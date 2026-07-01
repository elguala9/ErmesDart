// Standalone NAT-traversal test, initiator side (role A).
//
// Reads its identity and rendezvous parameters from environment
// variables (see NatConfig), connects to peer B through a public Nostr
// relay + public STUN, sends a fixed batch of testData messages, and
// requires an ACK for every single one. ANY deviation — missing config,
// failed rendezvous, malformed reply, a single missing ACK, or a
// timeout — makes the process exit non-zero. stdout/stderr is the only
// transport; there is no result file.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_test_shared/ermes_test_shared.dart';

const String _tag = 'PEER-A';

Future<void> main() async {
  try {
    await _run();
    print('[$_tag] RESULT: PASS');
    await stdout.flush();
    exit(0);
  } on Object catch (e, st) {
    stderr
      ..writeln('[$_tag] RESULT: FAIL -> $e')
      ..writeln(st);
    // exit() does NOT drain the IO buffers; on Windows with redirected output
    // the FAIL line is block-buffered and lost without an explicit flush.
    await stdout.flush();
    await stderr.flush();
    exit(1);
  }
}

Future<void> _run() async {
  final config = NatConfig.fromEnvStrict(NatRole.a);
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
    await NatHeartbeatInitiator(orc, config.peerPubkey, tag: _tag).run();
    return;
  }

  if (isEncryptedScenario()) {
    print('[$_tag] scenario=encrypted (ECDH handshake + encrypted burst).');
    await runEncryptedScenario(
      orc,
      config.peerPubkey,
      role: NatRole.a,
      tag: _tag,
    );
    return;
  }

  if (isRekeyScenario()) {
    print('[$_tag] scenario=rekey (encrypted heartbeat + key rotation).');
    await runRekeyScenario(orc, config.peerPubkey, role: NatRole.a, tag: _tag);
    return;
  }

  if (isSignalCipherScenario()) {
    print('[$_tag] scenario=signal-cipher (encryption from the signal ECDH).');
    await runSignalCipherScenario(
      orc,
      config.peerPubkey,
      role: NatRole.a,
      tag: _tag,
    );
    return;
  }

  final reconnect = currentReconnectScenario();
  if (reconnect != null) {
    print('[$_tag] scenario=${reconnect.id} (P1 disconnection/reconnection).');
    await NatReconnectInitiator(
      orc,
      config.peerPubkey,
      scenario: reconnect,
      tag: _tag,
    ).run();
    return;
  }

  final p2 = currentP2Scenario();
  if (p2 != null) {
    print('[$_tag] scenario=${p2.id} (P2 reliability, sender side).');
    await NatP2Initiator(orc, config.peerPubkey, scenario: p2, tag: _tag).run();
    return;
  }

  final load = currentLoadScenario();
  if (load != null) {
    print('[$_tag] scenario=${load.id} (P4/P5 load, sender side).');
    await NatLoadInitiator(orc, config.peerPubkey, scenario: load, tag: _tag)
        .run();
    return;
  }

  final acked = <int>{};
  final ready = Completer<void>();
  final done = Completer<void>();
  await _installHandlers(orc, acked, ready, done);

  print(
    '[$_tag] Startup grace '
    '${NatTestProtocol.initiatorStartupGrace.inSeconds}s...',
  );
  await Future<void>.delayed(NatTestProtocol.initiatorStartupGrace);

  await rendezvous(orc, config.peerPubkey, tag: _tag);

  print(
    '[$_tag] Connected; waiting for peer ready '
    '(timeout ${NatTestProtocol.readyTimeout.inSeconds}s)...',
  );
  await ready.future.timeout(NatTestProtocol.readyTimeout);
  print('[$_tag] Peer ready; sending batch.');
  await _sendBatch(orc, config.peerPubkey);

  print(
    '[$_tag] Waiting for all ACKs '
    '(timeout ${NatTestProtocol.ackTimeout.inSeconds}s)...',
  );
  await done.future.timeout(NatTestProtocol.ackTimeout);
  _verifyAcks(acked);

  const endOfTests = MessageEnvelope(type: DockerMsgType.endOfTests);
  print('[$_tag] All ACKs received; >> SENT ${endOfTests.describe()}.');
  await orc.send(endOfTests.encode(), config.peerPubkey);
  await Future<void>.delayed(const Duration(seconds: 2));
  await orc.destroy(force: true);
}

Future<void> _installHandlers(
  IOrcErmes<BookData> orc,
  Set<int> acked,
  Completer<void> ready,
  Completer<void> done,
) async {
  await orc.onMessage((data, from) {
    try {
      final env = MessageEnvelope.decode(data);
      print('[$_tag] << RECV ${env.describe()} from=${shortId(from)}');
      _dispatch(env, from, acked, ready, done);
    } on Object catch (e) {
      if (!ready.isCompleted) {
        ready.completeError(e);
      } else if (!done.isCompleted) {
        done.completeError(e);
      }
    }
  });
}

void _dispatch(
  MessageEnvelope env,
  String from,
  Set<int> acked,
  Completer<void> ready,
  Completer<void> done,
) {
  switch (env.type) {
    case DockerMsgType.ready:
      if (!ready.isCompleted) {
        print('[$_tag] Peer signalled ready.');
        ready.complete();
      }
    case DockerMsgType.ack:
      if (env.seq == null) {
        throw StateError('ACK without seq from $from');
      }
      acked.add(env.seq!);
      print(
        '[$_tag] ACK seq=${env.seq} '
        '(${acked.length}/${NatTestProtocol.messageCount})',
      );
      if (acked.length >= NatTestProtocol.messageCount && !done.isCompleted) {
        done.complete();
      }
    case DockerMsgType.rendezvousPing:
    case DockerMsgType.rendezvousPong:
      break; // handled by the rendezvous liveness handler; ignore here
    case DockerMsgType.testData:
    case DockerMsgType.disconnectNow:
    case DockerMsgType.endOfTests:
    case DockerMsgType.keyExchange:
    case DockerMsgType.decryptReady:
    case DockerMsgType.newKey:
    case DockerMsgType.requestMissing:
    case DockerMsgType.keepalive:
      throw StateError('Unexpected message type ${env.type.name} from $from');
  }
}

Future<void> _sendBatch(IOrcErmes<BookData> orc, String peer) async {
  for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
    final env = MessageEnvelope(
      type: DockerMsgType.testData,
      testName: 'a_to_b_$seq',
      seq: seq,
      payload: Uint8List.fromList([seq, seq + 1, seq + 2]),
    );
    await orc.send(env.encode(), peer);
    print('[$_tag] >> SENT ${env.describe()} to=${shortId(peer)}');
  }
}

void _verifyAcks(Set<int> acked) {
  for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
    if (!acked.contains(seq)) {
      throw StateError('Missing ACK for seq=$seq; received: $acked');
    }
  }
  if (acked.length != NatTestProtocol.messageCount) {
    throw StateError(
      'Expected exactly ${NatTestProtocol.messageCount} ACKs, '
      'got ${acked.length}: $acked',
    );
  }
}
