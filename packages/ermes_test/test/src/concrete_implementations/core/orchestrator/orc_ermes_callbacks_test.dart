import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_signaling_helper.dart';

void main() {
  testOrcErmesCallbacks();
}

void testOrcErmesCallbacks() {
  group('OrcErmesCallbacks', () {
    late TestSignalingSetup signaling;
    late OrcErmes orc;

    setUpAll(() async {
      signaling = await createTestSignalingSetup();
    });

    setUp(() async {
      orc = OrcErmes(
        signalingServer: signaling.signalingServer,
        signalingHandler: signaling.signalingHandler,
        socket: signaling.shspSocket,
        bookService: signaling.bookService,
      );
    });

    tearDown(() async {
      await orc.destroy(force: true);
    });

    tearDownAll(() async {
      await signaling.dispose();
    });

    group('dispatchMessage()', () {
      test('fans out to a single registered callback', () async {
        TypeOfData? received;
        IdPeer? receivedFrom;
        await orc.onMessage((data, from) {
          received = data;
          receivedFrom = from;
        });

        final payload = Uint8List.fromList([1, 2, 3]);
        orc.dispatchMessage(payload, 'peer-1');

        expect(received, equals(payload));
        expect(receivedFrom, equals('peer-1'));
      });

      test('fans out to every registered callback', () async {
        var firstCount = 0;
        var secondCount = 0;
        var thirdCount = 0;
        await orc.onMessage((data, from) => firstCount++);
        await orc.onMessage((data, from) => secondCount++);
        await orc.onMessage((data, from) => thirdCount++);

        orc.dispatchMessage(Uint8List.fromList([1]), 'peer-1');

        expect(firstCount, equals(1));
        expect(secondCount, equals(1));
        expect(thirdCount, equals(1));
      });

      test('does nothing when no callback is registered', () {
        expect(
          () => orc.dispatchMessage(Uint8List.fromList([1]), 'peer-1'),
          returnsNormally,
        );
      });

      test('invokes callback once per dispatch call', () async {
        var count = 0;
        await orc.onMessage((data, from) => count++);

        orc
          ..dispatchMessage(Uint8List.fromList([1]), 'peer-1')
          ..dispatchMessage(Uint8List.fromList([2]), 'peer-1')
          ..dispatchMessage(Uint8List.fromList([3]), 'peer-2');

        expect(count, equals(3));
      });
    });

    group('clearMessageCallbacks()', () {
      test('removes all registered message callbacks', () async {
        var count = 0;
        await orc.onMessage((data, from) => count++);

        orc
          ..clearMessageCallbacks()
          ..dispatchMessage(Uint8List.fromList([1]), 'peer-1');

        expect(count, equals(0));
      });

      test('is idempotent when called with no callbacks registered', () {
        expect(orc.clearMessageCallbacks, returnsNormally);
        expect(orc.clearMessageCallbacks, returnsNormally);
      });
    });

    group('handlePeerDisconnect()', () {
      test(
        'notifies disconnect callbacks after exhausting maxReconnectAttempts',
        () async {
          IdPeer? disconnectedPeer;
          var callCount = 0;
          await orc.onDisconnect((peer) {
            disconnectedPeer = peer;
            callCount++;
          });

          // Not a 64-char hex public key: openConnection rejects it
          // synchronously on every retry, so every backed-off attempt fails
          // fast without touching the network.
          const invalidPeer = 'not-a-valid-peer-id';
          await orc.handlePeerDisconnect(invalidPeer);

          expect(disconnectedPeer, equals(invalidPeer));
          expect(callCount, equals(1));
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );

      test('notifies every registered disconnect callback', () async {
        var firstCalled = false;
        var secondCalled = false;
        await orc.onDisconnect((peer) => firstCalled = true);
        await orc.onDisconnect((peer) => secondCalled = true);

        await orc.handlePeerDisconnect('not-a-valid-peer-id');

        expect(firstCalled, isTrue);
        expect(secondCalled, isTrue);
      },
          timeout: const Timeout(Duration(seconds: 20)));

      test('does not throw when no disconnect callback is registered',
          () async {
        await expectLater(
          orc.handlePeerDisconnect('not-a-valid-peer-id'),
          completes,
        );
      }, timeout: const Timeout(Duration(seconds: 20)));
    });
  });
}
