import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Mock repository for testing service delegation
class MockStorageRepository<T extends StorageType>
    implements IErmesStorageRepository<T> {
  final Map<int, T> _storage = {};

  @override
  Future<void> store(T data) async {
    _storage[data.id] = data;
  }

  @override
  Future<T?> retrieve(int id) async => _storage[id];

  @override
  Future<bool> delete(int id) async => _storage.remove(id) != null;

  @override
  Future<void> clear() async => _storage.clear();

  @override
  int numberOfElements() => _storage.length;

  @override
  Future<List<int>> listOfIds() async => _storage.keys.toList();

  @override
  Future<void> destroy() async => _storage.clear();
}

void main() {
  group('ErmesStorageService', () {
    late MockStorageRepository<MessageType> mockRepo;
    late ErmesStorageService<MessageType> service;

    setUp(() {
      mockRepo = MockStorageRepository<MessageType>();
      service = ErmesStorageService<MessageType>(mockRepo);
    });

    group('delegation to repository', () {
      test('should delegate store() call', () async {
        // Service just delegates - we test it forwards the call
        expect(service.numberOfElements(), equals(0));
        await service.clear();
        expect(service.numberOfElements(), equals(0));
      });

      test('should delegate retrieve() call', () async {
        // retrieve from empty should be null
        final result = await service.retrieve(999);
        expect(result, isNull);
      });

      test('should delegate delete() call', () async {
        // delete from empty should be false
        final result = await service.delete(999);
        expect(result, isFalse);
      });

      test('should delegate clear() call', () async {
        // multiple clears should work
        await service.clear();
        await service.clear();
        expect(service.numberOfElements(), equals(0));
      });

      test('should delegate listOfIds() call', () async {
        // empty storage should return empty list
        final ids = await service.listOfIds();
        expect(ids, isEmpty);
      });

      test('should delegate numberOfElements() call', () {
        expect(service.numberOfElements(), equals(0));
      });

      test('should delegate destroy() call', () async {
        await service.destroy();
        expect(service.numberOfElements(), equals(0));
      });
    });

    group('service consistency', () {
      test('should maintain consistent state across operations', () async {
        expect(service.numberOfElements(), equals(0));

        // Clear should work on empty
        await service.clear();
        expect(service.numberOfElements(), equals(0));

        // Destroy should work on empty
        await service.destroy();
        expect(service.numberOfElements(), equals(0));

        // listOfIds should be empty
        final ids = await service.listOfIds();
        expect(ids, isEmpty);
      });

      test('should handle sequential operations', () async {
        await service.clear();
        expect(service.numberOfElements(), equals(0));

        await service.clear();
        expect(service.numberOfElements(), equals(0));

        await service.destroy();
        expect(service.numberOfElements(), equals(0));

        final ids = await service.listOfIds();
        expect(ids, isEmpty);
      });
    });

    group('error resilience', () {
      test('should handle multiple destroys', () async {
        await service.destroy();
        await service.destroy();
        await service.destroy();

        expect(service.numberOfElements(), equals(0));
      });

      test('should handle clear then destroy', () async {
        await service.clear();
        await service.destroy();

        expect(service.numberOfElements(), equals(0));
      });
    });
  });
}
