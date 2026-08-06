// This file can run standalone (dart test) or be imported by an aggregator.
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

/// Coverage for [ErmesMessageControlInjector].
///
/// Since singleton_manager 2.x there is one keyed registry rather than a
/// separate global container, so the former "singleton" and "registry" suites
/// collapse into this single keyed one.
void testInjectionMessageControl() {
  group('ErmesMessageControlInjector', () {
    const key1 = 'test-message-control-injection-1';
    const key2 = 'test-message-control-injection-2';

    setUpAll(() {
      const injector = ErmesMessageControlInjector();
      injector.registerAllSingletonsMessageControl(key: key1);
      injector.registerAllSingletonsMessageControl(key: key2);
    });

    group('Registration', () {
      test('registers IErmesMessageControlRepository', () {
        expect(
          RegistryManager.instance
              .getInstance<IErmesMessageControlRepository>(key: key1),
          isA<IErmesMessageControlRepository>(),
        );
      });

      test('registers IErmesMessageControlService', () {
        expect(
          RegistryManager.instance
              .getInstance<IErmesMessageControlService>(key: key1),
          isA<IErmesMessageControlService>(),
        );
      });

      test('repository and service are distinct objects', () {
        final registry = RegistryManager.instance;
        final repo =
            registry.getInstance<IErmesMessageControlRepository>(key: key1);
        final service =
            registry.getInstance<IErmesMessageControlService>(key: key1);
        expect(identical(repo, service), isFalse);
      });
    });

    group('Identity', () {
      test('same key returns the same service', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesMessageControlService>(key: key1),
            registry.getInstance<IErmesMessageControlService>(key: key1),
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
            registry.getInstance<IErmesMessageControlService>(key: key1),
            registry.getInstance<IErmesMessageControlService>(key: key2),
          ),
          isFalse,
        );
      });

      test('different keys get different repositories', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesMessageControlRepository>(key: key1),
            registry.getInstance<IErmesMessageControlRepository>(key: key2),
          ),
          isFalse,
        );
      });

      test('tracking state does not leak across keys', () async {
        final registry = RegistryManager.instance;
        final a = registry.getInstance<IErmesMessageControlService>(key: key1)
          ..idArrived(0)
          ..idArrived(5);
        final b = registry.getInstance<IErmesMessageControlService>(key: key2);

        expect(a.numberOfMissingIds(), greaterThan(0));
        expect(b.numberOfMissingIds(), equals(0));
        await a.clear();
      });
    });

    group('Functional', () {
      late ErmesMessageControlRepository repo;
      late ErmesMessageControlService service;

      setUp(() {
        repo = ErmesMessageControlFactory.createRepository();
        service = ErmesMessageControlService.createWithRepository(repo);
      });

      test('initial state has zero missing IDs', () {
        expect(service.numberOfMissingIds(), equals(0));
      });

      test('sequential IDs create no gaps', () {
        service
          ..idArrived(0)
          ..idArrived(1)
          ..idArrived(2);
        expect(service.numberOfMissingIds(), equals(0));
      });

      test('a gap in IDs is detected as missing', () {
        service
          ..idArrived(0)
          ..idArrived(3);
        expect(service.numberOfMissingIds(), greaterThan(0));
      });

      test('idsToRequest returns the exact missing IDs', () async {
        service
          ..idArrived(0)
          ..idArrived(3);
        expect(await service.idsToRequest(), equals([1, 2]));
      });

      test('the registered service is reachable and callable', () {
        final svc = RegistryManager.instance
            .getInstance<IErmesMessageControlService>(key: key1);
        expect(svc.numberOfMissingIds(), isA<int>());
      });
    });
  });
}

void main() {
  testInjectionMessageControl();
}
