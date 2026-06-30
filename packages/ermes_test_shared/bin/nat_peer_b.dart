// Standalone NAT-traversal test, responder side (role B).
//
// Reads its identity and rendezvous parameters from environment
// variables (see NatConfig), connects to peer A through a public Nostr
// relay + public STUN, ACKs every testData it receives, and requires the
// full agreed sequence plus an endOfTests marker. ANY deviation —
// missing config, failed rendezvous, malformed message, a wrong/short
// count, or a timeout — makes the process exit non-zero. stdout/stderr
// is the only transport; there is no result file.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:ermes_test_shared/ermes_test_shared.dart';

const String _tag = 'PEER-B';

Future<void> main() async {
  try {
    await _run();
    print('[$_tag] RESULT: PASS');
    exit(0);
  } on Object catch (e, st) {
    stderr
      ..writeln('[$_tag] RESULT: FAIL -> $e')
      ..writeln(st);
    exit(1);
  }
}

Future<void> _run() async {
  final config = NatConfig.fromEnvStrict(NatRole.b);
  print('[$_tag] self=${config.selfPubkey}');
  print('[$_tag] peer=${config.peerPubkey}');
  print(
    '[$_tag] stun=${config.stunHost}:${config.stunPort} '
    'relays=${config.relayUrls.join(",")}',
  );

  final orc = await createDockerOrcErmes(config.toDockerConfig());
  installSignalListener(_tag);

  if (isNetworkChangeScenario()) {
    print('[$_tag] scenario=network-change (sustained heartbeat).');
    await NatHeartbeatResponder(orc, config.peerPubkey, tag: _tag).run();
    return;
  }

  if (isEncryptedScenario()) {
    print('[$_tag] scenario=encrypted (ECDH handshake + encrypted burst).');
    await runEncryptedScenario(
      orc,
      config.peerPubkey,
      role: NatRole.b,
      tag: _tag,
    );
    return;
  }

  if (isRekeyScenario()) {
    print('[$_tag] scenario=rekey (encrypted heartbeat + key rotation).');
    await runRekeyScenario(orc, config.peerPubkey, role: NatRole.b, tag: _tag);
    return;
  }

  final reconnect = currentReconnectScenario();
  if (reconnect != null) {
    print('[$_tag] scenario=${reconnect.id} (P1 survivor side).');
    await NatReconnectResponder(
      orc,
      config.peerPubkey,
      scenario: reconnect,
      tag: _tag,
    ).run();
    return;
  }

  final received = <int>{};
  final finished = Completer<void>();
  await _installResponder(orc, config.peerPubkey, received, finished);

  await rendezvous(orc, config.peerPubkey, tag: _tag);

  final readyPings = _startReadySignal(orc, config.peerPubkey, received);

  print(
    '[$_tag] Connected; signalled ready, waiting for sequence + endOfTests '
    '(timeout ${NatTestProtocol.responderExchangeTimeout.inSeconds}s)...',
  );
  try {
    await finished.future.timeout(NatTestProtocol.responderExchangeTimeout);
  } finally {
    readyPings.cancel();
  }
  _verifyReceived(received);

  print('[$_tag] Full sequence received and acknowledged.');
  await Future<void>.delayed(const Duration(seconds: 2));
  await orc.destroy(force: true);
}

/// Sends `ready` immediately and then every
/// [NatTestProtocol.readyResendInterval] until the first `testData` arrives,
/// so a single lost `ready` cannot stall the initiator. The caller cancels
/// the returned timer once the exchange completes.
Timer _startReadySignal(
  IOrcErmes<BookData> orc,
  String peer,
  Set<int> received,
) {
  void sendReady() {
    if (received.isNotEmpty) {
      return;
    }
    const readyMsg = MessageEnvelope(type: DockerMsgType.ready);
    print('[$_tag] >> SENT ${readyMsg.describe()} to=${shortId(peer)}');
    unawaited(orc.send(readyMsg.encode(), peer));
  }

  sendReady();
  return Timer.periodic(
    NatTestProtocol.readyResendInterval,
    (_) => sendReady(),
  );
}

Future<void> _installResponder(
  IOrcErmes<BookData> orc,
  String peer,
  Set<int> received,
  Completer<void> finished,
) async {
  await orc.onMessage((data, from) {
    try {
      if (from != peer) {
        throw StateError('Message from unexpected peer $from (want $peer)');
      }
      final env = MessageEnvelope.decode(data);
      print('[$_tag] << RECV ${env.describe()} from=${shortId(from)}');
      _handle(orc, peer, env, received, finished);
    } on Object catch (e) {
      if (!finished.isCompleted) {
        finished.completeError(e);
      }
    }
  });
}

void _handle(
  IOrcErmes<BookData> orc,
  String peer,
  MessageEnvelope env,
  Set<int> received,
  Completer<void> finished,
) {
  switch (env.type) {
    case DockerMsgType.testData:
      if (env.seq == null) {
        throw StateError('testData without seq from $peer');
      }
      received.add(env.seq!);
      print(
        '[$_tag] testData seq=${env.seq} '
        '(${received.length}/${NatTestProtocol.messageCount})',
      );
      final ack = MessageEnvelope(type: DockerMsgType.ack, seq: env.seq);
      print('[$_tag] >> SENT ${ack.describe()} to=${shortId(peer)}');
      unawaited(orc.send(ack.encode(), peer));
    case DockerMsgType.endOfTests:
      print('[$_tag] endOfTests received');
      if (!finished.isCompleted) {
        finished.complete();
      }
    case DockerMsgType.rendezvousPing:
    case DockerMsgType.rendezvousPong:
      break; // handled by the rendezvous liveness handler; ignore here
    case DockerMsgType.ready:
    case DockerMsgType.ack:
    case DockerMsgType.disconnectNow:
    case DockerMsgType.keyExchange:
    case DockerMsgType.decryptReady:
    case DockerMsgType.newKey:
      throw StateError('Unexpected message type ${env.type.name} from $peer');
  }
}

void _verifyReceived(Set<int> received) {
  for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
    if (!received.contains(seq)) {
      throw StateError('Missing testData seq=$seq; received: $received');
    }
  }
  if (received.length != NatTestProtocol.messageCount) {
    throw StateError(
      'Expected exactly ${NatTestProtocol.messageCount} '
      'testData messages, got ${received.length}: $received',
    );
  }
}
