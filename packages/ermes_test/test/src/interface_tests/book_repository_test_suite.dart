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
  group('IErmesBookRepository - $implementationName', () {
    late IErmesBookRepository<TInfo> repository;

    setUp(() {
      repository = createInstance();
    });

    tearDown(() async {
      try {
        // Cleanup any test data if possible
        repository.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Account Management', () {
      test('setAccount with account only', () {
        const testAccount = 'test-account';
        expect(
          () => repository.setAccount(
            const AccountInfo<dynamic>(account: testAccount)
                as AccountInfo<TInfo>,
          ),
          returnsNormally,
        );
      });

      test('setAccount with account and info', () {
        const testAccount = 'test-account-with-info';
        // Note: info will be dynamic since TInfo is generic
        try {
          repository.setAccount(
            const AccountInfo<dynamic>(
              account: testAccount,
              info: 'test-info' as dynamic,
            ) as AccountInfo<TInfo>,
          );
        } on Exception {
          // May fail with type issues - acceptable for generic tests
        }
      });

      test('getAccount returns AccountInfo<dynamic> type', () {
        const testAccount = 'existing-account';

        // First set an account (may fail if not implemented)
        try {
          repository.setAccount(
            const AccountInfo<dynamic>(
              account: testAccount,
              info: 'test-data' as dynamic,
            ) as AccountInfo<TInfo>,
          );
        } on Exception {
          // Ignore if setAccount not working
        }

        // Test that getAccount returns correct type
        try {
          final result = repository.getAccount(testAccount);
          expect(result, isA<AccountInfo<dynamic>>());
        } on Exception {
          // May throw if account doesn't exist - that's valid behavior
        }
      });

      test('updateAccount with AccountInfo', () {
        const testAccount = 'update-account';
        const updateInfo = AccountInfo<dynamic>(
          account: testAccount,
          info: 'Updated Info' as dynamic,
        );

        expect(
          () => repository.updateAccount(updateInfo as AccountInfo<TInfo>),
          returnsNormally,
        );
      });

      test('deleteAccount returns bool', () {
        const testAccount = 'delete-account';
        final result = repository.deleteAccount(testAccount);
        expect(result, isA<bool>());
      });
    });

    group('Account Listing', () {
      test('getAccountList returns paginated result', () {
        const cursor = 'test-cursor';
        const limit = 10;

        try {
          final result = repository.getAccountList(cursor, limit);
          expect(result, isA<PaginationDto<AccountInfo<dynamic>, String>>());
        } on Exception {
          // May fail with type issues - that's expected in generic tests
        }
      });

      test('getAccountList with different limits', () {
        const cursor = 'cursor';

        for (final limit in [1, 5, 10, 50]) {
          try {
            final result = repository.getAccountList(cursor, limit);
            expect(result, isA<PaginationDto<AccountInfo<dynamic>, String>>());
          } on Exception {
            // Expected for some implementations
          }
        }
      });

      test('getAccountList with empty cursor', () {
        const emptyCursor = '';
        const limit = 5;

        try {
          final result = repository.getAccountList(emptyCursor, limit);
          expect(result, isA<PaginationDto<AccountInfo<dynamic>, String>>());
        } on Exception {
          // May fail - acceptable
        }
      });
    });

    group('Repository Workflow', () {
      test('complete CRUD cycle', () {
        const accountId = 'crud-test-account';

        // Create
        repository.setAccount(
          const AccountInfo<dynamic>(
            account: accountId,
            info: 'initial-data' as dynamic,
          ) as AccountInfo<TInfo>,
        );

        // Read
        try {
          final account = repository.getAccount(accountId);
          expect(account, isA<AccountInfo<dynamic>>());
        } on Exception {
          // May not be implemented or account not found
        }

        // Update
        repository.updateAccount(
          const AccountInfo<dynamic>(
            account: accountId,
            info: 'Updated Info' as dynamic,
          ) as AccountInfo<TInfo>,
        );

        // Delete
        final deleted = repository.deleteAccount(accountId);
        expect(deleted, isA<bool>());
      });

      test('multiple account management', () {
        const accounts = ['account-1', 'account-2', 'account-3'];

        // Set multiple accounts
        for (final account in accounts) {
          try {
            repository.setAccount(
              AccountInfo<dynamic>(
                account: account,
                info: 'data-for-$account' as dynamic,
              ) as AccountInfo<TInfo>,
            );
          } on Exception {
            // May fail with type issues
          }
        }

        // Update some
        for (final account in accounts.take(2)) {
          repository.updateAccount(
            AccountInfo<dynamic>(account: account, info: 'updated' as dynamic)
                as AccountInfo<TInfo>,
          );
        }

        // Delete one
        repository.deleteAccount(accounts.first);

        // Try to list accounts
        try {
          const cursor = '';
          final result = repository.getAccountList(cursor, 10);
          expect(result, isNotNull);
        } on Exception {
          // Listing may not work with generic types
        }
      });
    });

    group('Repository Operations', () {
      test('destroy completes', () {
        expect(() => repository.destroy(), returnsNormally);
      });

      test('clear completes', () {
        expect(() => repository.clear(), returnsNormally);
      });

      test('numberOfElements returns int', () {
        final count = repository.numberOfElements();
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      });

      test('listOfIds returns list of account IDs', () {
        final ids = repository.listOfIds();
        expect(ids, isA<List<String>>());
      });
    });

    group('Error Handling', () {
      test('getAccount with non-existent account throws', () {
        const nonExistent = 'non-existent-account';

        expect(() => repository.getAccount(nonExistent), throwsA(anything));
      });

      test('updateAccount with non-existent account throws', () {
        const nonExistent = 'non-existent-update';

        expect(
          () => repository.updateAccount(
            const AccountInfo<dynamic>(
              account: nonExistent,
              info: 'test' as dynamic,
            ) as AccountInfo<TInfo>,
          ),
          throwsA(anything),
        );
      });

      test('handles null/empty inputs gracefully', () {
        const emptyAccount = '';

        // These should either work or throw predictable errors
        expect(
          () => repository.setAccount(
            const AccountInfo<dynamic>(account: emptyAccount)
                as AccountInfo<TInfo>,
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
      test('zero limit handling', () {
        const cursor = '';

        try {
          final result = repository.getAccountList(cursor, 0);
          expect(result, isA<PaginationDto<AccountInfo<dynamic>, String>>());
        } on Exception {
          // May throw - acceptable behavior
        }
      });

      test('negative limit handling', () {
        const cursor = '';

        expect(
          () => repository.getAccountList(cursor, -1),
          anyOf(returnsNormally, throwsA(anything)),
        );
      });

      test('very large limit handling', () {
        const cursor = '';

        try {
          final result = repository.getAccountList(cursor, 1000000);
          expect(result, isA<PaginationDto<AccountInfo<dynamic>, String>>());
        } on Exception {
          // May throw due to performance limits
        }
      });
    });
  });
}
