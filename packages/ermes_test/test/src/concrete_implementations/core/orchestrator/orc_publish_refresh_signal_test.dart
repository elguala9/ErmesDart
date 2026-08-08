import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/in_memory_signaling.dart';

/// 64-char hex account id (compatible with `ErmesIdValidator`).
String _hexAccountId(int value) => value.toRadixString(16).padLeft(64, '0');

void main() {
  setUpAll(registerErmesStorageHandlers);
  testPublishSignal();
  testRefreshSocket();
}

void testPublishSignal() {
  group('OrcErmes.publishSignal()', () {
    late Map<String, List<int>> store;
    late Map<String, List<InMemorySubscription>> subs;
    late String accountId;
    late OrcErmes orc;
    late IErmesSignalingServer server;

    setUp(() async {
      store = {};
      subs = {};
      accountId = _hexAccountId(1);
      final peer = await createInMemoryPeer(
        accountId: accountId,
        store: store,
        subscriptions: subs,
      );
      orc = peer.orc;
      server = peer.server;
    });

    tearDown(() async {
      await orc.destroy();
    });

    test('does not throw when no peers are connected', () async {
      await orc.publishSignal();
    });

    test('publishes a signal readable back from the server', () async {
      await orc.publishSignal();
      final signal =
          await server.getSignal(accountId, forceRefresh: true);
      expect(signal.ipv4, equals('127.0.0.1'));
    });

    test('can be called multiple times without throwing', () async {
      await orc.publishSignal();
      await orc.publishSignal();
      await orc.publishSignal();
    });

    test('a later call republishes a signal at least as fresh', () async {
      await orc.publishSignal();
      final first = await server.getSignal(accountId, forceRefresh: true);

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await orc.publishSignal();
      final second = await server.getSignal(accountId, forceRefresh: true);

      expect(
        second.epochTimestampStartConversation,
        greaterThanOrEqualTo(first.epochTimestampStartConversation),
      );
    });

    test(
      'wraps failures in CoreException when encryption is enabled '
      'without a key exchange',
      () async {
        final badAccountId = _hexAccountId(2);
        final peer = await createInMemoryPeer(
          accountId: badAccountId,
          store: store,
          subscriptions: subs,
          enableEncryption: true,
        );
        await expectLater(
          peer.orc.publishSignal(),
          throwsA(isA<CoreException>()),
        );
        await peer.orc.destroy();
      },
    );
  });
}

