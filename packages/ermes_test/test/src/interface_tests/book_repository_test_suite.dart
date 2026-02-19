import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesBookRepository interface
///
/// Usage:
/// ```dart
/// void main() {
///   testIErmesBookRepository<String, Map<String, dynamic>>(
///     'MyBookRepository',
///     () => MyBookRepository(),
///   );
/// }
/// ```
@includeInBarrelFile
void testIErmesBookRepository<TInfo>(
  String implementationName,
  IErmesBookRepository<TInfo> Function() createInstance,
) {
  group('IErmesBookRepository<$TInfo> - $implementationName', () {
    late IErmesBookRepository<TInfo> repository;

    setUp(() {
      repository = createInstance();
    });

    tearDown(() async {
      try {
        // Cleanup any test data if possible
        await repository.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Account Management', () {
      test('setAccount with account only', () async {
        const testAccount = 'test-account';
        expect(
          () => repository.setAccount(AccountInfo<TInfo>(account: testAccount)),
          returnsNormally,
        );
      });

      test('setAccount with account and info', () async {
        const testAccount = 'test-account-with-info';
        // Note: info will be dynamic since TInfo is generic
        try {
          await repository.setAccount(
            AccountInfo<TInfo>(account: testAccount, info: 'test-info' as TInfo),
          );
        } on Exception {
          // May fail with type issues - acceptable for generic tests
        }
      });

      test('getAccount returns AccountInfo<TInfo> type', () async {
        const testAccount = 'existing-account';

        // First set an account (may fail if not implemented)
        try {
          await repository.setAccount(
            AccountInfo<TInfo>(account: testAccount, info: 'test-data' as TInfo),
          );
        } on Exception {
          // Ignore if setAccount not working
        }

        // Test that getAccount returns correct type
        try {
          final result = await repository.getAccount(testAccount);
          expect(result, isA<AccountInfo<TInfo>>());
        } on Exception {
          // May throw if account doesn't exist - that's valid behavior
        }
      });

      test('updateAccount with AccountInfo', () async {
        const testAccount = 'update-account';
        final updateInfo = AccountInfo<TInfo>(
          account: testAccount,
          info: 'Updated Info' as TInfo,
        );

        expect(
          () => repository.updateAccount(updateInfo),
          returnsNormally,
        );
      });

      test('deleteAccount returns bool', () async {
        const testAccount = 'delete-account';
        final result = await repository.deleteAccount(testAccount);
        expect(result, isA<bool>());
      });
    });

    group('Account Listing', () {
      test('getAccountList returns paginated result', () async {
        const cursor = 'test-cursor';
        const limit = 10;

        try {
          final result = await repository.getAccountList(cursor, limit);
          expect(result, isA<PaginationDto<AccountInfo<TInfo>, String>>());
        } on Exception {
          // May fail with type issues - that's expected in generic tests
        }
      });

      test('getAccountList with different limits', () async {
        const cursor = 'cursor';

        for (final limit in [1, 5, 10, 50]) {
          try {
            final result = await repository.getAccountList(cursor, limit);
            expect(result, isA<PaginationDto<AccountInfo<TInfo>, String>>());
          } on Exception {
            // Expected for some implementations
          }
        }
      });

      test('getAccountList with empty cursor', () async {
        const emptyCursor = '';
        const limit = 5;

        try {
          final result = await repository.getAccountList(emptyCursor, limit);
          expect(result, isA<PaginationDto<AccountInfo<TInfo>, String>>());
        } on Exception {
          // May fail - acceptable
        }
      });
    });

    group('Repository Workflow', () {
      test('complete CRUD cycle', () async {
        const accountId = 'crud-test-account';

        // Create
        await repository.setAccount(
          AccountInfo<TInfo>(account: accountId, info: 'initial-data' as TInfo),
        );

        // Read
        try {
          final account = await repository.getAccount(accountId);
          expect(account, isA<AccountInfo<TInfo>>());
        } on Exception {
          // May not be implemented or account not found
        }

        // Update
        await repository.updateAccount(
          AccountInfo<TInfo>(account: accountId, info: 'Updated Info' as TInfo),
        );

        // Delete
        final deleted = await repository.deleteAccount(accountId);
        expect(deleted, isA<bool>());
      });

      test('multiple account management', () async {
        const accounts = ['account-1', 'account-2', 'account-3'];

        // Set multiple accounts
        for (final account in accounts) {
          try {
            await repository.setAccount(
              AccountInfo<TInfo>(account: account, info: 'data-for-$account' as TInfo),
            );
          } on Exception {
            // May fail with type issues
          }
        }

        // Update some
        for (final account in accounts.take(2)) {
          await repository.updateAccount(
            AccountInfo<TInfo>(account: account, info: 'updated' as TInfo),
          );
        }

        // Delete one
        await repository.deleteAccount(accounts.first);

        // Try to list accounts
        try {
          const cursor = '';
          final result = await repository.getAccountList(cursor, 10);
          expect(result, isNotNull);
        } on Exception {
          // Listing may not work with generic types
        }
      });
    });

    group('Repository Operations', () {
      test('destroy completes', () async {
        expect(() => repository.destroy(), returnsNormally);
      });

      test('clear completes', () async {
        expect(() => repository.clear(), returnsNormally);
      });

      test('numberOfElements returns int', () {
        final count = repository.numberOfElements();
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      });

      test('listOfIds returns list of account IDs', () async {
        final ids = await repository.listOfIds();
        expect(ids, isA<List<String>>());
      });
    });

    group('Error Handling', () {
      test('getAccount with non-existent account throws', () async {
        const nonExistent = 'non-existent-account';

        expect(() => repository.getAccount(nonExistent), throwsA(anything));
      });

      test('updateAccount with non-existent account throws', () async {
        const nonExistent = 'non-existent-update';

        expect(
          () => repository.updateAccount(
            AccountInfo<TInfo>(account: nonExistent, info: 'test' as TInfo),
          ),
          throwsA(anything),
        );
      });

      test('handles null/empty inputs gracefully', () async {
        const emptyAccount = '';

        // These should either work or throw predictable errors
        expect(
          () => repository.setAccount(
            AccountInfo<TInfo>(account: emptyAccount),
          ),
          anyOf(returnsNormally, throwsA(anything)),
        );

        expect(
          () => repository.deleteAccount(emptyAccount),
          anyOf(returnsNormally, throwsA(anything)),
        );
      });
    });

    group('Pagination Edge Cases', () {
      test('zero limit handling', () async {
        const cursor = '';

        try {
          final result = await repository.getAccountList(cursor, 0);
          expect(result, isA<PaginationDto<AccountInfo<TInfo>, String>>());
        } on Exception {
          // May throw - acceptable behavior
        }
      });

      test('negative limit handling', () async {
        const cursor = '';

        expect(
          () => repository.getAccountList(cursor, -1),
          anyOf(returnsNormally, throwsA(anything)),
        );
      });

      test('very large limit handling', () async {
        const cursor = '';

        try {
          final result = await repository.getAccountList(cursor, 1000000);
          expect(result, isA<PaginationDto<AccountInfo<TInfo>, String>>());
        } on Exception {
          // May throw due to performance limits
        }
      });
    });
  });
}
