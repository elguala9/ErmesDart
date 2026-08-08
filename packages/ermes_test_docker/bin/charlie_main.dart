// CLI binary for Docker-based integration tests; stdout is the
// designated transport for logs to the test orchestrator.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:ermes_test_docker/ermes_test_docker.dart';

/// Charlie peer entry point: connects to Alice and Bob, ACKs incoming test
/// data, and completes once END_OF_TESTS arrives, then writes results.
Future<void> main() async {
  const outputDir = '/output';

  print('[CHARLIE] Starting 3-peer test...');

  final config = DockerErmesConfig.fromEnv();
  final runner = DockerTestRunner(peer: 'charlie');
  const writer = ResultWriter(outputDir: outputDir);

  try {
    print('[CHARLIE] Initializing OrcErmes via createDockerOrcErmes...');
    final orc = await createDockerOrcErmes(config);
    // Only IOrcErmes methods from here on

    final alicePubkey = config.alicePubkey;
    final bobPubkey = config.bobPubkey;

    await runner.run('connect_to_alice', () async {
      await orc.openConnection(alicePubkey);
      final conns = await orc.getConnections();
      if (!conns.contains(alicePubkey)) {
        throw Exception('Alice not in connections');
      }
    });

    await runner.run('connect_to_bob', () async {
      await orc.openConnection(bobPubkey);
      final conns = await orc.getConnections();
      if (!conns.contains(bobPubkey)) {
        throw Exception('Bob not in connections');
      }
    });

    final endOfTests = Completer<void>();
    var messagesReceived = 0;

    await orc.onMessage((data, peerId) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.endOfTests) {
          print('[CHARLIE] Received END_OF_TESTS');
          if (!endOfTests.isCompleted) {
            endOfTests.complete();
          }
          return;
        }

        if (env.type == DockerMsgType.testData) {
          messagesReceived++;
          final testName = env.testName ?? 'unknown';
          print('[CHARLIE] Received testData "$testName" from $peerId');
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
        print('[CHARLIE] Error in message handler: $e');
      }
    });

    await runner.run('receive_from_alice', () async {
      await endOfTests.future.timeout(const Duration(minutes: 5));
      if (messagesReceived < 1) {
        throw Exception('No messages received during test');
      }
    });

    print('[CHARLIE] Test sequence completed');
    await orc.destroy(force: true);
  } on Exception catch (e) {
    print('[CHARLIE] Fatal error: $e');
  }

  final result = runner.buildResult();
  await writer.write(result);
  print(
      '[CHARLIE] Done. Passed: ${result.passedCount}/${result.tests.length}');
  exit(result.allPassed ? 0 : 1);
}