void testRefreshSocket() {
  group('OrcErmes.refreshSocket()', () {
    late Map<String, List<int>> store;
    late Map<String, List<InMemorySubscription>> subs;
    late String accountIdA;
    late String accountIdB;
    late OrcErmes orcA;
    late OrcErmes orcB;

    setUp(() async {
      store = {};
      subs = {};
      accountIdA = _hexAccountId(10);
      accountIdB = _hexAccountId(11);

      final peerA = await createInMemoryPeer(
        accountId: accountIdA,
        store: store,
        subscriptions: subs,
      );
      final peerB = await createInMemoryPeer(
        accountId: accountIdB,
        store: store,
        subscriptions: subs,
      );
      orcA = peerA.orc;
      orcB = peerB.orc;
    });

    tearDown(() async {
      await orcA.destroy();
      await orcB.destroy();
    });

    test('does not throw when no peers are connected', () async {
      await orcA.refreshSocket();
    });

    test('can be called multiple times in a row without throwing', () async {
      await orcA.refreshSocket();
      await orcA.refreshSocket();
      await orcA.refreshSocket();
    });

    test(
      'wraps failures in CoreException when encryption is enabled '
      'without a key exchange',
      () async {
        final badAccountId = _hexAccountId(12);
        final peer = await createInMemoryPeer(
          accountId: badAccountId,
          store: store,
          subscriptions: subs,
          enableEncryption: true,
        );
        await expectLater(
          peer.orc.refreshSocket(),
          throwsA(isA<CoreException>()),
        );
        await peer.orc.destroy();
      },
    );

    group('with a connected peer', () {
      setUp(() async {
        await Future.wait([
          orcA.openConnection(accountIdB),
          orcB.openConnection(accountIdA),
        ]);
        await Future<void>.delayed(const Duration(seconds: 2));
      });

      test('keeps the connection alive', () async {
        expect(await orcA.getConnections(), contains(accountIdB));

        await orcA.refreshSocket();

        expect(await orcA.getConnections(), contains(accountIdB));
      });

      test('does not throw and both sides stay reachable', () async {
        await Future.wait([orcA.refreshSocket(), orcB.refreshSocket()]);

        expect(await orcA.getConnections(), contains(accountIdB));
        expect(await orcB.getConnections(), contains(accountIdA));
      });

      test('peer can still send and receive data afterwards', () async {
        var receivedByB = Uint8List(0);
        var receiveCountB = 0;
        await orcB.onMessage((data, peerId) {
          receivedByB = data;
          receiveCountB++;
        });

        await orcA.refreshSocket();

        final payload = Uint8List.fromList([7, 8, 9]);
        await orcA.send(payload, accountIdB);

        var waited = 0;
        while (receiveCountB == 0 && waited < 30) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          waited++;
        }
        expect(receiveCountB, greaterThan(0));
        expect(receivedByB, equals(payload));
      });

      test(
        'data flows both directions after refreshing both sockets',
        () async {
          var receivedByA = Uint8List(0);
          var receivedByB = Uint8List(0);
          var receiveCountA = 0;
          var receiveCountB = 0;
          await orcA.onMessage((data, peerId) {
            receivedByA = data;
            receiveCountA++;
          });
          await orcB.onMessage((data, peerId) {
            receivedByB = data;
            receiveCountB++;
          });

          await Future.wait([orcA.refreshSocket(), orcB.refreshSocket()]);

          final dataAB = Uint8List.fromList([1, 2, 3]);
          await orcA.send(dataAB, accountIdB);
          var waited = 0;
          while (receiveCountB == 0 && waited < 30) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            waited++;
          }
          expect(receiveCountB, greaterThan(0));
          expect(receivedByB, equals(dataAB));

          final dataBA = Uint8List.fromList([4, 5, 6]);
          await orcB.send(dataBA, accountIdA);
          waited = 0;
          while (receiveCountA == 0 && waited < 30) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            waited++;
          }
          expect(receiveCountA, greaterThan(0));
          expect(receivedByA, equals(dataBA));
        },
      );

      test(
        'a fresh peer can still connect after refreshSocket()',
        () async {
          await orcA.refreshSocket();

          final accountIdC = _hexAccountId(13);
          final peerC = await createInMemoryPeer(
            accountId: accountIdC,
            store: store,
            subscriptions: subs,
          );

          await Future.wait([
            orcA.openConnection(accountIdC),
            peerC.orc.openConnection(accountIdA),
          ]);
          await Future<void>.delayed(const Duration(seconds: 2));

          expect(await orcA.getConnections(), contains(accountIdC));
          await peerC.orc.destroy();
        },
      );

      test(
        'concurrent refreshSocket() calls on the same instance do not throw',
        () async {
          await Future.wait([
            orcA.refreshSocket(),
            orcA.refreshSocket(),
            orcA.refreshSocket(),
          ]);

          expect(await orcA.getConnections(), contains(accountIdB));
        },
      );

      test(
        'does not duplicate the connection list across repeated refreshes',
        () async {
          await orcA.refreshSocket();
          await orcA.refreshSocket();
          await orcA.refreshSocket();

          final connections = await orcA.getConnections();
          expect(connections.where((p) => p == accountIdB).length, equals(1));
        },
      );

      test(
        'does not resurrect a connection that was closed beforehand',
        () async {
          await orcA.closeConnection(accountIdB);
          expect(await orcA.getConnections(), isNot(contains(accountIdB)));

          await orcA.refreshSocket();

          expect(await orcA.getConnections(), isNot(contains(accountIdB)));
        },
      );

      test('sending still throws for a peer closed after a refresh',
          () async {
        await orcA.refreshSocket();
        await orcA.closeConnection(accountIdB);

        expect(
          () => orcA.send(Uint8List.fromList([1]), accountIdB),
          throwsA(isA<Exception>()),
        );
      });

      test('destroy() after refreshSocket() completes without error',
          () async {
        await orcA.refreshSocket();
        await orcA.destroy();
        // Re-create so the shared tearDown's second destroy() is idempotent.
        expect(await orcA.getConnections(), isEmpty);
      });

      test(
        'publishSignal() right after refreshSocket() does not throw and '
        'the connection survives both',
        () async {
          await orcA.refreshSocket();
          await orcA.publishSignal();

          expect(await orcA.getConnections(), contains(accountIdB));
        },
      );

      test(
        'multiple sequential sends after a refresh all arrive in order',
        () async {
          final received = <int>[];
          await orcB.onMessage((data, peerId) {
            received.add(data.first);
          });

          await orcA.refreshSocket();

          for (var i = 1; i <= 5; i++) {
            await orcA.send(Uint8List.fromList([i]), accountIdB);
          }

          var waited = 0;
          while (received.length < 5 && waited < 50) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            waited++;
          }
          expect(received, equals([1, 2, 3, 4, 5]));
        },
      );

      test(
        'a third peer connecting to A does not disturb the existing '
        'A<->B connection across a refresh',
        () async {
          final accountIdC = _hexAccountId(14);
          final peerC = await createInMemoryPeer(
            accountId: accountIdC,
            store: store,
            subscriptions: subs,
          );

          await Future.wait([
            orcA.openConnection(accountIdC),
            peerC.orc.openConnection(accountIdA),
          ]);
          await Future<void>.delayed(const Duration(seconds: 2));

          await orcA.refreshSocket();

          final connectionsA = await orcA.getConnections();
          expect(connectionsA, containsAll([accountIdB, accountIdC]));

          var receivedByB = Uint8List(0);
          var receivedByC = Uint8List(0);
          await orcB.onMessage((data, peerId) => receivedByB = data);
          await peerC.orc.onMessage((data, peerId) => receivedByC = data);

          await orcA.send(Uint8List.fromList([9, 9]), accountIdB);
          await orcA.send(Uint8List.fromList([8, 8]), accountIdC);

          var waited = 0;
          while ((receivedByB.isEmpty || receivedByC.isEmpty) &&
              waited < 30) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            waited++;
          }
          expect(receivedByB, equals(Uint8List.fromList([9, 9])));
          expect(receivedByC, equals(Uint8List.fromList([8, 8])));

          await peerC.orc.destroy();
        },
      );

      test(
        'refreshSocket() racing a new openConnection() leaves both '
        'connections usable',
        () async {
          final accountIdD = _hexAccountId(15);
          final peerD = await createInMemoryPeer(
            accountId: accountIdD,
            store: store,
            subscriptions: subs,
          );

          await Future.wait([
            orcA.refreshSocket(),
            orcA.openConnection(accountIdD),
            peerD.orc.openConnection(accountIdA),
          ]);
          await Future<void>.delayed(const Duration(seconds: 2));

          final connectionsA = await orcA.getConnections();
          expect(connectionsA, contains(accountIdB));
          expect(connectionsA, contains(accountIdD));

          await peerD.orc.destroy();
        },
      );
    });
  });
}
