// ignore_for_file: cascade_invocations

import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('IdHandlerRepository Core Tests', () {
    late IdHandlerRepository repository;

    setUp(() {
      repository = IdHandlerRepository();
    });

    test('should generate sequential IDs starting from 0', () {
      expect(repository.getNewId(), equals(0));
      expect(repository.getNewId(), equals(1));
      expect(repository.getNewId(), equals(2));
    });

    test('should maintain current counter', () {
      repository.getNewId(); // 0
      repository.getNewId(); // 1

      expect(repository.getCurrent(), equals(2));
    });

    test('should reset counter to initial value', () {
      repository.getNewId();
      repository.getNewId();

      repository.reset();

      expect(repository.getCurrent(), equals(0));
      expect(repository.getNewId(), equals(0));
    });

    test('should set counter to specific value', () {
      repository.setCounter(100);

      expect(repository.getCurrent(), equals(100));
      expect(repository.getNewId(), equals(100));
    });

    test('should wrap around when exceeding max value', () {
      final customRepo = IdHandlerRepository(max: 5, start: 4);

      expect(customRepo.getNewId(), equals(4)); // id 4
      expect(customRepo.getNewId(), equals(5)); // id 5, max reached
      expect(customRepo.getNewId(), equals(0)); // wraps to 0
      expect(customRepo.getNewId(), equals(1));
    });

    test('should reject negative counter', () {
      expect(() => repository.setCounter(-1), throwsArgumentError);
    });

    test('should reject counter exceeding max', () {
      final customRepo = IdHandlerRepository(max: 100);

      expect(() => customRepo.setCounter(101), throwsArgumentError);
    });

    test('should handle custom start value', () {
      final customRepo = IdHandlerRepository(start: 50);

      expect(customRepo.getCurrent(), equals(50));
      expect(customRepo.getNewId(), equals(50));
    });

    test('should handle large max values', () {
      final largeRepo = IdHandlerRepository();

      largeRepo.setCounter(9007199254740990);

      expect(largeRepo.getNewId(), equals(9007199254740990));
      expect(largeRepo.getNewId(), equals(0)); // wraps
    });

    test('should generate 1000 sequential IDs without error', () {
      for (var i = 0; i < 1000; i++) {
        expect(repository.getNewId(), equals(i));
      }
    });
  });

  group('IdHandlerService Tests', () {
    late IdHandlerService service;
    late IdHandlerRepository repository;

    setUp(() {
      repository = IdHandlerRepository();
      service = IdHandlerService(repo: repository);
    });

    test('should generate IDs through service', () {
      expect(service.getNewId(), equals(0));
      expect(service.getNewId(), equals(1));
      expect(service.getNewId(), equals(2));
    });

    test('should maintain service counter', () {
      service.getNewId();
      service.getNewId();

      expect(service.getCurrent(), equals(2));
    });

    test('should reset service counter', () {
      service.getNewId();
      service.getNewId();

      service.reset();

      expect(service.getCurrent(), equals(0));
    });

    test('should set service counter', () {
      service.setCounter(50);

      expect(service.getCurrent(), equals(50));
      expect(service.getNewId(), equals(50));
    });

    test('should work with custom repository', () {
      final customRepo = IdHandlerRepository(max: 10, start: 8);
      final customService = IdHandlerService(repo: customRepo);

      expect(customService.getNewId(), equals(8));
      expect(customService.getNewId(), equals(9));
      expect(customService.getNewId(), equals(10));
      expect(customService.getNewId(), equals(0)); // wraps
    });
  });

  group('IdHandlerFactory Tests', () {
    test('should create repository with default values', () {
      const input = IdHandlerRepositoryInput();
      final repository = IdHandlerFactory.createRepository(input);

      expect(repository.getCurrent(), equals(0));
      expect(repository.getNewId(), equals(0));
    });

    test('should create repository with custom max', () {
      const input = IdHandlerRepositoryInput(max: 100);
      final repository = IdHandlerFactory.createRepository(input);

      repository.setCounter(99);
      expect(repository.getNewId(), equals(99));
      expect(repository.getNewId(), equals(100));
      expect(repository.getNewId(), equals(0));
    });

    test('should create repository with custom start', () {
      const input = IdHandlerRepositoryInput(start: 50);
      final repository = IdHandlerFactory.createRepository(input);

      expect(repository.getCurrent(), equals(50));
    });

    test('should create service with factory', () {
      const repoInput = IdHandlerRepositoryInput(start: 10);

      final service = IdHandlerFactory.createService(
        IdHandlerServiceInput(
          repo: IdHandlerFactory.createRepository(repoInput),
        ),
      );

      expect(service.getCurrent(), equals(10));
      expect(service.getNewId(), equals(10));
    });

    test('should create multiple independent repositories', () {
      const input1 = IdHandlerRepositoryInput(start: 0);
      const input2 = IdHandlerRepositoryInput(start: 100);

      final repo1 = IdHandlerFactory.createRepository(input1);
      final repo2 = IdHandlerFactory.createRepository(input2);

      expect(repo1.getNewId(), equals(0));
      expect(repo2.getNewId(), equals(100));
      expect(repo1.getNewId(), equals(1));
      expect(repo2.getNewId(), equals(101));
    });
  });

  group('IdHandlerServiceFactory Tests', () {
    test('should create service with default configuration', () {
      final service = IdHandlerServiceFactory.createDefault();

      expect(service.getCurrent(), equals(0));
      expect(service.getNewId(), equals(0));
    });

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
  });
}
