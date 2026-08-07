import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  // Each test registers under its own key so the graphs stay independent and
  // no test can see another's instances.
  var testCounter = 0;
  late String key;

  setUp(() {
    testCounter++;
    key = 'id_handler_di_test_$testCounter';
  });

  group('IdHandlerStorageRepository.dependencyInjectionFactory', () {
    test('resolves the work_db instance from the registry', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      RegistryManager.instance.setInstance<IWorkDbSync>(db, key: key);

      final repo =
          IdHandlerStorageRepository.dependencyInjectionFactory(key: key);

      expect(repo, isA<IIdHandlerStorageRepository>());
      repo.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(42));
    });

    test('throws when no work_db instance is registered', () {
      expect(
        () => IdHandlerStorageRepository.dependencyInjectionFactory(key: key),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });
  });

  group('IdHandlerStorageService.dependencyInjectionFactory', () {
    test('resolves its repository from the registry', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      RegistryManager.instance.setInstance<IIdHandlerStorageRepository>(
        IdHandlerStorageRepository(db),
        key: key,
      );

      final service =
          IdHandlerStorageService.dependencyInjectionFactory(key: key);

      expect(service, isA<IIdHandlerStorageService>());
      service.update(42);

      final result = db.retrieveSync(ItemId(
        id: 'current_id',
        collection: 'id_handler',
      ));
      expect(result!.item['id'], equals(42));
    });
  });

  group('IdHandlerService.dependencyInjectionFactory', () {
    test('resolves repo and storage from the registry', () {
      final db = WorkDbFactory().create(const MemoryWorkDbFactoryInput());
      RegistryManager.instance
        ..setInstance<IIdHandlerRepository>(
          IdHandlerRepository(start: 10),
          key: key,
        )
        ..setInstance<IIdHandlerStorageService>(
          IdHandlerStorageService(IdHandlerStorageRepository(db)),
          key: key,
        );

      final service = IdHandlerService.dependencyInjectionFactory(key: key);

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

  group('ErmesIdHandlerInjector', () {
    test('connects the whole graph lazily under its key', () {
      const ErmesIdHandlerInjector(dataPath: './build/test_id_handler')
          .registerAllSingletonsIdHandler(key: key);

      final service =
          RegistryManager.instance.getInstance<IIdHandlerService>(key: key);
      expect(service, isA<IIdHandlerService>());

      // Same key resolves the same instance.
      expect(
        RegistryManager.instance.getInstance<IIdHandlerService>(key: key),
        same(service),
      );
    });

    test('honours the configured start value', () {
      const ErmesIdHandlerInjector(
        dataPath: './build/test_id_handler',
        start: 7,
      ).registerAllSingletonsIdHandler(key: key);

      final repo =
          RegistryManager.instance.getInstance<IIdHandlerRepository>(key: key);
      expect(repo.getCurrent(), equals(7));
    });

    test('keeps graphs registered under different keys independent', () {
      const ErmesIdHandlerInjector(dataPath: './build/test_id_handler')
        ..registerAllSingletonsIdHandler(key: '$key-a')
        ..registerAllSingletonsIdHandler(key: '$key-b');

      final registry = RegistryManager.instance;
      final a = registry.getInstance<IIdHandlerService>(key: '$key-a');
      final b = registry.getInstance<IIdHandlerService>(key: '$key-b');
      expect(a, isNot(same(b)));
    });
  });
}
