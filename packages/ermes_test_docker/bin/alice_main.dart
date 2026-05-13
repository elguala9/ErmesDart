import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_test_docker/ermes_test_docker.dart';

Future<void> main() async {
  const outputDir = '/output';

  print('[ALICE] Starting 3-peer test...');

  final config = DockerErmesConfig.fromEnv();
  final runner = DockerTestRunner(peer: 'alice');
  const writer = ResultWriter(outputDir: outputDir);

  try {
    print('[ALICE] Initializing OrcErmes via initialPointErmes...');
    final orc = await createDockerOrcErmes(config);
    // Only IOrcErmes methods from here on

    final bobPubkey = config.bobPubkey;
    final charliePubkey = config.charliePubkey;

    await runner.run('connect_to_bob', () async {
      await orc.openConnection(bobPubkey);
      final conns = await orc.getConnections();
      if (!conns.contains(bobPubkey)) {
        throw Exception('Bob not in connections');
      }
    });

    await runner.run('connect_to_charlie', () async {
      await orc.openConnection(charliePubkey);
      final conns = await orc.getConnections();
      if (!conns.contains(charliePubkey)) {
        throw Exception('Charlie not in connections');
      }
    });

    final allAcks = Completer<void>();
    var ackCount = 0;
    await orc.onMessage((data, peerId) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.ack) {
          ackCount++;
          print('[ALICE] Received ACK from $peerId ($ackCount/2)');
          if (ackCount >= 2 && !allAcks.isCompleted) {
            allAcks.complete();
          }
        }
      } on Exception catch (e) {
        print('[ALICE] Error in message handler: $e');
      }
    });

    await runner.run('alice_to_bob', () async {
      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'alice_to_bob',
          payload: Uint8List.fromList([1, 2, 3]),
        ).encode(),
        bobPubkey,
      );
      print('[ALICE] Sent testData to Bob, waiting for ACK...');
    });

    await runner.run('alice_to_charlie', () async {
      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'alice_to_charlie',
          payload: Uint8List.fromList([4, 5, 6]),
        ).encode(),
        charliePubkey,
      );
      print('[ALICE] Sent testData to Charlie, waiting for ACK...');
    });

    await allAcks.future.timeout(const Duration(seconds: 15));

    print('[ALICE] All acks received, sending END_OF_TESTS...');
    await orc.send(
      const MessageEnvelope(type: DockerMsgType.endOfTests).encode(),
      bobPubkey,
    );
    await orc.send(
      const MessageEnvelope(type: DockerMsgType.endOfTests).encode(),
      charliePubkey,
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    await orc.destroy(force: true);
  } on Exception catch (e) {
    print('[ALICE] Fatal error: $e');
  }

  final result = runner.buildResult();
  await writer.write(result);
  print('[ALICE] Done. Passed: ${result.passedCount}/${result.tests.length}');
  exit(result.allPassed ? 0 : 1);
}
