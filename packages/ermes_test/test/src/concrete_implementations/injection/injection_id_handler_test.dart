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
      injector
        ..registerAllSingletonsIdHandler(key: key1)
        ..registerAllSingletonsIdHandler(key: key2);
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

    group('Error Handling and DI Edge Cases', () {
      test('getInstance for a completely unregistered key throws', () {
        expect(
          () => RegistryManager.instance
              .getInstance<IIdHandlerService>(key: 'never-registered-key'),
          throwsA(isA<RegistryNotFoundError>()),
        );
      });

      test(
          'an injector configured with max < 1 registers without throwing, '
          'but resolving the repository throws ArgumentError', () {
        const badInjector = ErmesIdHandlerInjector(
          dataPath: './build/test_id_handler_injection',
          max: 0,
        );
        const badKey = 'test-id-handler-injection-bad-max';

        expect(
          () => badInjector.registerAllSingletonsIdHandler(key: badKey),
          returnsNormally,
        );
        expect(
          () => RegistryManager.instance
              .getInstance<IIdHandlerRepository>(key: badKey),
          throwsArgumentError,
        );
      });

      test(
          'an injector configured with start > max resolves lazily and '
          'throws ArgumentError only when the repository is first requested',
          () {
        const badInjector = ErmesIdHandlerInjector(
          dataPath: './build/test_id_handler_injection',
          max: 10,
          start: 20,
        );
        const badKey = 'test-id-handler-injection-bad-start';

        badInjector.registerAllSingletonsIdHandler(key: badKey);
        expect(
          () => RegistryManager.instance
              .getInstance<IIdHandlerRepository>(key: badKey),
          throwsArgumentError,
        );
      });

      test('an injector configured with only `start` keeps the default max',
          () {
        const onlyStartInjector = ErmesIdHandlerInjector(
          dataPath: './build/test_id_handler_injection',
          start: 42,
        );
        const onlyStartKey = 'test-id-handler-injection-only-start';

        onlyStartInjector.registerAllSingletonsIdHandler(key: onlyStartKey);
        final svc = RegistryManager.instance
            .getInstance<IIdHandlerService>(key: onlyStartKey);

        expect(svc.getCurrent(), equals(42));
      });

      test('an injector configured with only `max` keeps the default start '
          'of zero', () {
        const onlyMaxInjector = ErmesIdHandlerInjector(
          dataPath: './build/test_id_handler_injection',
          max: 5,
        );
        const onlyMaxKey = 'test-id-handler-injection-only-max';

        onlyMaxInjector.registerAllSingletonsIdHandler(key: onlyMaxKey);
        final svc = RegistryManager.instance
            .getInstance<IIdHandlerService>(key: onlyMaxKey);

        expect(svc.getCurrent(), equals(0));
        // getNewId() wraps past max=5 back to 0, proving the injected
        // repository really received the custom max, not the default.
        for (var i = 0; i <= 5; i++) {
          expect(svc.getNewId(), equals(i));
        }
        expect(svc.getNewId(), equals(0));
      });

      test('setCounter rejects a negative value through the injected service',
          () {
        final svc =
            RegistryManager.instance.getInstance<IIdHandlerService>(key: key1);
        expect(() => svc.setCounter(-1), throwsArgumentError);
      });

      test(
          'registering the same key twice does not replace an already '
          'resolved instance', () {
        const repeatedKey = 'test-id-handler-injection-repeated';
        injector.registerAllSingletonsIdHandler(key: repeatedKey);
        final first = RegistryManager.instance
            .getInstance<IIdHandlerService>(key: repeatedKey);

        // Re-registering under the same key only replaces the connected
        // factory; the already-resolved singleton instance is untouched.
        injector.registerAllSingletonsIdHandler(key: repeatedKey);
        final second = RegistryManager.instance
            .getInstance<IIdHandlerService>(key: repeatedKey);

        expect(identical(first, second), isTrue);
      });

      test(
          'concurrent getNewId() calls across async gaps never hand out a '
          'duplicate ID', () async {
        const concurrentKey = 'test-id-handler-injection-concurrent';
        injector.registerAllSingletonsIdHandler(key: concurrentKey);
        final svc = RegistryManager.instance
            .getInstance<IIdHandlerService>(key: concurrentKey);

        final ids = await Future.wait(
          List.generate(20, (_) => Future(svc.getNewId)),
        );

        expect(ids.toSet().length, equals(ids.length));
      });
    });
  });
}

void main() {
  testInjectionIdHandler();
}
