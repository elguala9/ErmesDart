import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_test_docker/ermes_test_docker.dart';

Future<void> main() async {
  const bobAddress = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';
  const outputDir = '/output';

  // ignore: avoid_print
  print('[ALICE] Starting...');

  final config = DockerErmesConfig.fromEnv();
  final runner = DockerTestRunner(peer: 'alice');
  const writer = ResultWriter(outputDir: outputDir);

  OrcErmes? orc;
  try {
    // ignore: avoid_print
    print('[ALICE] Connecting with Nostr relays');
    orc = await createDockerOrcErmes(config);

    // ignore: avoid_print
    print('[ALICE] OrcErmes initialized, opening connection to Bob...');

    await orc.openConnection(bobAddress);
    // ignore: avoid_print
    print('[ALICE] Connected to Bob, running test scenarios...');

    await runner.run('sanity_check', () async {
      final conns = await orc!.getConnections();
      if (!conns.contains(bobAddress)) {
        throw Exception('Bob not in connections after openConnection');
      }
    });

    // Send a simple test message and wait for response
    final messageReceived = Completer<void>();
    await orc.onMessage((data, peerId) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.ack) {
          if (!messageReceived.isCompleted) {
            messageReceived.complete();
          }
        }
      } on Exception catch (e) {
        // ignore: avoid_print
        print('[ALICE] Error in message handler: $e');
      }
    });

    await runner.run('simple_send', () async {
      await orc!.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'simple_send',
          payload: Uint8List.fromList([1, 2, 3]),
        ).encode(),
        bobAddress,
      );
      await messageReceived.future.timeout(const Duration(seconds: 10));
    });

    // Signal test completion
    await orc.send(
      const MessageEnvelope(type: DockerMsgType.endOfTests).encode(),
      bobAddress,
    );
    // ignore: avoid_print
    print('[ALICE] Sent END_OF_TESTS marker');

    await Future<void>.delayed(const Duration(seconds: 2));
  } on Exception catch (e) {
    // ignore: avoid_print
    print('[ALICE] Fatal error: $e');
  } finally {
    await orc?.destroy(force: true);
    final result = runner.buildResult();
    await writer.write(result);
    // ignore: avoid_print
    print(
      '[ALICE] Done. Passed: ${result.passedCount}/${result.tests.length}',
    );
    exit(result.allPassed ? 0 : 1);
  }
}
