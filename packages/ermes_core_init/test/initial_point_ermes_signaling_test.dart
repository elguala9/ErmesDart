@TestOn('vm')
library;
import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() {
  // ===========================================================================
  //  initialPointErmesSignaling (SINGLETON)
  // ===========================================================================
  group('initialPointErmesSignaling [singleton]', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test('registers all signaling components with Nostr + stun_shsp', () async {
      final keyPair = NostrKeys.generate();

      await initialPointErmesSignaling(
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      expect(
        SingletonDIAccess.exists<INostrSignaling>(),
        isTrue,
        reason: 'INostrSignaling via nostr_signaling initialPointNostrSignaling',
      );
      expect(
        SingletonDIAccess.exists<IErmesSignalingServer>(),
        isTrue,
      );
      expect(
        SingletonDIAccess.exists<IErmesBookRepository<BookData>>(),
        isTrue,
      );
      expect(
        SingletonDIAccess.exists<IErmesBookService<BookData>>(),
        isTrue,
      );
      expect(
        SingletonDIAccess.exists<IErmesSignalingHandler<IShspPeer>>(),
        isTrue,
      );
      expect(
        SingletonDIAccess.exists<IErmesSignalingRepository<ISignalErmes>>(),
        isTrue,
      );
      expect(
        SingletonDIAccess.exists<IErmesSignalingService>(),
        isTrue,
      );
    });

    test('registers accountId when provided', () async {
      final keyPair = NostrKeys.generate();
      const customAccountId = 'test-account-id';

      await initialPointErmesSignaling(
        keyPair: keyPair,
        accountId: customAccountId,
        initializeStunShsp: true,
      );

      final accountId = SingletonDIAccess.get<IdAccountType>();
      expect(accountId, equals(customAccountId));
    });

    test('works with partial variant when deps are pre-registered', () async {
      final keyPair = NostrKeys.generate();

      await initializePointStunShsp();
      await initialPointNostrSignaling(
        keyPair: keyPair,
        relayUrls: ['wss://relay.damus.io'],
      );
      SingletonDIAccess.addInstance<IdAccountType>(keyPair.publicKey);
      // Bridge IShspSocket because partial variant doesn't do it
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      SingletonDIAccess.addInstance<IShspSocket>(wrapper.ipv4Socket);

      initialPointErmesSignalingPartial();

      expect(SingletonDIAccess.exists<IErmesSignalingService>(), isTrue);
    });
  });

  // ===========================================================================
  //  initialPointErmesSignalingPartial (SINGLETON)
  // ===========================================================================
  group('initialPointErmesSignalingPartial [singleton]', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test('registers all components when all deps are pre-registered', () async {
      final keyPair = NostrKeys.generate();

      await initializePointStunShsp();
      await initialPointNostrSignaling(
        keyPair: keyPair,
        relayUrls: ['wss://relay.damus.io'],
      );
      SingletonDIAccess.addInstance<IdAccountType>(keyPair.publicKey);
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      SingletonDIAccess.addInstance<IShspSocket>(wrapper.ipv4Socket);

      initialPointErmesSignalingPartial();

      expect(SingletonDIAccess.exists<IErmesSignalingServer>(), isTrue);
      expect(SingletonDIAccess.exists<IErmesBookRepository<BookData>>(), isTrue);
      expect(SingletonDIAccess.exists<IErmesBookService<BookData>>(), isTrue);
      expect(
        SingletonDIAccess.exists<IErmesSignalingHandler<IShspPeer>>(),
        isTrue,
      );
      expect(
        SingletonDIAccess.exists<IErmesSignalingRepository<ISignalErmes>>(),
        isTrue,
      );
      expect(SingletonDIAccess.exists<IErmesSignalingService>(), isTrue);
    });
  });

  // ===========================================================================
  //  initialPointErmesSignalingRegistry (REGISTRY)
  // ===========================================================================
  group('initialPointErmesSignalingRegistry [registry]', () {
    setUp(RegistryAccess.clearRegistry);

    test('registers all signaling components with Nostr + stun_shsp', () async {
      const key = 'test-signaling-reg';
      final keyPair = NostrKeys.generate();

      await initialPointErmesSignalingRegistry(
        key: key,
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      expect(
        getIErmesSignalingServerFromRegistry(key: key),
        isA<IErmesSignalingServer>(),
      );
      expect(
        getIErmesBookRepositoryFromRegistry(key: key),
        isA<IErmesBookRepository<BookData>>(),
      );
      expect(
        getIErmesBookServiceFromRegistry(key: key),
        isA<IErmesBookService<BookData>>(),
      );
      expect(
        getIErmesSignalingHandlerFromRegistry(key: key),
        isA<IErmesSignalingHandler<IShspPeer>>(),
      );
      expect(
        getIErmesSignalingRepositoryFromRegistry(key: key),
        isA<IErmesSignalingRepository<ISignalErmes>>(),
      );
      expect(
        getIErmesSignalingServiceFromRegistry(key: key),
        isA<IErmesSignalingService>(),
      );
    });

    test('supports multiple independent registry keys', () async {
      final aliceKeys = NostrKeys.generate();
      final bobKeys = NostrKeys.generate();

      await initialPointErmesSignalingRegistry(
        key: 'alice',
        keyPair: aliceKeys,
        accountId: aliceKeys.publicKey,
        initializeStunShsp: true,
      );
      await initialPointErmesSignalingRegistry(
        key: 'bob',
        keyPair: bobKeys,
        accountId: bobKeys.publicKey,
        initializeStunShsp: true,
      );

      final aliceServer = getIErmesSignalingServerFromRegistry(key: 'alice');
      final bobServer = getIErmesSignalingServerFromRegistry(key: 'bob');
      expect(identical(aliceServer, bobServer), isFalse);

      final aliceService =
          getIErmesSignalingServiceFromRegistry(key: 'alice');
      final bobService = getIErmesSignalingServiceFromRegistry(key: 'bob');
      expect(identical(aliceService, bobService), isFalse);
    });
  });

  // ===========================================================================
  //  initialPointErmesSignalingPartialRegistry (REGISTRY)
  // ===========================================================================
  group('initialPointErmesSignalingPartialRegistry [registry]', () {
    setUp(RegistryAccess.clearRegistry);

    test('registers all components when deps are pre-registered', () async {
      const key = 'partial-reg-test';
      final keyPair = NostrKeys.generate();

      await initializePointStunShsp();
      await initialPointNostrSignaling(
        keyPair: keyPair,
        relayUrls: ['wss://relay.damus.io'],
      );
      SingletonDIAccess.addInstance<IdAccountType>(keyPair.publicKey);
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      SingletonDIAccess.addInstance<IShspSocket>(wrapper.ipv4Socket);

      initialPointErmesSignalingPartialRegistry(key: key);

      expect(
        getIErmesSignalingServerFromRegistry(key: key),
        isA<IErmesSignalingServer>(),
      );
      expect(
        getIErmesSignalingServiceFromRegistry(key: key),
        isA<IErmesSignalingService>(),
      );
    });
  });

  // ===========================================================================
  //  initialPointErmesCore (SINGLETON)
  // ===========================================================================
  group('initialPointErmesCore [singleton]', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test('registers OrcErmes using Nostr + initializeStunShsp', () async {
      final keyPair = NostrKeys.generate();

      await initialPointErmesCore(
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      final orc = SingletonDIAccess.get<IOrcErmes<BookData>>();
      expect(orc, isA<IOrcErmes<BookData>>());
      expect(orc, isNotNull);
    });

    test('also initializes cipher by default', () async {
      final keyPair = NostrKeys.generate();

      await initialPointErmesCore(
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      expect(SingletonDIAccess.exists<IKeyExchange>(), isTrue);
      expect(SingletonDIAccess.exists<IErmesPeerCipher>(), isTrue);
    });
  });

  // ===========================================================================
  //  initialPointErmesCoreRegistry (REGISTRY)
  // ===========================================================================
  group('initialPointErmesCoreRegistry [registry]', () {
    setUp(RegistryAccess.clearRegistry);

    test('is a function', () {
      expect(initialPointErmesCoreRegistry, isA<Function>());
    });
  });
}
