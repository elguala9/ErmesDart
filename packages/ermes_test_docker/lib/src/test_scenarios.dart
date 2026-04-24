import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';

import 'docker_test_runner.dart';
import 'message_envelope.dart';

class AliceTestScenarios {
  AliceTestScenarios({
    required this.orc,
    required this.bobAddress,
  });

  final OrcErmes orc;
  final String bobAddress;

  final Map<String, Completer<void>> _ackCompleters = {};

  void handleIncoming(Uint8List data, String peerId) {
    final env = MessageEnvelope.decode(data);
    if (env.type == DockerMsgType.ack && env.testName != null) {
      final completer = _ackCompleters[env.testName];
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> runAll(DockerTestRunner runner) async {
    await testOpenConnection(runner);
    await testSingleAliceToBob(runner);
    await testMultiMsgOrdering(runner);
    await testLargeMsg(runner);
    await testBidirectionalConcurrent(runner);
    await testGetConnections(runner);
    await testCloseAndReconnect(runner);
  }

  Future<void> testOpenConnection(DockerTestRunner runner) =>
      runner.run('open_connection', () => orc.openConnection(bobAddress));

  Future<void> testSingleAliceToBob(DockerTestRunner runner) =>
      runner.run('single_msg_alice_to_bob', () async {
    final completer = Completer<void>();
    _ackCompleters['single_msg_alice_to_bob'] = completer;

    try {
      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'single_msg_alice_to_bob',
          seq: 0,
          payload: Uint8List.fromList([1, 2, 3, 4, 5]),
        ).encode(),
        bobAddress,
      );

      await completer.future.timeout(const Duration(seconds: 30));
    } finally {
      _ackCompleters.remove('single_msg_alice_to_bob');
    }
  });

  Future<void> testMultiMsgOrdering(DockerTestRunner runner) =>
      runner.run('multi_msg_ordering', () async {
    final completer = Completer<void>();
    _ackCompleters['multi_msg_ordering'] = completer;

    try {
      for (var i = 0; i < 5; i++) {
        await orc.send(
          MessageEnvelope(
            type: DockerMsgType.testData,
            testName: 'multi_msg_ordering',
            seq: i,
            payload: Uint8List.fromList([i]),
          ).encode(),
          bobAddress,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      await completer.future.timeout(const Duration(seconds: 30));
    } finally {
      _ackCompleters.remove('multi_msg_ordering');
    }
  });

  Future<void> testLargeMsg(DockerTestRunner runner) =>
      runner.run('large_msg_fragmentation', () async {
    final completer = Completer<void>();
    _ackCompleters['large_msg_fragmentation'] = completer;

    try {
      final largePayload = Uint8List(10240);
      for (var i = 0; i < largePayload.length; i++) {
        largePayload[i] = i % 256;
      }

      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'large_msg_fragmentation',
          seq: 0,
          payload: largePayload,
        ).encode(),
        bobAddress,
      );

      await completer.future.timeout(const Duration(seconds: 30));
    } finally {
      _ackCompleters.remove('large_msg_fragmentation');
    }
  });

  Future<void> testBidirectionalConcurrent(DockerTestRunner runner) =>
      runner.run('bidirectional_concurrent', () async {
    final completer = Completer<void>();
    _ackCompleters['bidirectional_concurrent'] = completer;

    try {
      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'bidirectional_concurrent',
          seq: 0,
          payload: Uint8List.fromList([0]),
        ).encode(),
        bobAddress,
      );
      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'bidirectional_concurrent',
          seq: 1,
          payload: Uint8List.fromList([1]),
        ).encode(),
        bobAddress,
      );
      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'bidirectional_concurrent',
          seq: 2,
          payload: Uint8List.fromList([2]),
        ).encode(),
        bobAddress,
      );

      await completer.future.timeout(const Duration(seconds: 30));
    } finally {
      _ackCompleters.remove('bidirectional_concurrent');
    }
  });

  Future<void> testGetConnections(DockerTestRunner runner) =>
      runner.run('get_connections', () async {
    final connections = await orc.getConnections();
    if (!connections.contains(bobAddress)) {
      throw Exception('Bob not in connections list: $connections');
    }
  });

  Future<void> testCloseAndReconnect(DockerTestRunner runner) =>
      runner.run('close_and_reconnect', () async {
    final completer = Completer<void>();
    _ackCompleters['close_and_reconnect'] = completer;

    try {
      await orc.closeConnection(bobAddress);
      await Future<void>.delayed(const Duration(seconds: 2));
      await orc.openConnection(bobAddress);

      await orc.send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'close_and_reconnect',
          seq: 0,
          payload: Uint8List.fromList([99]),
        ).encode(),
        bobAddress,
      );

      await completer.future.timeout(const Duration(seconds: 30));
    } finally {
      _ackCompleters.remove('close_and_reconnect');
    }
  });
}

