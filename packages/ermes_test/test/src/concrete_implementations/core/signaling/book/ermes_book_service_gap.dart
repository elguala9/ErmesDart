import 'dart:io';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void testErmesBookServiceGaps() {
  group('ErmesBookServiceBase - gap methods', () {
    late ErmesBookServiceBase bookService;

    setUp(() {
      bookService = ErmesBookServiceBase(ErmesBookRepository());
    });

    group('getPeerInfo', () {
      test('returns null for unknown account', () {
        final info = bookService.getPeerInfo('unknown');
        expect(info, isNull);
      });

      test('returns peer info after setAccount', () {
        bookService.setAccount(AccountInfo<BookData>(
          account: 'peer1',
          peerInfo: ErmesPeerInfo(
            address: InternetAddress('127.0.0.1'),
            port: 9000,
            id: 'peer1',
          ),
        ));
        final info = bookService.getPeerInfo('peer1');
        expect(info, isNotNull);
        expect(info!.id, equals('peer1'));
      });
    });

    group('updateAccount', () {
      test('throws when account does not exist', () {
        expect(
          () => bookService.updateAccount(const AccountInfo<BookData>(
            account: 'nonexistent',
          )),
          throwsException,
        );
      });

      test('updates name for existing account', () {
        bookService
          ..setAccount(AccountInfo<BookData>(
            account: 'peer1',
            info: BookData(
              peerId: 'peer1',
              name: 'Original',
              timestamp: 1000,
            ),
          ))
          ..updateAccount(AccountInfo<BookData>(
            account: 'peer1',
            info: BookData(
              peerId: 'peer1',
              name: 'Updated',
              timestamp: 2000,
            ),
          ));
        final account = bookService.getAccount('peer1');
        expect(account.info!.name, equals('Updated'));
      });
    });

    group('getAccountList', () {
      test('returns empty list for no accounts', () {
        final result = bookService.getAccountList('', 10);
        expect(result.items, isEmpty);
        expect(result.eof, isTrue);
      });

      test('returns paginated accounts', () {
        bookService
          ..setAccount(AccountInfo<BookData>(
            account: 'a',
            info: BookData(peerId: 'a', name: 'A', timestamp: 1),
          ))
          ..setAccount(AccountInfo<BookData>(
            account: 'b',
            info: BookData(peerId: 'b', name: 'B', timestamp: 2),
          ));
        final result = bookService.getAccountList('', 1);
        expect(result.items, hasLength(1));
        expect(result.eof, isFalse);
      });
    });

    group('destroy', () {
      test('clears all data', () {
        bookService.setAccount(AccountInfo<BookData>(
          account: 'peer1',
          info: BookData(peerId: 'peer1', name: 'Test', timestamp: 1),
        ));
        expect(bookService.numberOfElements(), equals(1));
        bookService.destroy();
        expect(bookService.numberOfElements(), equals(0));
        expect(bookService.getPeerInfo('peer1'), isNull);
      });

      test('can be called multiple times', () {
        bookService.destroy();
        expect(bookService.destroy, returnsNormally);
      });
    });
  });

  group('ErmesBookRepository - getPeerInfo', () {
    test('returns null for unknown peer', () {
      final repo = ErmesBookRepository();
      expect(repo.getPeerInfo('unknown'), isNull);
    });

    test('returns peer info after setAccount with peerInfo', () {
      final repo = ErmesBookRepository()
        ..setAccount(AccountInfo<BookData>(
          account: 'peer1',
          peerInfo: ErmesPeerInfo(
            address: InternetAddress('127.0.0.1'),
            port: 9000,
            id: 'peer1',
          ),
        ));
      final info = repo.getPeerInfo('peer1');
      expect(info, isNotNull);
      expect(info!.id, equals('peer1'));
    });

    test('returns null when account has no peerInfo', () {
      final repo = ErmesBookRepository()
        ..setAccount(AccountInfo<BookData>(
          account: 'peer1',
          info: BookData(peerId: 'peer1', name: 'Test', timestamp: 1),
        ));
      expect(repo.getPeerInfo('peer1'), isNull);
    });
  });
}
