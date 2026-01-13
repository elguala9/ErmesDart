import 'package:ermes_core/ermes_core.dart';
import 'package:test/test.dart';

void main() {
  group('IdHandler Interface Contract Tests', () {
    group('IdHandlerRepository', () {
      late IdHandlerRepository repository;

      setUp(() {
        repository = IdHandlerRepository();
      });

      test('should generate sequential IDs', () {
        expect(repository.getNewId(), equals(0));
        expect(repository.getNewId(), equals(1));
        expect(repository.getNewId(), equals(2));
      });

      test('should get current counter without incrementing', () {
        repository.getNewId(); // 0
        repository.getNewId(); // 1
        expect(repository.getCurrent(), equals(2));
      });

      test('should set counter to specific value', () {
        repository.setCounter(100);
        expect(repository.getCurrent(), equals(100));
        expect(repository.getNewId(), equals(100));
      });

      test('should reset counter to zero', () {
        repository.getNewId();
        repository.getNewId();
        repository.reset();
        expect(repository.getCurrent(), equals(0));
        expect(repository.getNewId(), equals(0));
      });

      test('should handle rapid generation without conflicts', () {
        final ids = <int>[];
        for (var i = 0; i < 100; i++) {
          ids.add(repository.getNewId());
        }

        // Verify all IDs are sequential
        for (var i = 0; i < 100; i++) {
          expect(ids[i], equals(i));
        }
      });

      test('should maintain state consistency across operations', () {
        expect(repository.getCurrent(), equals(0));
        expect(repository.getNewId(), equals(0));
        expect(repository.getCurrent(), equals(1));

        repository.setCounter(50);
        expect(repository.getCurrent(), equals(50));
        expect(repository.getNewId(), equals(50));
        expect(repository.getCurrent(), equals(51));

        repository.reset();
        expect(repository.getCurrent(), equals(0));
      });
    });

    group('IdHandlerService', () {
      late IdHandlerService service;

      setUp(() {
        service = IdHandlerService(repo: IdHandlerRepository());
      });

      test('should delegate to repository for ID generation', () {
        expect(service.getNewId(), isNotNull);
      });

      test('should maintain service-level state', () {
        final id1 = service.getNewId();
        final id2 = service.getNewId();
        expect(id2, greaterThan(id1));
      });

      test('should support reset through service interface', () {
        service.getNewId();
        service.getNewId();
        service.reset();
        // After reset, next ID should start from 0
        expect(service.getCurrent(), equals(0));
      });
    });
  });
}
