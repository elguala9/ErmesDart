import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:test/test.dart';

void testIdHandlerServiceFactory() {
  group('IdHandlerServiceFactory', () {
    group('createDefault()', () {
      test('should create service with default configuration', () {
        final service = IdHandlerServiceFactory.createDefault();

        expect(service.getCurrent(), equals(0));
        expect(service.getNewId(), equals(0));
      });
    });

    group('createWithRange()', () {
      test('should create service with custom range', () {
        final service = IdHandlerServiceFactory.createWithRange(
          start: 50,
          max: 100,
        );

        expect(service.getCurrent(), equals(50));
        service.setCounter(99);
        expect(service.getNewId(), equals(99));
        expect(service.getNewId(), equals(100));
        expect(service.getNewId(), equals(0));
      });

      test('should reject a start greater than max', () {
        expect(
          () => IdHandlerServiceFactory.createWithRange(start: 11, max: 10),
          throwsArgumentError,
        );
      });

      test('should accept start exactly equal to max', () {
        final service =
            IdHandlerServiceFactory.createWithRange(start: 10, max: 10);
        expect(service.getNewId(), equals(10));
        expect(service.getNewId(), equals(0)); // wraps immediately
      });
    });

    group('createWithStorage()', () {
      test('should use the given storage for persisted IDs', () {
        final storage = IdHandlerStorageFactory.createDefault();
        final service = IdHandlerServiceFactory.createWithStorage(storage);

        expect(() => service.getNewId(), returnsNormally);
      });
    });

    group('create()', () {
      test('should create multiple independent services', () {
        final service1 = IdHandlerServiceFactory.create();
        final service2 = IdHandlerServiceFactory.createWithRange(
          start: 100,
          max: 200,
        );

        expect(service1.getNewId(), equals(0));
        expect(service2.getNewId(), equals(100));
        expect(service1.getNewId(), equals(1));
        expect(service2.getNewId(), equals(101));
      });

      test('should generate 1000 IDs per service independently', () {
        final service1 = IdHandlerServiceFactory.createDefault();
        final service2 = IdHandlerServiceFactory.createDefault();

        for (var i = 0; i < 1000; i++) {
          expect(service1.getNewId(), equals(i));
          expect(service2.getNewId(), equals(i));
        }
      });

      test('should default repositoryInput to start 0 / default max when '
          'not provided', () {
        final service = IdHandlerServiceFactory.create();
        expect(service.getCurrent(), equals(0));
      });
    });
  });
}

void main() {
  testIdHandlerServiceFactory();
}
