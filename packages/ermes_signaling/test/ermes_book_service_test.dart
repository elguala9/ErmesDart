import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesBookServiceBase', () {
    late ErmesBookRepository bookRepo;
    late ErmesBookServiceBase service;

    setUp(() {
      bookRepo = ErmesBookRepository();
      service = ErmesBookServiceBase();
      service.repository = bookRepo;
    });

    test('should set and get account via service', () {
      service.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      final account = service.getAccount('peer1');
      expect(account.info?.name, equals('Alice'));
    });

    test('should delegate delete to repository', () {
      service.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      expect(service.deleteAccount('peer1'), isTrue);
      expect(service.numberOfElements(), equals(0));
    });

    test('should list IDs', () {
      service.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      expect(service.listOfIds(), contains('peer1'));
    });

    test('should clear all data', () {
      service.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));

      service.clear();
      expect(service.numberOfElements(), equals(0));
    });
  });

  group('ErmesBookService', () {
    test('should be a singleton', () {
      final s1 = ErmesBookService();
      final s2 = ErmesBookService();
      expect(identical(s1, s2), isTrue);
    });
  });

  group('BookData', () {
    test('should create book data', () {
      final data = BookData(peerId: 'peer1', name: 'Alice', timestamp: 12345);
      expect(data.peerId, equals('peer1'));
      expect(data.name, equals('Alice'));
      expect(data.timestamp, equals(12345));
    });
  });
}