class BobTestScenarios {
  BobTestScenarios({
    required this.orc,
    required this.aliceAddress,
    required this.runner,
    required this.onEndOfTests,
  });

  final OrcErmes orc;
  final String aliceAddress;
  final DockerTestRunner runner;
  final void Function() onEndOfTests;

  final Map<String, List<Uint8List>> _receivedMessages = {};

  void handleIncoming(Uint8List data, String peerId) {
    final env = MessageEnvelope.decode(data);

    if (env.type == DockerMsgType.endOfTests) {
      onEndOfTests();
      return;
    }

    if (env.type != DockerMsgType.testData) {
      return;
    }

    final testName = env.testName;
    if (testName == null) {
      return;
    }

    _receivedMessages.putIfAbsent(testName, () => []);
    _receivedMessages[testName]!.add(env.payload ?? Uint8List(0));

    unawaited(_processTestMessage(testName, env));
  }

  Future<void> _processTestMessage(
      String testName, MessageEnvelope env) async {
    try {
      if (testName == 'single_msg_alice_to_bob') {
        await _testSingleMsgAliceToBob(env);
      } else if (testName == 'multi_msg_ordering') {
        if (env.seq == 4) {
          await _testMultiMsgOrdering();
        }
      } else if (testName == 'large_msg_fragmentation') {
        await _testLargeMsg(env);
      } else if (testName == 'bidirectional_concurrent') {
        final msgs = _receivedMessages['bidirectional_concurrent'] ?? [];
        if (msgs.length >= 3) {
          await _testBidirectionalConcurrent();
        }
      } else if (testName == 'close_and_reconnect') {
        await _testCloseAndReconnect(env);
      }
    } on Exception catch (e) {
      // ignore: avoid_print
      print('[BOB] Error processing test message: $e');
    }
  }

  Future<void> _testSingleMsgAliceToBob(MessageEnvelope env) async =>
      runner.run('single_msg_alice_to_bob', () async {
    if ((env.payload?.length ?? 0) != 5) {
      throw Exception('Expected 5 bytes, got ${env.payload?.length}');
    }
    await orc.send(
      const MessageEnvelope(
        type: DockerMsgType.ack,
        testName: 'single_msg_alice_to_bob',
      ).encode(),
      aliceAddress,
    );
  });

  Future<void> _testMultiMsgOrdering() async =>
      runner.run('multi_msg_ordering', () async {
    final msgs = _receivedMessages['multi_msg_ordering'] ?? [];
    if (msgs.length != 5) {
      throw Exception('Expected 5 messages, got ${msgs.length}');
    }
    for (var i = 0; i < 5; i++) {
      final msgByte = msgs[i].isNotEmpty ? msgs[i][0] : -1;
      if (msgByte != i) {
        throw Exception(
          'Sequence mismatch at $i: expected $i, got $msgByte',
        );
      }
    }
    await orc.send(
      const MessageEnvelope(
        type: DockerMsgType.ack,
        testName: 'multi_msg_ordering',
      ).encode(),
      aliceAddress,
    );
  });

  Future<void> _testLargeMsg(MessageEnvelope env) async =>
      runner.run('large_msg_fragmentation', () async {
    final payload = env.payload ?? Uint8List(0);
    if (payload.length != 10240) {
      throw Exception('Expected 10240 bytes, got ${payload.length}');
    }
    for (var i = 0; i < payload.length; i++) {
      if (payload[i] != (i % 256)) {
        throw Exception(
          'Payload corruption at byte $i: '
          'expected ${i % 256}, got ${payload[i]}',
        );
      }
    }
    await orc.send(
      const MessageEnvelope(
        type: DockerMsgType.ack,
        testName: 'large_msg_fragmentation',
      ).encode(),
      aliceAddress,
    );
  });

  Future<void> _testBidirectionalConcurrent() async =>
      runner.run('bidirectional_concurrent', () async {
    final msgs = _receivedMessages['bidirectional_concurrent'] ?? [];
    if (msgs.length != 3) {
      throw Exception('Expected 3 concurrent messages, got ${msgs.length}');
    }
    await orc.send(
      const MessageEnvelope(
        type: DockerMsgType.ack,
        testName: 'bidirectional_concurrent',
      ).encode(),
      aliceAddress,
    );
  });

  Future<void> _testCloseAndReconnect(MessageEnvelope env) async =>
      runner.run('close_and_reconnect', () async {
    if ((env.payload?.length ?? 0) != 1) {
      throw Exception('Expected 1 byte, got ${env.payload?.length}');
    }
    await orc.send(
      const MessageEnvelope(
        type: DockerMsgType.ack,
        testName: 'close_and_reconnect',
      ).encode(),
      aliceAddress,
    );
  });
}
