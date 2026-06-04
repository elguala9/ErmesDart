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
  final acked = <int>{};
  final done = Completer<void>();
  await _installAckTracking(orc, acked, done);

  print(
    '[$_tag] Startup grace '
    '${NatTestProtocol.initiatorStartupGrace.inSeconds}s...',
  );
  await Future<void>.delayed(NatTestProtocol.initiatorStartupGrace);

  await rendezvous(orc, config.peerPubkey, tag: _tag);
  await _sendBatch(orc, config.peerPubkey);

  print(
    '[$_tag] Waiting for all ACKs '
    '(timeout ${NatTestProtocol.ackTimeout.inSeconds}s)...',
  );
  await done.future.timeout(NatTestProtocol.ackTimeout);
  _verifyAcks(acked);

  print('[$_tag] All ACKs received; sending endOfTests.');
  await orc.send(
    const MessageEnvelope(type: DockerMsgType.endOfTests).encode(),
    config.peerPubkey,
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  await orc.destroy(force: true);
}

Future<void> _installAckTracking(
  IOrcErmes<BookData> orc,
  Set<int> acked,
  Completer<void> done,
) async {
  await orc.onMessage((data, from) {
    try {
      final env = MessageEnvelope.decode(data);
      if (env.type != DockerMsgType.ack) {
        throw StateError('Unexpected message type ${env.type.name} from $from');
      }
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
    } on Object catch (e) {
      if (!done.isCompleted) {
        done.completeError(e);
      }
    }
  });
}

Future<void> _sendBatch(IOrcErmes<BookData> orc, String peer) async {
  for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
    await orc.send(
      MessageEnvelope(
        type: DockerMsgType.testData,
        testName: 'a_to_b_$seq',
        seq: seq,
        payload: Uint8List.fromList([seq, seq + 1, seq + 2]),
      ).encode(),
      peer,
    );
    print('[$_tag] Sent testData seq=$seq');
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
