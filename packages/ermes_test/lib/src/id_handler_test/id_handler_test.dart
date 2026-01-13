// ignore_for_file: cascade_invocations

import 'package:ermes_implementation/ermes_implementation.dart';
import 'package:ermes_storage/ermes_storage.dart' as es;
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

  group('IdHandlerService with Caching Storage Tests', () {
    late IdHandlerService service;
    late es.IErmesCachingRepository<Map<String, dynamic>> storageRepo;

    setUp(() {
      storageRepo = es.createErmesCachingRepository<Map<String, dynamic>>(100);

      final repository = IdHandlerRepository();
      service = IdHandlerService(repo: repository);
    });

    tearDown(() async {
      await storageRepo.destroy();
    });

    test('should generate IDs and store them in cache', () async {
      final id1 = service.getNewId();
      final id2 = service.getNewId();
      final id3 = service.getNewId();

      final data1 = {'id': '$id1', 'idValue': id1, 'type': 'generated'};
      final data2 = {'id': '$id2', 'idValue': id2, 'type': 'generated'};
      final data3 = {'id': '$id3', 'idValue': id3, 'type': 'generated'};

      await storageRepo.store(data1);
      await storageRepo.store(data2);
      await storageRepo.store(data3);

      final retrieved1 = await storageRepo.retrieve(id1);
      final retrieved2 = await storageRepo.retrieve(id2);
      final retrieved3 = await storageRepo.retrieve(id3);

      expect(retrieved1?['idValue'], equals(id1));
      expect(retrieved2?['idValue'], equals(id2));
      expect(retrieved3?['idValue'], equals(id3));
    });

    test('should handle rapid ID generation with caching', () async {
      const count = 100;
      final ids = <int>[];

      for (var i = 0; i < count; i++) {
        final id = service.getNewId();
        ids.add(id);

        final data = {'id': '$id', 'sequence': i, 'idValue': id};
        await storageRepo.store(data);
      }

      expect(storageRepo.numberOfElements(), equals(count));
      expect(ids.length, equals(count));

      // Verify all IDs are unique and sequential
      for (var i = 0; i < count; i++) {
        expect(ids[i], equals(i));
      }
    });

    test('should retrieve cached IDs correctly', () async {
      final generatedIds = <int>[];

      for (var i = 0; i < 20; i++) {
        final id = service.getNewId();
        generatedIds.add(id);

        await storageRepo.store({'id': '$id', 'value': 'data-$id'});
      }

      for (final id in generatedIds) {
        final retrieved = await storageRepo.retrieve(id);
        expect(retrieved, isNotNull);
        expect(retrieved?['id'], equals('$id'));
      }
    });
  });

  group('IdHandlerService with Factory and Caching Tests', () {
    late es.IErmesCachingRepository<Map<String, dynamic>> storageRepo;

    setUp(() {
      storageRepo = es.createErmesCachingRepository<Map<String, dynamic>>();
    });

    tearDown(() async {
      await storageRepo.destroy();
    });

    test('should use factory to create service and generate IDs', () async {
      final service = IdHandlerServiceFactory.createWithRange(
        start: 0,
        max: 500,
      );

      final ids = <int>[];
      for (var i = 0; i < 50; i++) {
        final id = service.getNewId();
        ids.add(id);

        await storageRepo.store({
          'id': '$id',
          'factoryGenerated': true,
          'index': i,
        });
      }

      expect(ids.length, equals(50));
      expect(storageRepo.numberOfElements(), equals(50));
    });

    test('should create multiple factory services independently', () async {
      final service1 = IdHandlerServiceFactory.createDefault();
      final service2 = IdHandlerServiceFactory.createWithRange(
        start: 100,
        max: 200,
      );
      final service3 = IdHandlerServiceFactory.create(
        repositoryInput: const IdHandlerRepositoryInput(start: 1000),
      );

      for (var i = 0; i < 10; i++) {
        final id1 = service1.getNewId();
        final id2 = service2.getNewId();
        final id3 = service3.getNewId();

        await storageRepo.store({'id': '1-$i', 'value': id1});
        await storageRepo.store({'id': '2-$i', 'value': id2});
        await storageRepo.store({'id': '3-$i', 'value': id3});
      }

      expect(storageRepo.numberOfElements(), equals(30));
      expect(service1.getCurrent(), equals(10));
      expect(service2.getCurrent(), equals(110));
      expect(service3.getCurrent(), equals(1010));
    });

    test('should handle service reset with cached data', () async {
      final service = IdHandlerServiceFactory.createDefault();

      for (var i = 0; i < 5; i++) {
        final id = service.getNewId();
        await storageRepo.store({'id': '$id', 'before_reset': true});
      }

      expect(service.getCurrent(), equals(5));
      expect(storageRepo.numberOfElements(), equals(5));

      service.reset();

      expect(service.getCurrent(), equals(0));

      for (var i = 0; i < 5; i++) {
        final id = service.getNewId();
        await storageRepo.store({'id': 'after-$id', 'after_reset': true});
      }

      expect(service.getCurrent(), equals(5));
      expect(storageRepo.numberOfElements(), equals(10));
    });

    test('should set counter and continue generation with caching', () async {
      final service = IdHandlerServiceFactory.createDefault();

      service.setCounter(100);

      for (var i = 0; i < 10; i++) {
        final id = service.getNewId();
        await storageRepo.store({'id': '$id', 'after_set_counter': true});
      }

      expect(service.getCurrent(), equals(110));
      expect(storageRepo.numberOfElements(), equals(10));

      final ids = await storageRepo.listOfIds();
      expect(ids.length, equals(10));
    });

    test('should generate large batches with factory services', () async {
      final service = IdHandlerServiceFactory.createWithRange(
        start: 0,
        max: 10000,
      );

      const batchSize = 500;
      for (var i = 0; i < batchSize; i++) {
        final id = service.getNewId();
        if (i % 50 == 0) {
          // Store every 50th ID
          await storageRepo.store({
            'id': '$id',
            'batch': 'large',
            'sampled': true,
          });
        }
      }

      expect(service.getCurrent(), equals(batchSize));
      expect(storageRepo.numberOfElements(), equals(batchSize ~/ 50));
    });
  });

  group('IdHandlerFactory Comprehensive Tests', () {
    late es.IErmesCachingRepository<Map<String, dynamic>> storageRepo;

    setUp(() {
      storageRepo = es.createErmesCachingRepository<Map<String, dynamic>>();
    });

    tearDown(() async {
      await storageRepo.destroy();
    });

    test(
      'should use IdHandlerFactory to create and manage repositories',
      () async {
        const repoInput1 = IdHandlerRepositoryInput(start: 0, max: 100);
        const repoInput2 = IdHandlerRepositoryInput(start: 50, max: 200);

        final repo1 = IdHandlerFactory.createRepository(repoInput1);
        final repo2 = IdHandlerFactory.createRepository(repoInput2);

        for (var i = 0; i < 10; i++) {
          final id1 = repo1.getNewId();
          final id2 = repo2.getNewId();

          await storageRepo.store({'id': '1-$i', 'idValue': id1, 'repo': 1});
          await storageRepo.store({'id': '2-$i', 'idValue': id2, 'repo': 2});
        }

        expect(storageRepo.numberOfElements(), equals(20));
        expect(repo1.getCurrent(), equals(10));
        expect(repo2.getCurrent(), equals(60));
      },
    );

    test('should create services with factory and store data', () async {
      const repoInput = IdHandlerRepositoryInput(start: 0);
      final repo = IdHandlerFactory.createRepository(repoInput);
      final serviceInput = IdHandlerServiceInput(repo: repo);

      final service = IdHandlerFactory.createService(serviceInput);

      for (var i = 0; i < 20; i++) {
        final id = service.getNewId();
        await storageRepo.store({
          'id': '$id',
          'factory_service': true,
          'iteration': i,
        });
      }

      expect(storageRepo.numberOfElements(), equals(20));
      expect(service.getCurrent(), equals(20));
    });
  });

  group('Stress Tests - IdHandler with Caching', () {
    late es.IErmesCachingRepository<Map<String, dynamic>> storageRepo;

    setUp(() {
      storageRepo = es.createErmesCachingRepository<Map<String, dynamic>>(5000);
    });

    tearDown(() async {
      await storageRepo.destroy();
    });

    test('should handle 1000 concurrent-like ID generations', () async {
      final service = IdHandlerServiceFactory.createDefault();

      for (var i = 0; i < 1000; i++) {
        final id = service.getNewId();
        if (i % 100 == 0) {
          await storageRepo.store({'id': '$id', 'batch': i ~/ 100});
        }
      }

      expect(service.getCurrent(), equals(1000));
      expect(
        storageRepo.numberOfElements(),
        equals(11),
      ); // 0, 100, 200, ..., 1000
    });

    test('should handle wrapping and caching together', () async {
      final service = IdHandlerServiceFactory.createWithRange(
        start: 9999990,
        max: 10000010,
      );

      for (var i = 0; i < 30; i++) {
        final id = service.getNewId();
        await storageRepo.store({'id': '$i', 'generatedId': id, 'index': i});
      }

      expect(storageRepo.numberOfElements(), equals(30));
      // Should have wrapped around
    });

    test('should maintain data consistency across 500 IDs', () async {
      final service = IdHandlerServiceFactory.createDefault();
      final generatedIds = <int>[];

      for (var i = 0; i < 500; i++) {
        final id = service.getNewId();
        generatedIds.add(id);

        await storageRepo.store({'id': '$id', 'sequence': i});
      }

      // Verify all are sequential
      for (var i = 0; i < 500; i++) {
        expect(generatedIds[i], equals(i));
      }

      // Verify all stored
      expect(storageRepo.numberOfElements(), equals(500));

      // Verify retrievable
      for (var i = 0; i < 500; i++) {
        final retrieved = await storageRepo.retrieve(i);
        expect(retrieved?['sequence'], equals(i));
      }
    });
  });
}
