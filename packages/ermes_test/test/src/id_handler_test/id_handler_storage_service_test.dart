import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

class _RecordingStorageRepository implements IIdHandlerStorageRepository {
  final List<IdType> updates = [];
  bool saveCalled = false;
  bool closeCalled = false;
  bool destroyCalled = false;

  @override
  void update(IdType id) => updates.add(id);

  @override
  void save() => saveCalled = true;

  @override
  void close() => closeCalled = true;

  @override
  void destroy() => destroyCalled = true;
}

void testIdHandlerStorageService() {
  group('IdHandlerStorageService', () {
    group('fromRepo() / update()', () {
      test('delegates update to the underlying repository', () {
        final repo = _RecordingStorageRepository();
        IdHandlerStorageService.fromRepo(repo).update(11);

        expect(repo.updates, equals([11]));
      });
    });

    group('save()', () {
      test('delegates to the underlying repository', () {
        final repo = _RecordingStorageRepository();
        IdHandlerStorageService.fromRepo(repo).save();

        expect(repo.saveCalled, isTrue);
      });
    });

    group('close()', () {
      test('delegates to the underlying repository', () {
        final repo = _RecordingStorageRepository();
        IdHandlerStorageService.fromRepo(repo).close();

        expect(repo.closeCalled, isTrue);
      });
    });

    group('destroy()', () {
      test('delegates to the underlying repository', () {
        final repo = _RecordingStorageRepository();
        IdHandlerStorageService.fromRepo(repo).destroy();

        expect(repo.destroyCalled, isTrue);
      });
    });

    group('inMemory()', () {
      test('creates a working service backed by an in-memory work_db', () {
        final service = IdHandlerStorageService.inMemory();
        expect(() => service.update(1), returnsNormally);
      });

      test('creates independent instances on each call', () {
        final serviceA = IdHandlerStorageService.inMemory();
        final serviceB = IdHandlerStorageService.inMemory();

        // Persisting through A must not be observable via B's own storage.
        serviceA.update(42);
        expect(() => serviceB.update(1), returnsNormally);
      });
    });

    group('integration with a real work_db-backed repository', () {
      test('persists through to the underlying database', () {
        final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
        final repo = IdHandlerStorageRepository.fromDb(db);
        IdHandlerStorageService.fromRepo(repo).update(99);

        final stored = db.retrieveSync(
          ItemId(id: 'current_id', collection: 'id_handler'),
        );
        expect(stored!.item['id'], equals(99));
      });

      test('destroy() removes the persisted state', () {
        final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
        final repo = IdHandlerStorageRepository.fromDb(db);
        IdHandlerStorageService.fromRepo(repo)
          ..update(5)
          ..destroy();

        final stored = db.retrieveSync(
          ItemId(id: 'current_id', collection: 'id_handler'),
        );
        expect(stored, isNull);
      });
    });
  });
}

void main() {
  testIdHandlerStorageService();
}
