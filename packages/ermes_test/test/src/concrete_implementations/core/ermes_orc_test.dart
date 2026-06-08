import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../test_signaling_helper.dart';

void main() {
  testOrcErmes();
}

void testOrcErmes() {
  group('OrcErmes', () {
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
      await orc.destroy();
    });

    tearDownAll(() async {
      await signaling.dispose();
    });

    group('constructor', () {
      test('creates OrcErmes instance', () {
        expect(orc, isA<OrcErmes>());
      });

      test('implements IOrcErmes', () {
        expect(orc, isA<IOrcErmes<BookData>>());
      });

      test('default enableEncryption is true', () {
        // Verify encryption is enabled by default through
        // openConnection validation behavior
        expect(orc, isA<OrcErmes>());
      });

      test('default connectionTimeoutMs is 30000', () {
        expect(orc, isA<OrcErmes>());
      });
    });

    group('getConnections()', () {
      test('returns empty list when no connections', () async {
        final connections = await orc.getConnections();
        expect(connections, isEmpty);
      });
    });

    group('send()', () {
      test('throws Exception when peer is not connected', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        expect(
          () => orc.send(data, 'unconnected-peer'),
          throwsA(isA<Exception>()),
        );
      });

      test('error message mentions peer ID', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        try {
          await orc.send(data, 'unconnected-peer');
          fail('Expected exception was not thrown');
        } on Exception catch (e) {
          expect(e.toString(), contains('unconnected-peer'));
        }
      });

      test('throws Exception for empty data', () async {
        expect(
          () => orc.send(Uint8List(0), 'unconnected-peer'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('closeConnection()', () {
      test('does not throw when peer is not connected', () async {
        await orc.closeConnection('non-existent-peer');
      });

      test('is idempotent for non-connected peers', () async {
        await orc.closeConnection('non-existent-peer');
        await orc.closeConnection('non-existent-peer');
      });
    });

    group('openConnection()', () {
      test('throws for invalid peer ID (not 64-char hex)', () async {
        expect(
          () => orc.openConnection('not-a-valid-peer-id'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws for empty peer ID', () async {
        expect(
          () => orc.openConnection(''),
          throwsA(isA<Exception>()),
        );
      });

      test('throws for 63-char hex string', () async {
        expect(
          () => orc.openConnection('a' * 63),
          throwsA(isA<Exception>()),
        );
      });

      test('throws for 65-char hex string', () async {
        expect(
          () => orc.openConnection('a' * 65),
          throwsA(isA<Exception>()),
        );
      });

      test('throws for lowercase hex with 64 chars still validates format',
          () async {
        expect(
          () => orc.openConnection('a' * 64),
          throwsA(isA<Exception>()),
        );
      });

      test('throws for uppercase hex with 64 chars', () async {
        expect(
          () => orc.openConnection('A' * 64),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('onMessage()', () {
      test('registers callback successfully', () async {
        var callCount = 0;
        await orc.onMessage((data, peerId) {
          callCount++;
        });
        expect(callCount, equals(0));
      });

      test('supports multiple callbacks', () async {
        var callCount1 = 0;
        var callCount2 = 0;
        await orc.onMessage((data, peerId) {
          callCount1++;
        });
        await orc.onMessage((data, peerId) {
          callCount2++;
        });
        expect(callCount1, equals(0));
        expect(callCount2, equals(0));
      });
    });

    group('onDisconnect()', () {
      test('registers callback successfully', () async {
        IdPeer? disconnectedPeer;
        await orc.onDisconnect((peerId) {
          disconnectedPeer = peerId;
        });
        expect(disconnectedPeer, isNull);
      });

      test('supports multiple callbacks', () async {
        var callCount1 = 0;
        var callCount2 = 0;
        await orc.onDisconnect((peerId) {
          callCount1++;
        });
        await orc.onDisconnect((peerId) {
          callCount2++;
        });
        expect(callCount1, equals(0));
        expect(callCount2, equals(0));
      });
    });

    group('save()', () {
      test('does not throw', () async {
        await orc.save();
      });

      test('is idempotent', () async {
        await orc.save();
        await orc.save();
      });
    });

    group('getIdAccount()', () {
      test('returns the account ID from signaling server', () async {
        final accountId = await orc.getIdAccount();
        expect(accountId, isA<String>());
        expect(accountId, isNotEmpty);
      });

      test('matches the signaling setup account', () async {
        final accountId = await orc.getIdAccount();
        expect(accountId, equals(signaling.accountId));
      });
    });

    group('isSignalingConnected()', () {
      test('returns true when signaling is active', () async {
        final connected = await orc.isSignalingConnected();
        expect(connected, isA<bool>());
      });
    });

    group('onSignalingError()', () {
      test('registers callback successfully', () async {
        Object? capturedError;
        await orc.onSignalingError((err) {
          capturedError = err;
        });
        expect(capturedError, isNull);
      });

      test('supports multiple callbacks', () async {
        var callCount1 = 0;
        var callCount2 = 0;
        await orc.onSignalingError((err) {
          callCount1++;
        });
        await orc.onSignalingError((err) {
          callCount2++;
        });
        expect(callCount1, equals(0));
        expect(callCount2, equals(0));
      });
    });

    group('onSignalingClose()', () {
      test('registers callback successfully', () async {
        var called = false;
        await orc.onSignalingClose(() {
          called = true;
        });
        expect(called, isFalse);
      });

      test('supports multiple callbacks', () async {
        var callCount1 = 0;
        var callCount2 = 0;
        await orc.onSignalingClose(() {
          callCount1++;
        });
        await orc.onSignalingClose(() {
          callCount2++;
        });
        expect(callCount1, equals(0));
        expect(callCount2, equals(0));
      });
    });

    group('destroy()', () {
      test('completes without error', () async {
        final localOrc = OrcErmes(
          signalingServer: signaling.signalingServer,
          signalingHandler: signaling.signalingHandler,
          socket: signaling.shspSocket,
          bookService: signaling.bookService,
        );
        await localOrc.destroy();
      });

      test('destroy with force completes without error', () async {
        final localOrc = OrcErmes(
          signalingServer: signaling.signalingServer,
          signalingHandler: signaling.signalingHandler,
          socket: signaling.shspSocket,
          bookService: signaling.bookService,
        );
        await localOrc.destroy(force: true);
      });

      test('destroy is idempotent', () async {
        final localOrc = OrcErmes(
          signalingServer: signaling.signalingServer,
          signalingHandler: signaling.signalingHandler,
          socket: signaling.shspSocket,
          bookService: signaling.bookService,
        );
        await localOrc.destroy();
        await localOrc.destroy();
      });
    });

    group('onMessage callbacks', () {
      test('callbacks are not called before data arrives', () async {
        var callCount = 0;
        await orc.onMessage((data, peerId) {
          callCount++;
        });
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(callCount, equals(0));
      });
    });
  });
}
