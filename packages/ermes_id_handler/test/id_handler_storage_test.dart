import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('IdHandlerStorageRepository', () {
    late IWorkDbSync db;
    late IdHandlerStorageRepository repo;

    setUp(() {
      db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      repo = IdHandlerStorageRepository.fromDb(db);
    });

    test('should persist ID via update', () {
      repo.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result, isNotNull);
      expect(result!.item['id'], equals(42));
    });

    test('should overwrite ID on subsequent update', () {
      repo
        ..update(42)
        ..update(99);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(99));
    });

    test('save should not throw', () {
      repo.update(42);
      expect(repo.save, returnsNormally);
    });

    test('close should not throw', () {
      expect(repo.close, returnsNormally);
    });

    test('destroy should remove collection', () {
      repo
        ..update(42)
        ..destroy();

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result, isNull);
    });

    test('should support custom collection name', () {
      IdHandlerStorageRepository.fromDb(db, 'custom_ids').update(7);

      final defaultResult = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(defaultResult, isNull);

      final customResult = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'custom_ids',
      ));
      expect(customResult!.item['id'], equals(7));
    });
  });

  group('IdHandlerStorageService', () {
    late IWorkDbSync db;
    late IdHandlerStorageRepository storageRepo;
    late IdHandlerStorageService service;

    setUp(() {
      db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      storageRepo = IdHandlerStorageRepository.fromDb(db);
      service = IdHandlerStorageService.fromRepo(storageRepo);
    });

    test('should delegate update to repository', () {
      service.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(42));
    });

    test('should delegate save to repository', () {
      expect(service.save, returnsNormally);
    });

    test('should delegate close to repository', () {
      expect(service.close, returnsNormally);
    });

    test('should delegate destroy to repository', () {
      service
        ..update(42)
        ..destroy();

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result, isNull);
    });

    test('should create with default in-memory repo', () {
      final svc = IdHandlerStorageService.inMemory();
      expect(svc, isNotNull);
      svc.update(1);
    });
  });
}
