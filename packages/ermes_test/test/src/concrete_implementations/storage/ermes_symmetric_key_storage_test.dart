import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesSymmetricKeyRepository', () {
    late IWorkDb db;
    late IErmesSymmetricKeyRepository repo;

    setUp(() {
      final factory = WorkDbFactory();
      db = factory.create(const MemoryWorkDbFactoryInput());
      repo = createErmesSymmetricKeyRepository(db);
    });

    tearDown(() async {
      await repo.destroy();
    });

    group('store', () {
      test('should store a symmetric key', () async {
        final key = StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'test_key_123',
          idPeer: '100',
        );

        await repo.store(key);

        expect(repo.numberOfElements(), equals(1));
      });

      test('should overwrite existing key with same id', () async {
        final key1 = StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'original_key',
          idPeer: '100',
        );
        final key2 = StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 2)),
          key: 'updated_key',
          idPeer: '100',
        );

        await repo.store(key1);
        await repo.store(key2);

        // Should still be 1 element (overwritten)
        expect(repo.numberOfElements(), equals(1));
      });

      test('should store multiple keys with different ids', () async {
        final keys = [
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 1)),
            key: 'key_1',
            idPeer: '100',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 2)),
            key: 'key_2',
            idPeer: '200',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 3)),
            key: 'key_3',
            idPeer: '300',
          ),
        ];

        for (final key in keys) {
          await repo.store(key);
        }

        expect(repo.numberOfElements(), equals(3));
      });
    });

    group('retrieve', () {
      test('should retrieve stored symmetric key', () async {
        final original = StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'test_key_123',
          idPeer: '100',
        );

        await repo.store(original);
        final retrieved = await repo.retrieve(100);

        expect(retrieved, isNotNull);
        expect(retrieved?.key, equals('test_key_123'));
        expect(retrieved?.idPeer, equals('100'));
      });

      test('should return null for non-existent key', () async {
        final retrieved = await repo.retrieve(999);
        expect(retrieved, isNull);
      });

      test('should retrieve correct key from multiple stored keys', () async {
        final keys = [
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 1)),
            key: 'key_A',
            idPeer: '100',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 2)),
            key: 'key_B',
            idPeer: '200',
          ),
        ];

        for (final key in keys) {
          await repo.store(key);
        }

        final retrieved = await repo.retrieve(200);
        expect(retrieved?.key, equals('key_B'));
      });

      test('should properly deserialize all fields', () async {
        final now = DateTime(2026, 4, 24, 10, 30);
        final original = StorageSymmetricKeyType(
          expiration: now,
          key: 'complex_key_!@#percent',
          idPeer: '12345',
        );

        await repo.store(original);
        final retrieved = await repo.retrieve(12345);

        expect(retrieved?.key, equals('complex_key_!@#percent'));
        expect(retrieved?.idPeer, equals('12345'));
        expect(retrieved?.expiration, equals(now));
      });
    });

    group('delete', () {
      test('should delete stored key', () async {
        final key = StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'test_key',
          idPeer: '100',
        );

        await repo.store(key);
        expect(repo.numberOfElements(), equals(1));

        final deleted = await repo.delete(100);
        expect(deleted, isTrue);
        expect(repo.numberOfElements(), equals(0));
      });

      test('should return false when deleting non-existent key', () async {
        final deleted = await repo.delete(999);
        expect(deleted, isFalse);
      });

      test('should only delete specified key', () async {
        final keys = [
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 1)),
            key: 'key_1',
            idPeer: '100',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 2)),
            key: 'key_2',
            idPeer: '200',
          ),
        ];

        for (final key in keys) {
          await repo.store(key);
        }

        await repo.delete(100);
        expect(repo.numberOfElements(), equals(1));

        final remaining = await repo.retrieve(200);
        expect(remaining, isNotNull);
        expect(remaining?.key, equals('key_2'));
      });
    });

    group('listOfIds', () {
      test('should return empty list when no keys stored', () async {
        final ids = await repo.listOfIds();
        expect(ids, isEmpty);
      });

      test('should return all stored key ids', () async {
        final keys = [
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 1)),
            key: 'key_1',
            idPeer: '100',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 2)),
            key: 'key_2',
            idPeer: '200',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 3)),
            key: 'key_3',
            idPeer: '300',
          ),
        ];

        for (final key in keys) {
          await repo.store(key);
        }

        final ids = await repo.listOfIds();
        expect(ids.length, equals(3));
        expect(ids, containsAll([100, 200, 300]));
      });

      test('should reflect deletions in listOfIds', () async {
        final keys = [
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 1)),
            key: 'key_1',
            idPeer: '100',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 2)),
            key: 'key_2',
            idPeer: '200',
          ),
        ];

        for (final key in keys) {
          await repo.store(key);
        }

        await repo.delete(100);

        final ids = await repo.listOfIds();
        expect(ids, equals([200]));
      });
    });

    group('numberOfElements', () {
      test('should return 0 for empty repository', () async {
        expect(repo.numberOfElements(), equals(0));
      });

      test('should increment on store', () async {
        expect(repo.numberOfElements(), equals(0));

        await repo.store(StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'key_1',
          idPeer: '100',
        ));
        expect(repo.numberOfElements(), equals(1));

        await repo.store(StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'key_2',
          idPeer: '200',
        ));
        expect(repo.numberOfElements(), equals(2));
      });

      test('should decrement on delete', () async {
        await repo.store(StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'key_1',
          idPeer: '100',
        ));
        expect(repo.numberOfElements(), equals(1));

        await repo.delete(100);
        expect(repo.numberOfElements(), equals(0));
      });

      test('should not change on failed delete', () async {
        expect(repo.numberOfElements(), equals(0));

        await repo.delete(999);
        expect(repo.numberOfElements(), equals(0));
      });
    });

    group('clear', () {
      test('should clear all keys', () async {
        final keys = [
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 1)),
            key: 'key_1',
            idPeer: '100',
          ),
          StorageSymmetricKeyType(
            expiration: DateTime.now().add(const Duration(days: 2)),
            key: 'key_2',
            idPeer: '200',
          ),
        ];

        for (final key in keys) {
          await repo.store(key);
        }

        expect(repo.numberOfElements(), equals(2));

        await repo.clear();

        expect(repo.numberOfElements(), equals(0));
        expect(await repo.listOfIds(), isEmpty);
      });

      test('should allow restoring after clear', () async {
        await repo.store(StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'key_1',
          idPeer: '100',
        ));

        await repo.clear();
        expect(repo.numberOfElements(), equals(0));

        await repo.store(StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'key_2',
          idPeer: '200',
        ));

        expect(repo.numberOfElements(), equals(1));
        final retrieved = await repo.retrieve(200);
        expect(retrieved?.key, equals('key_2'));
      });
    });

    group('destroy', () {
      test('should clear database', () async {
        await repo.store(StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'key_1',
          idPeer: '100',
        ));

        await repo.destroy();

        expect(repo.numberOfElements(), equals(0));
      });
    });

    group('serialization', () {
      test('should properly serialize and deserialize with special characters',
          () async {
        final original = StorageSymmetricKeyType(
          expiration: DateTime(2026, 12, 31, 23, 59, 59),
          key: 'key_with_!@#_special_chars_^&*()_+-=[]{}|;:,.<>?/~`',
          idPeer: '999',
        );

        await repo.store(original);
        final retrieved = await repo.retrieve(999);

        expect(retrieved?.key, equals(original.key));
        expect(retrieved?.idPeer, equals(original.idPeer));
        expect(retrieved?.expiration, equals(original.expiration));
      });

      test('should preserve DateTime precision', () async {
        final precise = DateTime(2026, 6, 15, 14, 30, 45, 123, 456);
        final key = StorageSymmetricKeyType(
          expiration: precise,
          key: 'test_key',
          idPeer: '100',
        );

        await repo.store(key);
        final retrieved = await repo.retrieve(100);

        // DateTime.parse loses microseconds precision, check ISO8601
        expect(
          retrieved?.expiration.toIso8601String(),
          equals(precise.toIso8601String()),
        );
      });
    });
  });

  group('ErmesSymmetricKeyService', () {
    late IWorkDb db;
    late IErmesSymmetricKeyService service;

    setUp(() {
      final factory = WorkDbFactory();
      db = factory.create(const MemoryWorkDbFactoryInput());
      final repo = createErmesSymmetricKeyRepository(db);
      service = createErmesSymmetricKeyService(repo);
    });

    tearDown(() async {
      await service.destroy();
    });

    test('should delegate to repository correctly', () async {
      final key = StorageSymmetricKeyType(
        expiration: DateTime.now().add(const Duration(days: 1)),
        key: 'service_test_key',
        idPeer: '100',
      );

      await service.store(key);
      expect(service.numberOfElements(), equals(1));

      final retrieved = await service.retrieve(100);
      expect(retrieved?.key, equals('service_test_key'));

      await service.delete(100);
      expect(service.numberOfElements(), equals(0));
    });

    test('should handle all operations through service interface', () async {
      final keys = [
        StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 1)),
          key: 'key_a',
          idPeer: '111',
        ),
        StorageSymmetricKeyType(
          expiration: DateTime.now().add(const Duration(days: 2)),
          key: 'key_b',
          idPeer: '222',
        ),
      ];

      for (final key in keys) {
        await service.store(key);
      }

      expect(service.numberOfElements(), equals(2));

      final ids = await service.listOfIds();
      expect(ids.length, equals(2));

      await service.clear();
      expect(service.numberOfElements(), equals(0));
    });
  });
}
