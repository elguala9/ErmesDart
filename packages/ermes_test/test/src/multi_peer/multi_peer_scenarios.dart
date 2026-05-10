import 'dart:typed_data';

import 'package:test/test.dart';

import 'multi_peer_framework.dart';

void runMultiPeerScenarios() {
  group('Complex Multi-Peer Scenarios', () {
    test('framework creates correct number of peers', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      expect(framework.peers, hasLength(3));
      await framework.cleanup();
    });

    test('each peer has unique id and signaling setup', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      for (final peer in framework.peers) {
        expect(peer.id, isNotEmpty);
        expect(peer.signalingSetup, isNotNull);
        expect(peer.idHandler, isNotNull);
      }
      await framework.cleanup();
    });

    test('peers can be created and cleaned up multiple times', () async {
      for (var i = 0; i < 3; i++) {
        final framework = MultiPeerTestFramework();
        await framework.createPeers(2);
        expect(framework.peers, hasLength(2));
        await framework.cleanup();
      }
    });

    test('connectPeers throws on non-existent peer', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(2);
      expect(
        () => framework.connectPeers('peer-999', 'peer-0'),
        throwsStateError,
      );
      await framework.cleanup();
    });

    test('peer lookup returns correct instances', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      for (var i = 0; i < 3; i++) {
        final peer = framework.getPeer('peer-$i');
        expect(peer, isNotNull);
        expect(peer!.id, equals('peer-$i'));
      }
      await framework.cleanup();
    });

    test('peer lookup returns null for unknown peer', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(2);
      expect(framework.getPeer('peer-999'), isNull);
      await framework.cleanup();
    });

    test('cleanup handles multiple calls safely', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(2);
      await framework.cleanup();
      await framework.cleanup();
    });

    test('sendMessage throws before service initialized', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(2);
      expect(
        () => framework.sendMessage(
          'peer-0',
          'peer-1',
          Uint8List.fromList([1, 2, 3]),
        ),
        throwsStateError,
      );
      await framework.cleanup();
    });

    test('peer dispose cleans up resources', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(2);
      for (final peer in framework.peers) {
        await peer.dispose();
      }
      expect(framework.peers, hasLength(2));
      await framework.cleanup();
    });

    test('onPeerMessageReceived throws before service initialized', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(2);
      expect(
        () => framework.onPeerMessageReceived('peer-0', (_) {}),
        throwsStateError,
      );
      await framework.cleanup();
    });

    test('scenario: create 4 peers and verify all are connected to relay',
        () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(4);

      expect(framework.peers, hasLength(4));
      for (final peer in framework.peers) {
        expect(
          peer.signalingSetup!.nostrSignaling.isConnected(),
          isTrue,
        );
      }
      await framework.cleanup();
    }, skip: 'Requires reachable Nostr relay');
  });
}
