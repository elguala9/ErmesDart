// CLI binary for Docker-based integration tests; stdout is the
// designated transport for logs to the test orchestrator.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:ermes_test_docker/ermes_test_docker.dart';

/// Bob peer entry point: connects to Alice and Charlie, ACKs incoming test
/// data, and completes once END_OF_TESTS arrives, then writes results.
Future<void> main() async {
  const outputDir = '/output';

  print('[BOB] Starting 3-peer test...');

  final config = DockerErmesConfig.fromEnv();
  final runner = DockerTestRunner(peer: 'bob');
  const writer = ResultWriter(outputDir: outputDir);

  try {
    print('[BOB] Initializing OrcErmes via initialPointErmes...');
    final orc = await createDockerOrcErmes(config);
    // Only IOrcErmes methods from here on

    final alicePubkey = config.alicePubkey;
    final charliePubkey = config.charliePubkey;

    await runner.run('connect_to_alice', () async {
      await orc.openConnection(alicePubkey);
      final conns = await orc.getConnections();
      if (!conns.contains(alicePubkey)) {
        throw Exception('Alice not in connections');
      }
    });

    await runner.run('connect_to_charlie', () async {
      await orc.openConnection(charliePubkey);
      final conns = await orc.getConnections();
      if (!conns.contains(charliePubkey)) {
        throw Exception('Charlie not in connections');
      }
    });

    final endOfTests = Completer<void>();
    var messagesReceived = 0;

    await orc.onMessage((data, peerId) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.endOfTests) {
          print('[BOB] Received END_OF_TESTS');
          if (!endOfTests.isCompleted) {
            endOfTests.complete();
          }
          return;
        }

        if (env.type == DockerMsgType.testData) {
          messagesReceived++;
          final testName = env.testName ?? 'unknown';
          print('[BOB] Received testData "$testName" from $peerId');
          unawaited(
            orc.send(
              MessageEnvelope(
                type: DockerMsgType.ack,
                testName: testName,
              ).encode(),
              peerId,
            ),
          );
        }
      } on Exception catch (e) {
        print('[BOB] Error in message handler: $e');
      }
    });

    await runner.run('receive_from_alice', () async {
      await endOfTests.future.timeout(const Duration(minutes: 5));
      if (messagesReceived < 1) {
        throw Exception('No messages received during test');
      }
    });

    print('[BOB] Test sequence completed');
    await orc.destroy(force: true);
  } on Exception catch (e) {
    print('[BOB] Fatal error: $e');
  }

  final result = runner.buildResult();
  await writer.write(result);
  print('[BOB] Done. Passed: ${result.passedCount}/${result.tests.length}');
  exit(result.allPassed ? 0 : 1);
}
