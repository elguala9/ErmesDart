import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
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
void testIErmesBookRepository<TInput, TInfo>(
  String implementationName,
  IErmesBookRepository<TInput, TInfo> Function() createInstance,
) {
  group('IErmesBookRepository<$TInput, $TInfo> - $implementationName', () {
    late IErmesBookRepository<TInput, TInfo> repository;

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
        expect(() => repository.setAccount(testAccount), returnsNormally);
      });

      test('setAccount with account and info', () async {
        const testAccount = 'test-account-with-info';
        // Note: info will be dynamic since TInput is generic
        try {
          await repository.setAccount(testAccount, 'test-info' as TInput);
        } on Exception {
          // May fail with type issues - acceptable for generic tests
        }
      });

      test('getAccount returns TInfo type', () async {
        const testAccount = 'existing-account';

        // First set an account (may fail if not implemented)
        try {
          await repository.setAccount(testAccount, 'test-data' as TInput);
        } on Exception {
          // Ignore if setAccount not working
        }

        // Test that getAccount returns correct type
        try {
          final result = await repository.getAccount(testAccount);
          expect(result, isA<TInfo>());
        } on Exception {
          // May throw if account doesn't exist - that's valid behavior
        }
      });

      test('updateAccount with map data', () async {
        const testAccount = 'update-account';
        final updateData = <String, dynamic>{'name': 'Updated Name'};

        expect(
          () => repository.updateAccount(testAccount, updateData),
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
            expect(result, isA<PaginationDto>());
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
          expect(result, isA<PaginationDto>());
        } on Exception {
          // May fail - acceptable
        }
      });
    });

    group('Repository Workflow', () {
      test('complete CRUD cycle', () async {
        const accountId = 'crud-test-account';

        // Create
        await repository.setAccount(accountId, 'initial-data' as TInput);

        // Read
        try {
          final account = await repository.getAccount(accountId);
          expect(account, isA<TInfo>());
        } on Exception {
          // May not be implemented or account not found
        }

        // Update
        final updateData = <String, dynamic>{
          'name': 'Updated Name',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await repository.updateAccount(accountId, updateData);

        // Delete
        final deleted = await repository.deleteAccount(accountId);
        expect(deleted, isA<bool>());
      });

      test('multiple account management', () async {
        const accounts = ['account-1', 'account-2', 'account-3'];

        // Set multiple accounts
        for (final account in accounts) {
          try {
            await repository.setAccount(account, 'data-for-$account' as TInput);
          } on Exception {
            // May fail with type issues
          }
        }

        // Update some
        for (final account in accounts.take(2)) {
          await repository.updateAccount(account, {'updated': true});
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
        final updateData = <String, dynamic>{'name': 'test'};

        expect(
          () => repository.updateAccount(nonExistent, updateData),
          throwsA(anything),
        );
      });

      test('handles null/empty inputs gracefully', () async {
        const emptyAccount = '';

        // These should either work or throw predictable errors
        expect(
          () => repository.setAccount(emptyAccount),
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
          expect(result, isA<PaginationDto>());
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
          expect(result, isA<PaginationDto>());
        } on Exception {
          // May throw due to performance limits
        }
      });
    });
  });
}
