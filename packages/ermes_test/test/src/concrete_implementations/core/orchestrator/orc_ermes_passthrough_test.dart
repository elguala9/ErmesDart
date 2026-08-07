import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_signaling_helper.dart';

void main() {
  testOrcErmesPassthrough();
}

AccountInfo<BookData> _account(String id) => AccountInfo<BookData>(
      account: id,
      info: BookData(
        peerId: id,
        name: 'Peer $id',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

void testOrcErmesPassthrough() {
  group('OrcErmesPassthrough', () {
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

    group('setAccount() / getAccount()', () {
      test('stores and retrieves an account via the book service', () async {
        await orc.setAccount(_account('passthrough-peer-1'));
        final result = await orc.getAccount('passthrough-peer-1');
        expect(result.account, equals('passthrough-peer-1'));
      });
    });

    group('updateAccount()', () {
      test('replaces a previously stored account', () async {
        await orc.setAccount(_account('passthrough-peer-2'));
        final updated = AccountInfo<BookData>(
          account: 'passthrough-peer-2',
          info: BookData(
            peerId: 'passthrough-peer-2',
            name: 'Updated Name',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        await orc.updateAccount(updated);

        final result = await orc.getAccount('passthrough-peer-2');
        expect(result.info?.name, equals('Updated Name'));
      });
    });

    group('getAccountList()', () {
      test('returns a paginated list including added accounts', () async {
        await orc.setAccount(_account('passthrough-peer-3'));
        final page = await orc.getAccountList('', 10);
        expect(
          page.items.any((a) => a.account == 'passthrough-peer-3'),
          isTrue,
        );
      });
    });

    group('deleteAccount()', () {
      test('removes a stored account and reports success', () async {
        await orc.setAccount(_account('passthrough-peer-4'));
        final deleted = await orc.deleteAccount('passthrough-peer-4');
        expect(deleted, isTrue);
      });

      test('returns false for a non-existent account', () async {
        final deleted = await orc.deleteAccount('never-existed');
        expect(deleted, isFalse);
      });
    });

    group('numberOfElements() / listOfIds()', () {
      test('reflects the accounts currently stored', () async {
        await orc.setAccount(_account('passthrough-peer-5'));
        final ids = await orc.listOfIds();
        expect(ids, contains('passthrough-peer-5'));

        final count = await orc.numberOfElements();
        expect(count, equals(ids.length));
      });
    });

    group('getPeerInfo()', () {
      test('returns null for an account without peer info', () async {
        await orc.setAccount(_account('passthrough-peer-6'));
        final info = await orc.getPeerInfo('passthrough-peer-6');
        expect(info, isNull);
      });

      test('returns the stored peer info when present', () async {
        const id = 'passthrough-peer-7';
        await orc.setAccount(AccountInfo<BookData>(
          account: id,
          peerInfo: ErmesPeerInfo(
            address: InternetAddress('127.0.0.1'),
            port: 4000,
            id: id,
          ),
        ));
        final info = await orc.getPeerInfo(id);
        expect(info, isNotNull);
        expect(info!.port, equals(4000));
      });
    });

    group('clear()', () {
      test('empties the book service', () async {
        await orc.setAccount(_account('passthrough-peer-8'));
        await orc.clear();
        final count = await orc.numberOfElements();
        expect(count, equals(0));
      });

      test('is idempotent', () async {
        await orc.clear();
        await orc.clear();
        final count = await orc.numberOfElements();
        expect(count, equals(0));
      });
    });

    group('getIdAccount()', () {
      test('delegates to the signaling server', () async {
        final accountId = await orc.getIdAccount();
        expect(accountId, equals(signaling.accountId));
      });
    });

    group('isSignalingConnected()', () {
      test('delegates to the signaling server', () async {
        final connected = await orc.isSignalingConnected();
        expect(connected, isA<bool>());
      });
    });

    group('onSignalingError() / onSignalingClose()', () {
      test('registers a signaling-error callback without invoking it',
          () async {
        Object? captured;
        await orc.onSignalingError((err) => captured = err);
        expect(captured, isNull);
      });

      test('registers a signaling-close callback without invoking it',
          () async {
        var called = false;
        await orc.onSignalingClose(() => called = true);
        expect(called, isFalse);
      });
    });
  });
}
