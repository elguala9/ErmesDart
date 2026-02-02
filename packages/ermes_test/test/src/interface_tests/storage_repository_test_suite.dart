import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesStorageRepository interface.
///
/// Validates interface contracts for storage repositories:
/// - Return type consistency across all storage operations
/// - Persistent storage state across lifecycle
/// - Proper delete and clear semantics
@includeInBarrelFile
void testStorageRepository<DataJson extends MessageType>(
  String name,
  IErmesStorageRepository<DataJson> Function() create,
) {
  group('IErmesStorageRepository<$DataJson>', () {
    late IErmesStorageRepository<DataJson> repository;

    setUp(() {
      repository = create();
    });

    tearDown(() async {
      try {
        await repository.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    test('$name - retrieve() returns Future<MessageType?>', () async {
      final result = repository.retrieve(999);
      expect(result, isA<Future<MessageType?>>());
      final data = await result;
      expect(data, isNull);
    });

    test('$name - delete() returns Future<bool>', () async {
      final result = repository.delete(999);
      expect(result, isA<Future<bool>>());
      final deleted = await result;
      expect(deleted, isFalse);
    });

    test('$name - numberOfElements() returns int', () async {
      final count = repository.numberOfElements();
      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    test('$name - listOfIds() returns Future<List<dynamic>>', () async {
      final result = repository.listOfIds();
      expect(result, isA<Future<List<dynamic>>>());
      final ids = await result;
      expect(ids, isA<List<dynamic>>());
    });

    test('$name - clear() returns Future<void>', () async {
      final result = repository.clear();
      expect(result, isA<Future<void>>());
      await result;
    });

    test('$name - destroy() returns Future<void>', () async {
      final result = repository.destroy();
      expect(result, isA<Future<void>>());
      await result;
    });

    test('$name - empty storage has 0 elements', () async {
      await repository.clear();
      final count = repository.numberOfElements();
      expect(count, equals(0));
    });

    test('$name - empty storage returns empty ID list', () async {
      await repository.clear();
      final ids = await repository.listOfIds();
      expect(ids, isEmpty);
    });
  });
}
