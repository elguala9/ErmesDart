import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesStorageRepository with WorkDb', () {
    late IWorkDb db;

    setUp(() {
      final factory = WorkDbFactory();
      db = factory.create(const MemoryWorkDbFactoryInput());
    });

    group('basic operations', () {
      test('should create repository with default collection', () {
        final repo = ErmesStorageRepository<MessageType>(db);
        expect(repo, isNotNull);
        expect(repo.numberOfElements(), equals(0));
      });

      test('should create repository with custom collection', () {
        final repo = ErmesStorageRepository<MessageType>(
          db,
          'custom_collection',
        );
        expect(repo, isNotNull);
      });

      test('should handle empty state', () async {
        final repo = ErmesStorageRepository<MessageType>(db, 'empty_test');

        expect(repo.numberOfElements(), equals(0));
        expect(await repo.listOfIds(), isEmpty);
        expect(await repo.retrieve(1), isNull);
      });

      test('should delete from empty repository', () async {
        final repo = ErmesStorageRepository<MessageType>(db, 'empty_delete');

        final deleted = await repo.delete(999);
        expect(deleted, isFalse);
        expect(repo.numberOfElements(), equals(0));
      });
    });

    group('concurrent access', () {
      test('should handle concurrent clear operations', () async {
        final repo = ErmesStorageRepository<MessageType>(
          db,
          'concurrent_clear',
        );

        final operations = <Future<void>>[];

        for (var i = 0; i < 5; i++) {
          operations.add(repo.clear());
        }

        await Future.wait(operations);
        expect(repo.numberOfElements(), equals(0));
      });

      test('should handle concurrent destroy operations', () async {
        final repo =
            ErmesStorageRepository<MessageType>(db, 'concurrent_destroy');

        await repo.destroy();
        await repo.destroy();
        expect(repo.numberOfElements(), equals(0));
      });
    });

    group('collection isolation', () {
      test('should isolate data by collection', () async {
        final repo1 = ErmesStorageRepository<MessageType>(db, 'collection1');
        final repo2 = ErmesStorageRepository<MessageType>(db, 'collection2');

        await repo1.clear();
        await repo2.clear();

        // Both should be empty initially
        expect(repo1.numberOfElements(), equals(0));
        expect(repo2.numberOfElements(), equals(0));

        // Clear operations on one shouldn't affect the other
        await repo1.clear();
        expect(repo2.numberOfElements(), equals(0));
      });
    });

    group('error handling', () {
      test('should handle database operations gracefully', () async {
        final repo = ErmesStorageRepository<MessageType>(db, 'error_test');

        // Multiple clears should not cause issues
        await repo.clear();
        await repo.clear();
        await repo.clear();

        expect(repo.numberOfElements(), equals(0));
      });
    });

    group('state management', () {
      test('should track numberOfElements accurately', () async {
        final repo = ErmesStorageRepository<MessageType>(db, 'count_test');

        expect(repo.numberOfElements(), equals(0));

        // After clear
        await repo.clear();
        expect(repo.numberOfElements(), equals(0));

        // After destroy
        await repo.destroy();
        expect(repo.numberOfElements(), equals(0));
      });

      test('should return empty list after clear', () async {
        final repo = ErmesStorageRepository<MessageType>(db, 'list_test');

        await repo.clear();
        final ids = await repo.listOfIds();

        expect(ids, isEmpty);
      });
    });
  });
}
