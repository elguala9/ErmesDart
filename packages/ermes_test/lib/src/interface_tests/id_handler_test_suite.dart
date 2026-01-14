import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite per verificare l'implementazione di IIdHandlerRepository
/// Testa la generazione di ID sequenziali, wrapping, reset e consistenza
@includeInBarrelFile
void testIdHandlerRepository(
  String name,
  IIdHandlerRepository Function() create,
) {
  group('IdHandlerRepository Tests - $name', () {
    late IIdHandlerRepository repository;

    setUp(() {
      repository = create();
    });

    test('should generate sequential IDs starting from 0', () {
      expect(repository.getNewId(), equals(0));
      expect(repository.getNewId(), equals(1));
      expect(repository.getNewId(), equals(2));
    });

    test('should maintain current counter correctly', () {
      repository
        ..getNewId() // 0
        ..getNewId() // 1
        ..getNewId(); // 2

      expect(repository.getCurrent(), equals(3));
    });

    test('should reset counter', () {
      repository
        ..getNewId() // 0
        ..getNewId() // 1
        ..getNewId() // 2
        ..reset();

      expect(repository.getCurrent(), equals(0));
      expect(repository.getNewId(), equals(0));
    });

    test('should set counter from specified value', () {
      repository.setCounter(100);

      expect(repository.getNewId(), equals(100));
      expect(repository.getNewId(), equals(101));
    });

    test('should increment counter continuously', () {
      for (var i = 0; i < 10; i++) {
        expect(repository.getNewId(), equals(i));
      }

      expect(repository.getCurrent(), equals(10));
    });

    test('should handle counter overflow', () {
      // Set counter near max value
      repository.setCounter(1000000);

      final id1 = repository.getNewId();
      final id2 = repository.getNewId();

      expect(id1, equals(1000000));
      expect(id2, equals(1000001));
    });

    test('should maintain consistency across multiple calls', () {
      final ids = <int>[];

      for (var i = 0; i < 50; i++) {
        ids.add(repository.getNewId());
      }

      // Verify all IDs are unique
      expect(ids.toSet().length, equals(ids.length));

      // Verify IDs are sequential
      for (var i = 0; i < ids.length; i++) {
        expect(ids[i], equals(i));
      }
    });

    test('should allow reset and restart', () {
      repository
        ..getNewId()
        ..getNewId()
        ..getNewId()
        ..reset();

      expect(repository.getNewId(), equals(0));
      expect(repository.getNewId(), equals(1));
    });

    test('should preserve counter after setCounter', () {
      repository.setCounter(50);

      expect(repository.getCurrent(), equals(50));

      repository.getNewId();
      expect(repository.getCurrent(), equals(51));
    });

    test('should generate unique IDs after reset and setCounter', () {
      final id1 = repository.getNewId(); // 0
      final id2 = repository.getNewId(); // 1
      repository
        ..reset()
        ..setCounter(100);

      final id3 = repository.getNewId(); // 100
      final id4 = repository.getNewId(); // 101

      expect(id1, equals(0));
      expect(id2, equals(1));
      expect(id3, equals(100));
      expect(id4, equals(101));
    });
  });
}

/// Test suite per verificare l'implementazione di IIdHandlerService
@includeInBarrelFile
void testIdHandlerService(String name, IIdHandlerService Function() create) {
  group('IdHandlerService Tests - $name', () {
    late IIdHandlerService service;

    setUp(() {
      service = create();
    });

    test('should generate sequential IDs starting from 0', () {
      expect(service.getNewId(), equals(0));
      expect(service.getNewId(), equals(1));
      expect(service.getNewId(), equals(2));
    });

    test('should maintain current counter correctly', () {
      service
        ..getNewId() // 0
        ..getNewId() // 1
        ..getNewId(); // 2

      expect(service.getCurrent(), equals(3));
    });

    test('should reset counter', () {
      service
        ..getNewId() // 0
        ..getNewId() // 1
        ..getNewId() // 2
        ..reset();

      expect(service.getCurrent(), equals(0));
      expect(service.getNewId(), equals(0));
    });

    test('should set counter from specified value', () {
      service.setCounter(100);

      expect(service.getNewId(), equals(100));
      expect(service.getNewId(), equals(101));
    });

    test('should increment counter continuously', () {
      for (var i = 0; i < 10; i++) {
        expect(service.getNewId(), equals(i));
      }

      expect(service.getCurrent(), equals(10));
    });

    test('should maintain consistency across multiple calls', () {
      final ids = <int>[];

      for (var i = 0; i < 50; i++) {
        ids.add(service.getNewId());
      }

      // Verify all IDs are unique
      expect(ids.toSet().length, equals(ids.length));

      // Verify IDs are sequential
      for (var i = 0; i < ids.length; i++) {
        expect(ids[i], equals(i));
      }
    });

    test('should allow reset and restart', () {
      service
        ..getNewId()
        ..getNewId()
        ..getNewId()
        ..reset();

      expect(service.getNewId(), equals(0));
      expect(service.getNewId(), equals(1));
    });

    test('should preserve counter after setCounter', () {
      service.setCounter(50);

      expect(service.getCurrent(), equals(50));

      service.getNewId();
      expect(service.getCurrent(), equals(51));
    });
  });
}
