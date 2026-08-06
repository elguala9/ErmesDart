import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

/// Offline coverage for [ErmesInjector].
///
/// No Nostr key pair is supplied, so nothing here touches the network: the
/// whole graph is connected lazily and only the entries that do not need a
/// signaling transport are resolved.
void main() {
  // Each test registers under its own key so the graphs stay independent and
  // no test can see another's instances.
  var testCounter = 0;
  late String key;

  setUp(() {
    testCounter++;
    key = 'ermes_injector_test_$testCounter';
  });

  group('ErmesInjector.register', () {
    test('registers the message storage handlers', () async {
      await const ErmesInjector().register(key: key);

      final registry = RegistryManager.instance;
      expect(
        registry.getInstance<
            ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(key: key),
        isNotNull,
      );
      expect(
        registry.getInstance<
            ErmesStorageAndCachingMessagesHandlerBaseMessageType>(key: key),
        isNotNull,
      );
    });

    test('generates a key pair and turns encryption on', () async {
      await const ErmesInjector().register(key: key);

      final registry = RegistryManager.instance;
      expect(registry.getInstance<IKeyExchange>(key: key), isA<IKeyExchange>());
      expect(registry.getInstance<bool>(key: key), isTrue);
    });

    test('reuses a key pair already registered under the key', () async {
      final existing = await ECDHKeyExchangeService.generateNewService();
      RegistryManager.instance.setInstance<IKeyExchange>(existing, key: key);

      await const ErmesInjector().register(key: key);

      expect(
        RegistryManager.instance.getInstance<IKeyExchange>(key: key),
        same(existing),
      );
    });

    test('reuses a supplied key pair', () async {
      final supplied = await ECDHKeyExchangeService.generateNewService();

      await ErmesInjector(keyExchange: supplied).register(key: key);

      expect(
        RegistryManager.instance.getInstance<IKeyExchange>(key: key),
        same(supplied),
      );
    });

    test('connects the cipher stack', () async {
      await const ErmesInjector().register(key: key);

      final registry = RegistryManager.instance;
      expect(
        registry.getInstance<IErmesPeerCipher>(key: key),
        isA<IErmesPeerCipher>(),
      );
      expect(
        registry.getInstance<IErmesPeerKeyExchange>(key: key),
        isA<IErmesPeerKeyExchange>(),
      );
    });

    test('connects the book stack, which needs no signaling transport',
        () async {
      await const ErmesInjector().register(key: key);

      final registry = RegistryManager.instance;
      final service =
          registry.getInstance<IErmesBookService<BookData>>(key: key);
      expect(service, isA<IErmesBookService<BookData>>());

      // The book service must delegate to the registered repository.
      service.setAccount(AccountInfo<BookData>(
        account: 'peer1',
        info: BookData(peerId: 'peer1', name: 'Alice', timestamp: 1000),
      ));
      final repo =
          registry.getInstance<IErmesBookRepository<BookData>>(key: key);
      expect(repo.getAccount('peer1').info?.name, equals('Alice'));
    });

    test('leaves the ID handler and message control graphs unregistered',
        () async {
      await const ErmesInjector().register(key: key);

      final registry = RegistryManager.instance;
      expect(
        registry.getInstanceNullable<IIdHandlerService>(key: key),
        isNull,
      );
      expect(
        registry.getInstanceNullable<IErmesMessageControlService>(key: key),
        isNull,
      );
    });

    test('registers the ID handler graph when asked', () async {
      await const ErmesInjector(registerIdHandler: true).register(key: key);

      expect(
        RegistryManager.instance.getInstance<IIdHandlerService>(key: key),
        isA<IIdHandlerService>(),
      );
    });

    test('registers the message control graph when asked', () async {
      await const ErmesInjector(registerMessageControl: true)
          .register(key: key);

      expect(
        RegistryManager.instance
            .getInstance<IErmesMessageControlService>(key: key),
        isA<IErmesMessageControlService>(),
      );
    });

    test('needs a signaling transport before the orchestrator resolves',
        () async {
      await const ErmesInjector().register(key: key);

      // No key pair was given, so INostrSignaling was never registered and the
      // orchestrator cannot be built. tryGetInstance is what swallows the
      // RegistryNotFoundError thrown deeper in the factory chain.
      expect(
        () => getIOrcErmes(key: key),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('keeps graphs registered under different keys independent', () async {
      const injector = ErmesInjector();
      await injector.register(key: '$key-a');
      await injector.register(key: '$key-b');

      final registry = RegistryManager.instance;
      final a = registry.getInstance<IKeyExchange>(key: '$key-a');
      final b = registry.getInstance<IKeyExchange>(key: '$key-b');
      expect(a, isNot(same(b)));

      final bookA =
          registry.getInstance<IErmesBookService<BookData>>(key: '$key-a');
      final bookB =
          registry.getInstance<IErmesBookService<BookData>>(key: '$key-b');
      expect(bookA, isNot(same(bookB)));
    });
  });

  group('registerErmesStorageHandlers', () {
    test('does not clobber an already registered handler', () {
      final existing = ErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
      RegistryManager.instance
          .setInstance<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(
        existing,
        key: key,
      );

      registerErmesStorageHandlers(key: key);

      expect(
        RegistryManager.instance.getInstance<
            ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(key: key),
        same(existing),
      );
    });
  });
}
