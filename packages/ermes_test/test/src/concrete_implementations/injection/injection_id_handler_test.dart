// This file can run standalone (dart test) or be imported by an aggregator.
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

/// Coverage for [ErmesIdHandlerInjector].
///
/// Since singleton_manager 2.x there is one keyed registry rather than a
/// separate global container, so the former "singleton" and "registry" suites
/// collapse into this single keyed one.
void testInjectionIdHandler() {
  group('ErmesIdHandlerInjector', () {
    const key1 = 'test-id-handler-injection-1';
    const key2 = 'test-id-handler-injection-2';
    // Keep the persisted counter inside the build directory rather than the
    // package root, so running the suite leaves no stray ./id_handler folder.
    const injector = ErmesIdHandlerInjector(
      dataPath: './build/test_id_handler_injection',
    );

    setUpAll(() {
      injector.registerAllSingletonsIdHandler(key: key1);
      injector.registerAllSingletonsIdHandler(key: key2);
    });

    group('Registration', () {
      test('registers IIdHandlerStorageRepository', () {
        expect(
          RegistryManager.instance
              .getInstance<IIdHandlerStorageRepository>(key: key1),
          isA<IIdHandlerStorageRepository>(),
        );
      });

      test('registers IIdHandlerStorageService', () {
        expect(
          RegistryManager.instance
              .getInstance<IIdHandlerStorageService>(key: key1),
          isA<IIdHandlerStorageService>(),
        );
      });

      test('registers IIdHandlerRepository', () {
        expect(
          RegistryManager.instance
              .getInstance<IIdHandlerRepository>(key: key1),
          isA<IIdHandlerRepository>(),
        );
      });

      test('registers IIdHandlerService', () {
        expect(
          RegistryManager.instance.getInstance<IIdHandlerService>(key: key1),
          isA<IIdHandlerService>(),
        );
      });
    });

    group('Identity', () {
      test('same key returns the same service', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IIdHandlerService>(key: key1),
            registry.getInstance<IIdHandlerService>(key: key1),
          ),
          isTrue,
        );
      });
    });

    group('Independence between keys', () {
      test('different keys get different services', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IIdHandlerService>(key: key1),
            registry.getInstance<IIdHandlerService>(key: key2),
          ),
          isFalse,
        );
      });
    });

    group('Functional', () {
      test('generates monotonically increasing IDs', () {
        final svc =
            RegistryManager.instance.getInstance<IIdHandlerService>(key: key1);
        expect(svc.getNewId(), lessThan(svc.getNewId()));
      });

      test('getCurrent is never less than the last generated ID', () {
        final svc =
            RegistryManager.instance.getInstance<IIdHandlerService>(key: key1);
        final id = svc.getNewId();
        expect(svc.getCurrent(), greaterThanOrEqualTo(id));
      });

      test('each key keeps its own counter', () {
        final registry = RegistryManager.instance;
        final a = registry.getInstance<IIdHandlerService>(key: key1);
        final b = registry.getInstance<IIdHandlerService>(key: key2);
        a
          ..setCounter(100)
          ..getNewId();
        b.setCounter(5);
        expect(b.getCurrent(), equals(5));
        expect(a.getCurrent(), greaterThan(100));
      });
    });
  });
}

void main() {
  testInjectionIdHandler();
}
