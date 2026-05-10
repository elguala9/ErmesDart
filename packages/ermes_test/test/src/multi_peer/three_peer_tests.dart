import 'package:test/test.dart';

import 'multi_peer_framework.dart';

void runThreePeerTests() {
  group('Three-Peer Communication Tests', () {
    test('framework creates three peers', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      expect(framework.peers, hasLength(3));
      for (var i = 0; i < 3; i++) {
        expect(framework.getPeer('peer-$i'), isNotNull);
      }
      await framework.cleanup();
    });

    test('each peer has independent signaling setup', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      final setups = framework.peers
          .map((p) => p.signalingSetup!.accountId)
          .toSet();
      // Each peer must have a unique account ID (Nostr public key)
      expect(setups, hasLength(3));
      await framework.cleanup();
    });

    test('peers can connect in mesh pairwise', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      // Connect peer-0 to peer-1
      await framework.connectPeers('peer-0', 'peer-1');
      // Connect peer-1 to peer-2
      await framework.connectPeers('peer-1', 'peer-2');
      // Connect peer-0 to peer-2
      await framework.connectPeers('peer-0', 'peer-2');
      await framework.cleanup();
    }, skip: 'Requires reachable Nostr relay');

    test('all peers cleaned up properly', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      await framework.cleanup();
      expect(framework.peers, hasLength(0));
    });

    test('star topology: center peer connects to all others', () async {
      final framework = MultiPeerTestFramework();
      await framework.createPeers(3);
      // peer-0 acts as center
      await framework.connectPeers('peer-0', 'peer-1');
      await framework.connectPeers('peer-0', 'peer-2');
      await framework.cleanup();
    }, skip: 'Requires reachable Nostr relay');
  });
}
