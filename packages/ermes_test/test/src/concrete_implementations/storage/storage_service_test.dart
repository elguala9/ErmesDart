import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesStorageService', () {
    late ErmesStorageRepository<MessageType> realRepo;
    late ErmesStorageService<MessageType> service;

    setUp(() {
      realRepo = ErmesStorageRepository<MessageType>(
        WorkDb.memory(),
        ErmesStorageRepository.defaultCollection,
        MessageType.fromJson,
      );
      service = ErmesStorageService<MessageType>(realRepo);
    });

    tearDown(() async {
      await realRepo.destroy();
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

    group('edge cases and error handling', () {
      MessageType buildMessage(int id, List<int> bytes) => MessageType.data(
            MessageData(id: id, data: Uint8List.fromList(bytes)),
          );

      test('store then retrieve round-trips real data through the service',
          () async {
        final item = buildMessage(1, [1, 2, 3]);

        await service.store(item);
        final retrieved = await service.retrieve(1);

        expect(retrieved, isNotNull);
        expect(retrieved?.id, equals(1));
        expect(retrieved?.asData()?.data, equals([1, 2, 3]));
      });

      test('delete removes an item that was stored through the service',
          () async {
        final item = buildMessage(2, [9]);

        await service.store(item);
        expect(await service.delete(2), isTrue);
        expect(await service.retrieve(2), isNull);
      });

      test('re-storing the same id updates in place without growing the '
          'element count', () async {
        final v1 = buildMessage(3, [1]);
        final v2 = buildMessage(3, [2]);

        await service.store(v1);
        await service.store(v2);

        expect(service.numberOfElements(), equals(1));
        expect((await service.retrieve(3))?.asData()?.data, equals([2]));
      });

      test('listOfIds reflects items stored through the service', () async {
        final item = buildMessage(4, [7]);
        await service.store(item);

        final ids = await service.listOfIds();
        expect(ids, contains(4));
      });

      test('retrieve throws UnimplementedError when the repository has no '
          'fromJsonFactory (falls back to StorageType.fromJson)', () async {
        final noFactoryRepo = ErmesStorageRepository<MessageType>(
          WorkDb.memory(),
          'no_factory_collection',
        );
        final noFactoryService = ErmesStorageService<MessageType>(
          noFactoryRepo,
        );

        final item = buildMessage(5, [1]);
        await noFactoryService.store(item);

        await expectLater(
          noFactoryService.retrieve(5),
          throwsA(isA<UnimplementedError>()),
        );

        await noFactoryRepo.destroy();
      });

      test('concurrent stores through the service all persist correctly',
          () async {
        await Future.wait([
          for (var i = 100; i < 110; i++) service.store(buildMessage(i, [i])),
        ]);

        expect(service.numberOfElements(), equals(10));
        for (var i = 100; i < 110; i++) {
          expect(await service.retrieve(i), isNotNull);
        }
      });
    });
  });
}
