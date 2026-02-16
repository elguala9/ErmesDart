import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesCachingRepository interface.
///
/// Validates interface contracts for caching repositories:
/// - Return type consistency across all cache operations
/// - Cache state tracking and lifecycle
/// - Proper delete and clear semantics
@includeInBarrelFile
void testCachingRepository<DataJson extends MessageType>(
  String name,
  IErmesCachingRepository<DataJson> Function() create,
) {
  group('IErmesCachingRepository<$DataJson>', () {
    late IErmesCachingRepository<DataJson> repository;

    setUp(() {
      repository = create();
    });

    test('$name - new repository element count is 0', () async {
      final count = repository.numberOfElements();
      expect(count, equals(0));
    });

    test('$name - clear() returns Future<void>', () async {
      final result = repository.clear();
      expect(result, isA<Future<void>>());
      await result;
    });

    test('$name - clear() completes without error', () async {
      await expectLater(repository.clear(), completes);
    });

    test('$name - retrieve() returns Future<MessageType?>', () async {
      final result = repository.retrieve(0);
      expect(result, isA<Future<MessageType?>>());
      await result;
    });

    test('$name - listOfIds() returns Future<List<dynamic>>', () async {
      final result = repository.listOfIds();
      expect(result, isA<Future<List<dynamic>>>());
      final ids = await result;
      expect(ids, isA<List<dynamic>>());
    });

    test('$name - delete(id) returns Future<bool>', () async {
      final result = repository.delete(0);
      expect(result, isA<Future<bool>>());
      final deleted = await result;
      expect(deleted, isA<bool>());
    });

    test('$name - numberOfElements() returns int', () async {
      final count = repository.numberOfElements();
      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    test('$name - delete from empty repository returns false', () async {
      final deleted = await repository.delete(9999);
      expect(deleted, isFalse);
    });

    test('$name - destroy() returns Future<void>', () async {
      final result = repository.destroy();
      expect(result, isA<Future<void>>());
      await result;
    });

    test('$name - listOfIds in new repository is empty', () async {
      final ids = await repository.listOfIds();
      expect(ids, isEmpty);
    });
  });
}
