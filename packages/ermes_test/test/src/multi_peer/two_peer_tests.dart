import 'dart:typed_data';


import 'package:test/test.dart';

import '../helpers/peer_test_helper.dart';
import 'multi_peer_framework.dart';

/// Test di comunicazione a due peer
///
/// Testa scenari fondamentali di comunicazione peer-to-peer:
/// - Creazione e cleanup di peer
/// - Invio messaggi da peer A a peer B
/// - Ricezione messaggi

void runTwoPeerTests() {
  group('Two-Peer Communication Tests', () {
    late MultiPeerTestFramework framework;

    setUp(() async {
      framework = MultiPeerTestFramework();
      // Crea 2 peer per test
      await framework.createPeers(2);
    });

    tearDown(() async {
      await framework.cleanup();
    });

    group('Framework Setup', () {
      test('creates correct number of peers', () {
        expect(framework.peers, hasLength(2));
        expect(framework.peers[0].id, equals('peer-0'));
        expect(framework.peers[1].id, equals('peer-1'));
      });

      test('each peer has idHandler', () {
        expect(framework.peers[0].idHandler, isNotNull);
        expect(framework.peers[1].idHandler, isNotNull);
      });

      test('peer lookup works correctly', () {
        expect(framework.getPeer('peer-0'), isNotNull);
        expect(framework.getPeer('peer-1'), isNotNull);
        expect(framework.getPeer('peer-999'), isNull);
      });
    });

    group('Message Exchange', () {
      test('sendMessage throws when service not initialized', () async {
        final testData = PeerTestHelper.createTestData(10);

        expect(
          () => framework.sendMessage('peer-0', 'peer-1', testData),
          throwsStateError,
        );
      });

      test('sendMessage throws on non-existent peer', () async {
        final testData = PeerTestHelper.createTestData(10);

        expect(
          () => framework.sendMessage('peer-999', 'peer-0', testData),
          throwsStateError,
        );
      });

      test('onPeerMessageReceived throws when service not initialized',
          () async {
        void callback(Uint8List data) {}

        expect(
          () => framework.onPeerMessageReceived('peer-0', callback),
          throwsStateError,
        );
      });

      test('connectPeers attempts signaling via Nostr relay', () async {
        await framework.connectPeers('peer-0', 'peer-1');
        // If we reach here, the signaling attempt didn't throw
        // parameter validation errors. Real relay publish may
        // succeed or fail depending on network availability.
      });

      test('connectPeers throws on non-existent peer', () async {
        expect(
          () => framework.connectPeers('peer-999', 'peer-0'),
          throwsStateError,
        );
      });
    });

    group('Message Data Generation', () {
      test('createTestData generates correct size', () {
        final data = PeerTestHelper.createTestData(100);
        expect(data.length, equals(100));
      });

      test('createTestData respects pattern', () {
        final data = PeerTestHelper.createTestData(5, pattern: 42);
        for (final byte in data) {
          expect(byte, equals(42));
        }
      });

      test('createTestMessages generates multiple messages', () {
        const count = 5;
        const size = 20;
        final messages = PeerTestHelper.createTestMessages(count, size: size);

        expect(messages, hasLength(count));
        for (final msg in messages) {
          expect(msg.length, equals(size));
        }
      });

      test('areDataEqual compares correctly', () {
        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([1, 2, 3]);
        final data3 = Uint8List.fromList([1, 2, 4]);

        expect(PeerTestHelper.areDataEqual(data1, data2), isTrue);
        expect(PeerTestHelper.areDataEqual(data1, data3), isFalse);
      });

      test('areDataEqual handles different lengths', () {
        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([1, 2]);

        expect(PeerTestHelper.areDataEqual(data1, data2), isFalse);
      });
    });

    group('Peer Cleanup', () {
      test('cleanup disposes all peers', () async {
        expect(framework.peers, hasLength(2));

        await framework.cleanup();

        expect(framework.peers, hasLength(0));
      });

      test('multiple cleanup calls are safe', () async {
        await framework.cleanup();
        expect(framework.cleanup, returnsNormally);
      });
    });
  });
}
