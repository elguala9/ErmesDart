import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

const _collection = 'id_handler';
const _idKey = 'current_id';

void testIdHandlerStorageRepository() {
  group('IdHandlerStorageRepository', () {
    late IWorkDbSync db;
    late IdHandlerStorageRepository repository;

    setUp(() {
      db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      repository = IdHandlerStorageRepository.fromDb(db);
    });

    group('update()', () {
      test('persists the given id under the default collection', () {
        repository.update(7);

        final stored = db.retrieveSync(
          ItemId(id: _idKey, collection: _collection),
        );
        expect(stored, isNotNull);
        expect(stored!.item['id'], equals(7));
      });

      test('overwrites the previously persisted id', () {
        repository
          ..update(1)
          ..update(2);

        final stored = db.retrieveSync(
          ItemId(id: _idKey, collection: _collection),
        );
        expect(stored!.item['id'], equals(2));
      });

      test('uses a custom collection when provided', () {
        final customRepo = IdHandlerStorageRepository.fromDb(db, 'custom');
        customRepo.update(5);

        final stored = db.retrieveSync(
          ItemId(id: _idKey, collection: 'custom'),
        );
        expect(stored, isNotNull);

        final defaultStored = db.retrieveSync(
          ItemId(id: _idKey, collection: _collection),
        );
        expect(defaultStored, isNull);
      });

      test('accepts id 0', () {
        repository.update(0);
        final stored = db.retrieveSync(
          ItemId(id: _idKey, collection: _collection),
        );
        expect(stored!.item['id'], equals(0));
      });
    });

    group('save()', () {
      test('does not throw (work_db persists synchronously on write)', () {
        expect(repository.save, returnsNormally);
      });
    });

    group('close()', () {
      test('does not throw', () {
        expect(repository.close, returnsNormally);
      });

      test('is idempotent', () {
        repository
          ..close()
          ..close();
      });
    });

    group('destroy()', () {
      test('deletes the persisted collection', () {
        repository.update(3);
        repository.destroy();

        final stored = db.retrieveSync(
          ItemId(id: _idKey, collection: _collection),
        );
        expect(stored, isNull);
      });

      test('does not throw when nothing was ever persisted', () {
        expect(repository.destroy, returnsNormally);
      });

      test('is idempotent', () {
        repository.update(1);
        repository
          ..destroy()
          ..destroy();
      });

      test('allows further updates after destroy', () {
        repository
          ..update(1)
          ..destroy()
          ..update(9);

        final stored = db.retrieveSync(
          ItemId(id: _idKey, collection: _collection),
        );
        expect(stored!.item['id'], equals(9));
      });
    });

    group('dependencyInjectionFactory', () {
      test('is exposed as a factory constructor', () {
        expect(
          IdHandlerStorageRepository.dependencyInjectionFactory,
          isA<Function>(),
        );
      });
    });
  });
}

void main() {
  testIdHandlerStorageRepository();
}
