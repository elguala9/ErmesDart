import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('IdHandlerService', () {
    test('should create service with repository', () {
      final repo = IdHandlerRepository();
      final service = IdHandlerService.fromRepo(repo: repo);

      expect(service.getCurrent(), equals(0));
    });

    test('should generate sequential IDs through service', () {
      final repo = IdHandlerRepository();
      final service = IdHandlerService.fromRepo(repo: repo);

      expect(service.getNewId(), equals(0));
      expect(service.getNewId(), equals(1));
      expect(service.getNewId(), equals(2));
    });

    test('should reset counter through service', () {
      final repo = IdHandlerRepository();
      final service = IdHandlerService.fromRepo(repo: repo);

      service.getNewId();
      service.reset();

      expect(service.getCurrent(), equals(0));
    });

    test('should set counter through service', () {
      final repo = IdHandlerRepository();
      final service = IdHandlerService.fromRepo(repo: repo);

      service.setCounter(50);
      expect(service.getNewId(), equals(50));
    });

    group('with storage', () {
      test('should persist IDs via storage on getNewId', () {
        final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
        final storageRepo = IdHandlerStorageRepository.fromDb(db);
        final storage = IdHandlerStorageService.fromRepo(storageRepo);
        final repo = IdHandlerRepository();
        final service = IdHandlerService.fromRepo(repo: repo, storage: storage);

        service.getNewId();
        service.getNewId();
        service.getNewId();

        final stored = db.retrieveSync(ItemId(
          id: 'current_id',
          collection: 'id_handler',
        ));
        expect(stored, isNotNull);
        expect(stored!.item['id'], equals(2));
      });

      test('should persist counter via storage on setCounter', () {
        final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
        final storageRepo = IdHandlerStorageRepository.fromDb(db);
        final storage = IdHandlerStorageService.fromRepo(storageRepo);
        final repo = IdHandlerRepository();
        final service = IdHandlerService.fromRepo(repo: repo, storage: storage);

        service.setCounter(42);

        final stored = db.retrieveSync(ItemId(
          id: 'current_id',
          collection: 'id_handler',
        ));
        expect(stored!.item['id'], equals(42));
      });
    });
  });
}
