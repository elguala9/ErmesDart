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

import 'package:ermes_test_docker/ermes_test_docker.dart';

const String _tag = 'PEER-A';

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
    case DockerMsgType.testData:
    case DockerMsgType.disconnectNow:
    case DockerMsgType.endOfTests:
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
