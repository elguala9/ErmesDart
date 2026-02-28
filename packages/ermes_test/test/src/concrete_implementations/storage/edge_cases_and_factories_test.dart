import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('Edge Cases - Caching Repository', () {
    late ErmesCachingRepository<MessageType> repository;

    setUp(() {
      repository = ErmesCachingRepository<MessageType>(100);
    });

    tearDown(() async {
      await repository.destroy();
    });

    group('Boundary values', () {
      test('should handle buffer size = 1', () async {
        final smallBuffer = ErmesCachingRepository<MessageType>(1);

        expect(smallBuffer.numberOfElements(), equals(0));

        await smallBuffer.clear();
        expect(smallBuffer.numberOfElements(), equals(0));

        await smallBuffer.destroy();
      });

      test('should handle very large buffer', () async {
        final largeBuffer =
            ErmesCachingRepository<MessageType>(100000);

        expect(largeBuffer.numberOfElements(), equals(0));

        await largeBuffer.clear();
        expect(largeBuffer.numberOfElements(), equals(0));

        await largeBuffer.destroy();
      });
    });

    group('Repeated operations', () {
      test('should handle consecutive clears', () async {
        for (var i = 0; i < 100; i++) {
          await repository.clear();
        }

        expect(repository.numberOfElements(), equals(0));
      });

      test('should handle consecutive destroys', () async {
        for (var i = 0; i < 10; i++) {
          await repository.destroy();
        }

        expect(repository.numberOfElements(), equals(0));
      });

      test('should handle alternating clear and destroy', () async {
        for (var i = 0; i < 5; i++) {
          await repository.clear();
          await repository.destroy();
        }

        expect(repository.numberOfElements(), equals(0));
      });

      test('should handle rapid fire clear operations', () async {
        final operations = <Future<void>>[];

        for (var i = 0; i < 50; i++) {
          operations.add(repository.clear());
        }

        await Future.wait(operations);
        expect(repository.numberOfElements(), equals(0));
      });
    });

    group('Buffer edge cases', () {
      test('buffer at capacity stays at capacity', () async {
        final testBuffer =
            ErmesCachingRepository<MessageType>(3);

        expect(testBuffer.numberOfElements(), equals(0));

        await testBuffer.clear();
        expect(testBuffer.numberOfElements(), equals(0));

        await testBuffer.destroy();
      });

      test('multiple destroys on full buffer', () async {
        final testBuffer =
            ErmesCachingRepository<MessageType>(5);

        for (var i = 0; i < 3; i++) {
          await testBuffer.destroy();
        }

        expect(testBuffer.numberOfElements(), equals(0));
      });
    });

    group('State consistency', () {
      test('numberOfElements is consistent after operations', () async {
        expect(repository.numberOfElements(), equals(0));

        await repository.clear();
        expect(repository.numberOfElements(), equals(0));

        await repository.destroy();
        expect(repository.numberOfElements(), equals(0));

        final ids = await repository.listOfIds();
        expect(ids, isEmpty);
      });

      test('listOfIds matches numberOfElements', () async {
        final ids = await repository.listOfIds();
        expect(ids.length, equals(repository.numberOfElements()));

        await repository.clear();
        final idsAfterClear = await repository.listOfIds();
        expect(idsAfterClear.length,
            equals(repository.numberOfElements()));
      });

      test('maintains state through clear-destroy cycles', () async {
        for (var cycle = 0; cycle < 5; cycle++) {
          expect(repository.numberOfElements(), equals(0));

          await repository.clear();
          expect(repository.numberOfElements(), equals(0));

          final ids = await repository.listOfIds();
          expect(ids, isEmpty);

          await repository.destroy();
          expect(repository.numberOfElements(), equals(0));
        }
      });
    });

    group('Concurrent edge cases', () {
      test('concurrent clears on single repo', () async {
        final operations = <Future<void>>[];

        for (var i = 0; i < 20; i++) {
          operations.add(repository.clear());
        }

        await Future.wait(operations);
        expect(repository.numberOfElements(), equals(0));
      });

      test('concurrent listOfIds calls', () async {
        final futures = <Future<List<int>>>[];

        for (var i = 0; i < 10; i++) {
          futures.add(repository.listOfIds());
        }

        final results = await Future.wait(futures);

        for (final result in results) {
          expect(result, isEmpty);
        }
      });

      test('concurrent clear and destroy mix', () async {
        final operations = <Future<void>>[];

        for (var i = 0; i < 10; i++) {
          if (i.isEven) {
            operations.add(repository.clear());
          } else {
            operations.add(repository.destroy());
          }
        }

        await Future.wait(operations);
        expect(repository.numberOfElements(), equals(0));
      });
    });

    group('Service integration', () {
      test('service with edge case buffer', () async {
        final tinyCache = ErmesCachingRepository<MessageType>(1);
        final service = ErmesCachingService<MessageType>(tinyCache);

        expect(service.numberOfElements(), equals(0));

        await service.clear();
        expect(service.numberOfElements(), equals(0));

        await service.destroy();
        expect(service.numberOfElements(), equals(0));
      });

      test('service with large buffer', () async {
        final largeCache =
            ErmesCachingRepository<MessageType>(10000);
        final service = ErmesCachingService<MessageType>(largeCache);

        expect(service.numberOfElements(), equals(0));

        await service.clear();
        expect(service.numberOfElements(), equals(0));

        await service.destroy();
        expect(service.numberOfElements(), equals(0));
      });
    });

    group('Error recovery', () {
      test('recovers from rapid operations', () async {
        for (var i = 0; i < 100; i++) {
          await repository.clear();
        }

        expect(repository.numberOfElements(), equals(0));
        final ids = await repository.listOfIds();
        expect(ids, isEmpty);
      });

      test('handles delete calls on empty repo', () async {
        for (var i = 0; i < 100; i++) {
          final result = await repository.delete(i);
          expect(result, isFalse);
        }

        expect(repository.numberOfElements(), equals(0));
      });

      test('handles retrieve calls on empty repo', () async {
        for (var i = 0; i < 100; i++) {
          final result = await repository.retrieve(i);
          expect(result, isNull);
        }

        expect(repository.numberOfElements(), equals(0));
      });
    });
  });
}
