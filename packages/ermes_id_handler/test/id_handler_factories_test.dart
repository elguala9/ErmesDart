import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('IdHandlerFactory', () {
    test('createRepository should create repository from input', () {
      final input = IdHandlerRepositoryInput(max: 50, start: 10);
      final repo = IdHandlerFactory.createRepository(input);

      expect(repo.getCurrent(), equals(10));
      expect(repo.getNewId(), equals(10));
    });

    test('createRepository should use defaults when input fields are null', () {
      final input = IdHandlerRepositoryInput();
      final repo = IdHandlerFactory.createRepository(input);

      expect(repo, isA<IIdHandlerRepository>());
      expect(repo.getCurrent(), equals(0));
    });

    test('createService should create service with provided repository', () {
      final repo = IdHandlerRepository(start: 100);
      final input = IdHandlerServiceInput(repo: repo);
      final service = IdHandlerFactory.createService(input);

      expect(service.getCurrent(), equals(100));
    });

    test('createService should create repository from inputForRepo', () {
      final repo = IdHandlerRepository();
      final serviceInput = IdHandlerServiceInput(repo: repo);
      final repoInput = IdHandlerRepositoryInput(start: 5, max: 50);
      final service = IdHandlerFactory.createService(serviceInput, repoInput);

      expect(service.getCurrent(), equals(5));
    });

    test('createService should use provided storage', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      final storageRepo = IdHandlerStorageRepository.fromDb(db);
      final storage = IdHandlerStorageService.fromRepo(storageRepo);
      final repo = IdHandlerRepository();
      final input = IdHandlerServiceInput(repo: repo, storage: storage);
      final service = IdHandlerFactory.createService(input);

      service.getNewId();

      final stored = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(stored!.item['id'], equals(0));
    });
  });

  group('IdHandlerServiceFactory', () {
    test('createDefault should create service with default config', () {
      final service = IdHandlerServiceFactory.createDefault();

      expect(service, isA<IIdHandlerService>());
      expect(service.getCurrent(), equals(0));
      expect(service.getNewId(), equals(0));
    });

    test('create should create service with custom repository input', () {
      final input = IdHandlerRepositoryInput(start: 100, max: 200);
      final service = IdHandlerServiceFactory.create(repositoryInput: input);

      expect(service.getCurrent(), equals(100));
    });

    test('create should create service with no repository input', () {
      final service = IdHandlerServiceFactory.create();

      expect(service.getCurrent(), equals(0));
    });

    test('createWithRange should create service with specific range', () {
      final service = IdHandlerServiceFactory.createWithRange(
        start: 50,
        max: 100,
      );

      expect(service.getCurrent(), equals(50));
      expect(service.getNewId(), equals(50));
    });

    test('createWithStorage should create service with custom storage', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      final storageRepo = IdHandlerStorageRepository.fromDb(db);
      final storage = IdHandlerStorageService.fromRepo(storageRepo);
      final service = IdHandlerServiceFactory.createWithStorage(storage);

      service.getNewId();

      final stored = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(stored!.item['id'], equals(0));
    });
  });

  group('IdHandlerStorageFactory', () {
    test('createDefault should create storage with in-memory db', () {
      final storage = IdHandlerStorageFactory.createDefault();

      expect(storage, isA<IIdHandlerStorageService>());
      storage.update(42);
    });

    test('createWithDb should create storage with custom db', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      final storage = IdHandlerStorageFactory.createWithDb(db);

      storage.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(42));
    });

    test('createWithDb should support custom collection', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      final storage = IdHandlerStorageFactory.createWithDb(db, 'custom_collection');

      storage.update(99);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'custom_collection',
      ));
      expect(result!.item['id'], equals(99));
    });
  });
}
