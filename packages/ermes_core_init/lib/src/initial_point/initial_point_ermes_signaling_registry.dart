import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  /// Wraps the given [value] so it can be stored in the registry.
  _Wrap(this.value);

  /// The wrapped instance held in the registry.
  final T value;
}

/// Registry-based variant of initialPointErmesSignaling.
///
/// If [keyPair] is provided, calls [initialPointNostrSignalingRegistry]
/// to register [INostrSignaling] in the registry before wiring
/// ermes_signaling components.
///
/// If [initializeStunShsp] is true, calls [initializePointRegistryStunShsp]
/// from stun_shsp to bind SHSP sockets and initialize STUN in the registry.
Future<void> initialPointErmesSignalingRegistry({
  String key = 'default',
  NostrKeyPair? keyPair,
  List<String>? relayUrls,
  bool useCompression = false,
  IdAccountType? accountId,
  bool initializeStunShsp = false,
  bool connectSignaling = false,
}) async {
  if (initializeStunShsp) {
    await initializePointRegistryStunShsp(key);
    // Bridge IShspSocket from DualShspSocketWrapper (in registry) to
    // SingletonDIAccess because DI classes read from singleton.
    final wrapper =
        RegistryAccess.getInstance<IDualShspSocketWrapper>(key);
    SingletonDIAccess.addInstance<IShspSocket>(wrapper.ipv4Socket);
  }
  if (keyPair != null) {
    initialPointNostrSignalingRegistry(
      registryKey: key,
      keyPair: keyPair,
      relayUrls: relayUrls ?? ['wss://relay.damus.io'],
      useCompression: useCompression,
    );
    // Bridge to SingletonDIAccess because DI classes (ErmesSignalingServerDI,
    // ErmesSignalingHandlerDI, etc.) read from SingletonDIAccess.
    SingletonDIAccess.addInstance<INostrSignaling>(
      getINostrSignalingFromRegistry(key: key),
    );
    if (connectSignaling) {
      // Unlike the fromKeys factories, this registry path leaves the relay
      // WebSocket opt-in. Open it now so publish/subscribe actually reach a
      // relay; otherwise every set/getSignal fails ("All relays failed").
      await getINostrSignalingFromRegistry(key: key).connect();
    }
  }
  if (accountId != null) {
    RegistryAccess.register<_Wrap<IdAccountType>>(
      key,
      _Wrap(accountId),
    );
    SingletonDIAccess.addInstance<IdAccountType>(accountId);
  }
  _initializeDIRegistry(key);
}

/// Registry-based variant of initialPointErmesSignalingPartial.
/// Assumes INostrSignaling and IdAccountType are already registered.
void initialPointErmesSignalingPartialRegistry({String key = 'default'}) {
  _initializeDIRegistry(key);
}

void _initializeDIRegistry(String key) {
  // 1. Signaling server (needs: SignalingContract, IdAccountType)
  final server = ErmesSignalingServerDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingServer>>(
    key,
    _Wrap(server),
  );

  // 2. Book repository (no deps)
  final bookRepo = ErmesBookRepositoryDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesBookRepository<BookData>>>(
    key,
    _Wrap(bookRepo),
  );

  // 3. Book service (needs: IErmesBookRepository<BookData>)
  final bookService = ErmesBookServiceBaseDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesBookService<BookData>>>(
    key,
    _Wrap(bookService),
  );

  // 4. Signaling handler
  // (needs: IStunShspHandler, IShspSocket, IErmesBookService<BookData>)
  final handler = ErmesSignalingHandlerDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingHandler<IShspPeer>>>(
    key,
    _Wrap(handler),
  );

  // 5. Signaling repository
  // (needs: IErmesSignalingServer, IErmesSignalingHandler<IShspPeer>)
  final repo = ErmesSignalingRepositoryDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingRepository<ISignalErmes>>>(
    key,
    _Wrap(repo),
  );

  // 6. Signaling service (needs: IErmesSignalingRepository<ISignalErmes>)
  final service = ErmesSignalingServiceDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingService>>(
    key,
    _Wrap(service),
  );
}

/// Retrieve IErmesSignalingServer from registry by key.
IErmesSignalingServer getIErmesSignalingServerFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesSignalingServer>>(key).value;

/// Retrieve IErmesBookRepository<BookData> from registry by key.
IErmesBookRepository<BookData> getIErmesBookRepositoryFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess
        .getInstance<_Wrap<IErmesBookRepository<BookData>>>(key)
        .value;

/// Retrieve IErmesBookService<BookData> from registry by key.
IErmesBookService<BookData> getIErmesBookServiceFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesBookService<BookData>>>(key).value;

/// Retrieve IErmesSignalingHandler<IShspPeer> from registry by key.
IErmesSignalingHandler<IShspPeer> getIErmesSignalingHandlerFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess
        .getInstance<_Wrap<IErmesSignalingHandler<IShspPeer>>>(key)
        .value;

/// Retrieve IErmesSignalingRepository<ISignalErmes> from registry by key.
IErmesSignalingRepository<ISignalErmes>
    getIErmesSignalingRepositoryFromRegistry({String key = 'default'}) =>
        RegistryAccess
            .getInstance<_Wrap<IErmesSignalingRepository<ISignalErmes>>>(
              key,
            )
            .value;

/// Retrieve IErmesSignalingService from registry by key.
IErmesSignalingService getIErmesSignalingServiceFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesSignalingService>>(key).value;
