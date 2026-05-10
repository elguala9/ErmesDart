import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesBookRepository', () {
    late ErmesBookRepository bookRepo;

    setUp(() {
      bookRepo = ErmesBookRepository();
    });

    test('should start empty', () {
      expect(bookRepo.numberOfElements(), equals(0));
      expect(bookRepo.listOfIds(), isEmpty);
    });

    test('should set and get account', () {
      bookRepo.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      final account = bookRepo.getAccount('peer1');
      expect(account.info?.name, equals('Alice'));
    });

    test('should update account name', () {
      bookRepo.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      bookRepo.updateAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Bob', timestamp: 2000),
      ));

      final account = bookRepo.getAccount('peer1');
      expect(account.info?.name, equals('Bob'));
    });

    test('should throw when getting non-existent account', () {
      expect(
        () => bookRepo.getAccount('unknown'),
        throwsException,
      );
    });

    test('should throw when updating non-existent account', () {
      expect(
        () => bookRepo.updateAccount(AccountInfo<BookData>(
          account: 'unknown',
          info: BookData(peerId: 'unknown', name: 'X', timestamp: 0),
        )),
        throwsException,
      );
    });

    test('should delete account', () {
      bookRepo.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      final deleted = bookRepo.deleteAccount('peer1');
      expect(deleted, isTrue);
      expect(bookRepo.numberOfElements(), equals(0));
    });

    test('should return false when deleting non-existent account', () {
      final deleted = bookRepo.deleteAccount('nonexistent');
      expect(deleted, isFalse);
    });

    test('should paginate account list', () {
      for (var i = 0; i < 10; i++) {
        final id = 'peer$i';
        bookRepo.setAccount(AccountInfo<BookData>(
          account: id,
          info: BookData(peerId: id, name: 'User$i', timestamp: i),
        ));
      }

      final page = bookRepo.getAccountList('', 5);
      expect(page.items.length, equals(5));
      expect(page.totalItems, equals(10));
      expect(page.eof, isFalse);
    });

    test('should clear all accounts', () {
      bookRepo.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      bookRepo.clear();
      expect(bookRepo.numberOfElements(), equals(0));
    });
  });
}
