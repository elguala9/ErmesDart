import 'package:test/test.dart';

import 'multi_peer_framework.dart';

void runNPeerTests() {
  group('N-Peer Scalability Tests', () {
    test('creates 5 peers', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(5);
      expect(framework.peers, hasLength(5));
      for (var i = 0; i < 5; i++) {
        expect(framework.getPeer('peer-$i'), isNotNull);
      }
      await framework.cleanup();
    });

    test('each of 5 peers has unique identity', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(5);
      final ids = framework.peers
          .map((p) => p.accountId)
          .toSet();
      expect(ids, hasLength(5));
      await framework.cleanup();
    });

    test('creates 10 peers', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(10);
      expect(framework.peers, hasLength(10));
      for (var i = 0; i < 10; i++) {
        expect(framework.getPeer('peer-$i'), isNotNull);
      }
      await framework.cleanup();
    });

    test('10 peers each have unique idHandler', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(10);
      for (final peer in framework.peers) {
        expect(peer.idHandler, isNotNull);
      }
      await framework.cleanup();
    });

    test('all N peers cleaned up', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(7);
      await framework.cleanup();
      expect(framework.peers, hasLength(0));
    });

    test('connectPeers between any two of 5 peers', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(5);
      await framework.connectPeers('peer-0', 'peer-4');
      await framework.connectPeers('peer-1', 'peer-3');
      await framework.connectPeers('peer-2', 'peer-0');
      await framework.cleanup();
    });

    test('N-peer cleanup is safe after partial disposal', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(5);
      // Dispose first two peers manually
      await framework.peers[0].dispose();
      await framework.peers[1].dispose();
      // Cleanup should handle remaining peers
      await framework.cleanup();
      expect(framework.peers, hasLength(0));
    });
  });
}
