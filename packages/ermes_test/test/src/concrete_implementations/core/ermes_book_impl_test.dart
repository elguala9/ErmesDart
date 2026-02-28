
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test concreti per ErmesBookRepository usando le factories
///
/// Testa l'implementazione concreta di IErmesBookRepository

void testErmesBookRepositoryImplementation() {
  group('ErmesBookRepository Concrete Implementation', () {
    late IErmesBookRepository<BookData> repository;

    setUp(() {
      repository = ErmesBookRepository();
    });

    tearDown(() {
      try {
        repository.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Factory Creation', () {
      test('ErmesBookRepositoryFactory creates instance', () {
        final repo = ErmesBookRepositoryFactory.createDefault();
        expect(repo, isNotNull);
        expect(repo, isA<ErmesBookRepository>());
      });
    });

    group('Basic Operations', () {
      test('setAccount stores account info', () {
        const accountId = 'test-peer-1';
        final bookData = BookData(
          peerId: accountId,
          name: 'Test Peer',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final accountInfo = AccountInfo<BookData>(
          account: accountId,
          info: bookData,
        );

        repository.setAccount(accountInfo);
        expect(repository.numberOfElements(), equals(1));
      });

      test('getAccount retrieves stored account', () {
        const accountId = 'test-peer-2';
        final bookData = BookData(
          peerId: accountId,
          name: 'Test Peer 2',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final accountInfo = AccountInfo<BookData>(
          account: accountId,
          info: bookData,
        );

        repository.setAccount(accountInfo);
        final retrieved = repository.getAccount(accountId);

        expect(retrieved, isA<AccountInfo<BookData>>());
        expect(retrieved.account, equals(accountId));
        final info = retrieved.info;
        expect(info?.name, equals('Test Peer 2'));
      });

      test('updateAccount modifies existing account', () {
        const accountId = 'test-peer-3';
        final initialData = BookData(
          peerId: accountId,
          name: 'Initial Name',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final initialInfo = AccountInfo<BookData>(
          account: accountId,
          info: initialData,
        );

        repository.setAccount(initialInfo);

        final updatedData = BookData(
          peerId: accountId,
          name: 'Updated Name',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final updatedInfo = AccountInfo<BookData>(
          account: accountId,
          info: updatedData,
        );

        repository.updateAccount(updatedInfo);
        final retrieved = repository.getAccount(accountId);

        final info = retrieved.info;
        expect(info?.name, equals('Updated Name'));
      });

      test('deleteAccount removes account', () {
        const accountId = 'test-peer-4';
        final bookData = BookData(
          peerId: accountId,
          name: 'To Delete',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final accountInfo = AccountInfo<BookData>(
          account: accountId,
          info: bookData,
        );

        repository.setAccount(accountInfo);
        expect(repository.numberOfElements(), equals(1));

        final deleted = repository.deleteAccount(accountId);
        expect(deleted, isTrue);
        expect(repository.numberOfElements(), equals(0));
      });

      test('deleteAccount returns false for non-existent account', () {
        final deleted = repository.deleteAccount('non-existent');
        expect(deleted, isFalse);
      });
    });

    group('Account Listing', () {
      test('getAccountList returns paginated accounts', () {
        const accountIds = ['account-a', 'account-b', 'account-c'];

        for (final id in accountIds) {
          final data = BookData(
            peerId: id,
            name: 'Peer $id',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          final info = AccountInfo<BookData>(account: id, info: data);
          repository.setAccount(info);
        }

        final result = repository.getAccountList('', 10);

        expect(result, isA<PaginationDto<AccountInfo<BookData>, String>>());
        expect(result.items, hasLength(3));
        expect(result.items[0].account, equals('account-a'));
      });

      test('listOfIds returns all account ids', () {
        const accountIds = ['id-1', 'id-2', 'id-3'];

        for (final id in accountIds) {
          final data = BookData(
            peerId: id,
            name: 'Peer $id',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          final info = AccountInfo<BookData>(account: id, info: data);
          repository.setAccount(info);
        }

        final ids = repository.listOfIds();
        expect(ids, containsAll(accountIds));
      });
    });

    group('Repository Lifecycle', () {
      test('clear removes all accounts', () {
        const accountIds = ['acc-1', 'acc-2'];

        for (final id in accountIds) {
          final data = BookData(
            peerId: id,
            name: 'Peer $id',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          final info = AccountInfo<BookData>(account: id, info: data);
          repository.setAccount(info);
        }

        repository.clear();
        expect(repository.numberOfElements(), equals(0));
      });

      test('destroy clears and deinitializes repository', () {
        const accountId = 'destroy-test';
        final data = BookData(
          peerId: accountId,
          name: 'Test',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final info = AccountInfo<BookData>(account: accountId, info: data);
        repository
          ..setAccount(info)
          ..destroy();
        expect(repository.numberOfElements(), equals(0));
      });
    });

    group('Error Handling', () {
      test('getAccount throws for non-existent account', () {
        expect(
          () => repository.getAccount('non-existent'),
          throwsA(isA<Exception>()),
        );
      });

      test('updateAccount throws for non-existent account', () {
        const accountId = 'non-existent';
        final data = BookData(
          peerId: accountId,
          name: 'Update',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final info = AccountInfo<BookData>(account: accountId, info: data);

        expect(
          () => repository.updateAccount(info),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('ErmesBookService Integration', () {
      test('ErmesBookService is singleton', () {
        final service1 = ErmesBookService();
        final service2 = ErmesBookService();
        expect(identical(service1, service2), isTrue);
      });

      test('ErmesBookService delegates to repository', () {
        final service = ErmesBookService();
        const accountId = 'service-test';
        final data = BookData(
          peerId: accountId,
          name: 'Service Test',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final info = AccountInfo<BookData>(account: accountId, info: data);

        service.setAccount(info);
        final retrieved = service.getAccount(accountId);

        expect(retrieved.account, equals(accountId));
        final retrievedData = retrieved.info;
        if (retrievedData is BookData) {
          expect(retrievedData.name, equals('Service Test'));
        }

        // Cleanup
        service.destroy();
      });
    });
  });
}

void main() {
  testErmesBookRepositoryImplementation();
}
