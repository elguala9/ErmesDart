import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_test_docker/ermes_test_docker.dart';

Future<void> main() async {
  const aliceAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
  const outputDir = '/output';

  // ignore: avoid_print
  print('[BOB] Starting...');

  final config = DockerErmesConfig.fromEnv();
  final runner = DockerTestRunner(peer: 'bob');
  const writer = ResultWriter(outputDir: outputDir);

  OrcErmes? orc;
  try {
    // ignore: avoid_print
    print('[BOB] Connecting to Ganache: ${config.rpcUrl}');
    orc = await createDockerOrcErmes(config);

    final endOfTestsCompleter = Completer<void>();

    // ignore: avoid_print
    print('[BOB] OrcErmes initialized, opening connection to Alice...');

    await orc.openConnection(aliceAddress);
    // ignore: avoid_print
    print('[BOB] Connected to Alice, waiting for test messages...');

    await runner.run('sanity_check', () async {
      final conns = await orc!.getConnections();
      if (!conns.contains(aliceAddress)) {
        throw Exception('Alice not in connections after openConnection');
      }
    });

    // Register global message listener
    await orc.onMessage((data, peerId) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.endOfTests) {
          // ignore: avoid_print
          print('[BOB] Received END_OF_TESTS');
          if (!endOfTestsCompleter.isCompleted) {
            endOfTestsCompleter.complete();
          }
          return;
        }

        if (env.type == DockerMsgType.testData) {
          final testName = env.testName ?? 'unknown';
          // ignore: avoid_print
          print('[BOB] Received test message: $testName');
          unawaited(_handleTestMessage(orc!, aliceAddress, env, runner));
        }
      } on Exception catch (e) {
        // ignore: avoid_print
        print('[BOB] Error in message handler: $e');
      }
    });

    // Wait for END_OF_TESTS signal
    await endOfTestsCompleter.future.timeout(const Duration(minutes: 5));
    // ignore: avoid_print
    print('[BOB] Test sequence completed');
  } on Exception catch (e) {
    // ignore: avoid_print
    print('[BOB] Fatal error: $e');
  } finally {
    await orc?.destroy(force: true);
    final result = runner.buildResult();
    await writer.write(result);
    // ignore: avoid_print
    print(
      '[BOB] Done. Passed: ${result.passedCount}/${result.tests.length}',
    );
    exit(result.allPassed ? 0 : 1);
  }
}

Future<void> _handleTestMessage(
  OrcErmes orc,
  String aliceAddress,
  MessageEnvelope env,
  DockerTestRunner runner,
) async {
  final testName = env.testName ?? 'unknown';

  if (testName == 'simple_send') {
    await runner.run('simple_send_received', () async {
      final payload = env.payload ?? Uint8List(0);
      if (payload.length != 3) {
        throw Exception('Expected 3 bytes, got ${payload.length}');
      }
      await orc.send(
        const MessageEnvelope(
          type: DockerMsgType.ack,
          testName: 'simple_send',
        ).encode(),
        aliceAddress,
      );
    });
  }
}
