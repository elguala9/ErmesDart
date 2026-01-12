import 'package:ermes_storage/ermes_storage.dart';
import 'package:test/test.dart';

/// Test suite per verificare l'implementazione di IErmesStorageRepository
///
/// Questo test suite verifica che tutte le implementazioni di IErmesStorageRepository
/// funzionino correttamente e mantengano la consistenza dei dati.
void testStorageRepository<DataJson>(
  String name,
  IErmesStorageRepository<DataJson> Function(
    DataJson Function(Map<String, dynamic>) fromJson,
    DataJson Function(DataJson) toJson,
  )
  create,
  DataJson Function(Map<String, dynamic>) fromJson,
  DataJson Function(DataJson) toJson,
) {
  group('Storage Repository Tests - $name', () {
    late IErmesStorageRepository<DataJson> repository;

    setUp(() {
      repository = create(fromJson, toJson);
    });

    tearDown(() async {
      await repository.destroy();
    });

    test('should store and retrieve data', () async {
      final data = fromJson({'id': '1', 'content': 'test'});

      await repository.store(data);
      final retrieved = await repository.retrieve('1');

      expect(retrieved, isNotNull);
    });

    test('should return null for non-existent data', () async {
      final retrieved = await repository.retrieve('non-existent');
      expect(retrieved, isNull);
    });

    test('should delete data', () async {
      final data = fromJson({'id': '1', 'content': 'test'});

      await repository.store(data);
      final deleted = await repository.delete('1');
      expect(deleted, isTrue);

      final retrieved = await repository.retrieve('1');
      expect(retrieved, isNull);
    });

    test('should return false when deleting non-existent data', () async {
      final deleted = await repository.delete('non-existent');
      expect(deleted, isFalse);
    });

    test('should clear all data', () async {
      final data1 = fromJson({'id': '1', 'content': 'test1'});
      final data2 = fromJson({'id': '2', 'content': 'test2'});

      await repository.store(data1);
      await repository.store(data2);

      expect(repository.numberOfElements(), equals(2));

      await repository.clear();
      expect(repository.numberOfElements(), equals(0));
    });

    test('should return correct number of elements', () async {
      expect(repository.numberOfElements(), equals(0));

      final data1 = fromJson({'id': '1', 'content': 'test1'});
      await repository.store(data1);
      expect(repository.numberOfElements(), equals(1));

      final data2 = fromJson({'id': '2', 'content': 'test2'});
      await repository.store(data2);
      expect(repository.numberOfElements(), equals(2));
    });

    test('should list all IDs', () async {
      final data1 = fromJson({'id': '1', 'content': 'test1'});
      final data2 = fromJson({'id': '2', 'content': 'test2'});

      await repository.store(data1);
      await repository.store(data2);

      final ids = await repository.listOfIds();
      expect(ids, isNotEmpty);
      expect(ids.length, equals(2));
    });

    test(
      'should maintain data consistency after multiple operations',
      () async {
        final data1 = fromJson({'id': '1', 'content': 'test1'});
        final data2 = fromJson({'id': '2', 'content': 'test2'});
        final data3 = fromJson({'id': '3', 'content': 'test3'});

        // Store
        await repository.store(data1);
        await repository.store(data2);
        expect(repository.numberOfElements(), equals(2));

        // Add more
        await repository.store(data3);
        expect(repository.numberOfElements(), equals(3));

        // Delete
        await repository.delete('2');
        expect(repository.numberOfElements(), equals(2));

        // Verify remaining
        final ids = await repository.listOfIds();
        expect(ids.length, equals(2));
        expect(ids, containsAll(['1', '3']));
      },
    );

    test('should not lose data after retrieve', () async {
      final data = fromJson({'id': '1', 'content': 'test'});

      await repository.store(data);
      await repository.retrieve('1');

      final retrieved = await repository.retrieve('1');
      expect(retrieved, isNotNull);
    });

    test('should handle empty operations gracefully', () async {
      await repository.clear();
      expect(repository.numberOfElements(), equals(0));

      final ids = await repository.listOfIds();
      expect(ids, isEmpty);
    });
  });
}
