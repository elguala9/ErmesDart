import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  setUp(() {
    SingletonManager.instance.clearRegistry();
  });

  group('IdHandlerStorageRepositoryDI', () {
    test('initializeWithParametersDI should create with given db', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      final repo = IdHandlerStorageRepositoryDI.initializeWithParametersDI(db);

      expect(repo, isA<IIdHandlerStorageRepository>());
      repo.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(42));
    });

    test('initializeDI should resolve db from SingletonDIAccess', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      SingletonDIAccess.addInstance<IWorkDbSync>(db);

      final repo = IdHandlerStorageRepositoryDI.initializeDI();

      expect(repo, isA<IIdHandlerStorageRepository>());
      repo.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(42));
    });
  });

  group('IdHandlerStorageServiceDI', () {
    test('initializeDI should resolve repo from SingletonDIAccess', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      final repo = IdHandlerStorageRepository.fromDb(db);
      SingletonDIAccess.addInstance<IIdHandlerStorageRepository>(repo);

      final service = IdHandlerStorageServiceDI.initializeDI();

      expect(service, isA<IIdHandlerStorageService>());
      service.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(42));
    });
  });

  group('IdHandlerServiceDI', () {
    test('initializeDI should resolve repo and storage from SingletonDIAccess',
        () {
      final repo = IdHandlerRepository(start: 10);
      SingletonDIAccess.addInstance<IIdHandlerRepository>(repo);

      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      final storageRepo = IdHandlerStorageRepository.fromDb(db);
      final storage = IdHandlerStorageService.fromRepo(storageRepo);
      SingletonDIAccess.addInstance<IIdHandlerStorageService>(storage);

      final service = IdHandlerServiceDI.initializeDI();

      expect(service, isA<IIdHandlerService>());
      expect(service.getCurrent(), equals(10));
      expect(service.getNewId(), equals(10));

      final stored = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(stored!.item['id'], equals(10));
    });
  });
}
