import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test concreti per ErmesBookRepository usando le factories
///
/// Testa l'implementazione concreta di IErmesBookRepository<BookData>
@includeInBarrelFile
void testErmesBookRepositoryImplementation() {
  group('ErmesBookRepository Concrete Implementation', () {
    late IErmesBookRepository<BookData> repository;

    setUp(() {
      repository = ErmesBookRepository();
    });

    tearDown(() async {
      try {
        await repository.destroy();
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
      test('setAccount stores account info', () async {
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

        await repository.setAccount(accountInfo);
        expect(repository.numberOfElements(), equals(1));
      });

      test('getAccount retrieves stored account', () async {
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

        await repository.setAccount(accountInfo);
        final retrieved = await repository.getAccount(accountId);

        expect(retrieved, isA<AccountInfo<BookData>>());
        expect(retrieved.account, equals(accountId));
        expect(retrieved.info?.name, equals('Test Peer 2'));
      });

      test('updateAccount modifies existing account', () async {
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

        await repository.setAccount(initialInfo);

        final updatedData = BookData(
          peerId: accountId,
          name: 'Updated Name',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final updatedInfo = AccountInfo<BookData>(
          account: accountId,
          info: updatedData,
        );

        await repository.updateAccount(updatedInfo);
        final retrieved = await repository.getAccount(accountId);

        expect(retrieved.info?.name, equals('Updated Name'));
      });

      test('deleteAccount removes account', () async {
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

        await repository.setAccount(accountInfo);
        expect(repository.numberOfElements(), equals(1));

        final deleted = await repository.deleteAccount(accountId);
        expect(deleted, isTrue);
        expect(repository.numberOfElements(), equals(0));
      });

      test('deleteAccount returns false for non-existent account', () async {
        final deleted = await repository.deleteAccount('non-existent');
        expect(deleted, isFalse);
      });
    });

    group('Account Listing', () {
      test('getAccountList returns paginated accounts', () async {
        const accountIds = ['account-a', 'account-b', 'account-c'];

        for (final id in accountIds) {
          final data = BookData(
            peerId: id,
            name: 'Peer $id',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          final info = AccountInfo<BookData>(account: id, info: data);
          await repository.setAccount(info);
        }

        final result = await repository.getAccountList('', 10);

        expect(result, isA<PaginationDto<AccountInfo<BookData>, String>>());
        expect(result.items, hasLength(3));
        expect(result.items[0].account, equals('account-a'));
      });

      test('listOfIds returns all account ids', () async {
        const accountIds = ['id-1', 'id-2', 'id-3'];

        for (final id in accountIds) {
          final data = BookData(
            peerId: id,
            name: 'Peer $id',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          final info = AccountInfo<BookData>(account: id, info: data);
          await repository.setAccount(info);
        }

        final ids = await repository.listOfIds();
        expect(ids, containsAll(accountIds));
      });
    });

    group('Repository Lifecycle', () {
      test('clear removes all accounts', () async {
        const accountIds = ['acc-1', 'acc-2'];

        for (final id in accountIds) {
          final data = BookData(
            peerId: id,
            name: 'Peer $id',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          final info = AccountInfo<BookData>(account: id, info: data);
          await repository.setAccount(info);
        }

        await repository.clear();
        expect(repository.numberOfElements(), equals(0));
      });

      test('destroy clears and deinitializes repository', () async {
        const accountId = 'destroy-test';
        final data = BookData(
          peerId: accountId,
          name: 'Test',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final info = AccountInfo<BookData>(account: accountId, info: data);
        await repository.setAccount(info);

        await repository.destroy();
        expect(repository.numberOfElements(), equals(0));
      });
    });

    group('Error Handling', () {
      test('getAccount throws for non-existent account', () async {
        expect(
          () => repository.getAccount('non-existent'),
          throwsA(isA<Exception>()),
        );
      });

      test('updateAccount throws for non-existent account', () async {
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

      test('ErmesBookService delegates to repository', () async {
        final service = ErmesBookService();
        const accountId = 'service-test';
        final data = BookData(
          peerId: accountId,
          name: 'Service Test',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        final info = AccountInfo<BookData>(account: accountId, info: data);

        await service.setAccount(info);
        final retrieved = await service.getAccount(accountId);

        expect(retrieved.account, equals(accountId));
        expect(retrieved.info?.name, equals('Service Test'));

        // Cleanup
        await service.destroy();
      });
    });
  });
}

void main() {
  testErmesBookRepositoryImplementation();
}
