import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_book_repository.dart';
import 'ermes_book_service.dart';
import 'ermes_signaling_handler.dart';
import 'ermes_signaling_repository.dart';
import 'ermes_signaling_server.dart';
import 'ermes_signaling_service.dart';

/// Connects the ermes_signaling graph to [RegistryManager].
///
/// Every call is independent: registering under a different [key] never
/// overwrites a previous call, so several graphs can live side by side.
///
/// The graph resolves three things this package does not own and which must be
/// registered under the same [key] first — [ErmesSignalingInjector] does that:
///  * `INostrSignaling`, the signaling transport,
///  * `IdAccountType`, this peer's account id,
///  * `IStunShspHandler` and `IShspSocket` under the `ipv4` subkey, from
///    stun_shsp's `initializeStunShsp`.
mixin MainInjectionErmesSignalingMixin {
  /// Called right before anything is connected. Override to customize.
  void beforeRegisterAllSingletonsErmesSignaling({String key = 'default'}) {}

  /// Connects every ermes_signaling singleton under [key], in dependency
  /// order. Instances are lazy, so the order below is documentation rather
  /// than a constraint.
  void registerAllSingletonsErmesSignaling({String key = 'default'}) {
    beforeRegisterAllSingletonsErmesSignaling(key: key);
    RegistryManager.instance
      ..connectInstance<IErmesSignalingServer, ErmesSignalingServer>(
        () => ErmesSignalingServer.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IErmesBookRepository<BookData>, ErmesBookRepository>(
        () => ErmesBookRepository.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IErmesBookService<BookData>, ErmesBookServiceBase>(
        () => ErmesBookServiceBase.dependencyInjectionFactory(key: key),
        key: key,
      )
      // The handler is registered three times on purpose. Registry lookups are
      // keyed by the exact type, and the two consumers ask for different ones:
      // ErmesSignalingRepository wants IErmesSignalingHandler<IShspPeer>,
      // OrcErmes wants IErmesSignalingHandler<ShspPeer>. Both interface
      // entries resolve the single concrete entry rather than building their
      // own, because the handler owns the per-peer socket map and the whole
      // stack has to share one.
      ..connectInstance<ErmesSignalingHandler, ErmesSignalingHandler>(
        () => ErmesSignalingHandler.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IErmesSignalingHandler<IShspPeer>,
          ErmesSignalingHandler>(
        () => RegistryManager.instance
            .getInstance<ErmesSignalingHandler>(key: key),
        key: key,
      )
      ..connectInstance<IErmesSignalingHandler<ShspPeer>,
          ErmesSignalingHandler>(
        () => RegistryManager.instance
            .getInstance<ErmesSignalingHandler>(key: key),
        key: key,
      )
      ..connectInstance<IErmesSignalingRepository<ISignalErmes>,
          ErmesSignalingRepository>(
        () => ErmesSignalingRepository.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IErmesSignalingService, ErmesSignalingService>(
        () => ErmesSignalingService.dependencyInjectionFactory(key: key),
        key: key,
      );
    afterRegisterAllSingletonsErmesSignaling(key: key);
  }

  /// Called right after everything is connected. Override to customize.
  void afterRegisterAllSingletonsErmesSignaling({String key = 'default'}) {}

  /// Called right before the async variant connects anything.
  Future<void> beforeRegisterAllSingletonsErmesSignalingAsync({
    String key = 'default',
  }) async {}

  /// Async twin of [registerAllSingletonsErmesSignaling] — required when the
  /// STUN/SHSP sockets or the Nostr transport still have to be set up.
  Future<void> registerAllSingletonsErmesSignalingAsync({
    String key = 'default',
  }) async {
    await beforeRegisterAllSingletonsErmesSignalingAsync(key: key);
    registerAllSingletonsErmesSignaling(key: key);
    await afterRegisterAllSingletonsErmesSignalingAsync(key: key);
  }

  /// Called right after the async variant finishes connecting.
  Future<void> afterRegisterAllSingletonsErmesSignalingAsync({
    String key = 'default',
  }) async {}
}

/// Ready-to-use injector for the ermes_signaling stack.
///
/// Supplies the prerequisites the graph resolves but does not own:
///  * binds the SHSP sockets and STUN handlers when [initializeStunShsp] is
///    true, delegating to stun_shsp's own injector,
///  * registers an `INostrSignaling` when a [keyPair] is given,
///  * registers [accountId] when given.
///
/// Use [registerAllSingletonsErmesSignalingAsync]; the sync variant cannot do
/// any of the above.
class ErmesSignalingInjector with MainInjectionErmesSignalingMixin {
  /// Creates an injector for the ermes_signaling stack.
  const ErmesSignalingInjector({
    this.keyPair,
    this.relayUrls,
    this.accountId,
    this.useCompression = false,
    this.initializeStunShsp = false,
    this.connectSignaling = false,
  });

  /// Nostr key pair identifying this peer on the signaling network.
  final NostrKeyPair? keyPair;

  /// Relay WebSocket URLs to publish and subscribe signals through.
  final List<String>? relayUrls;

  /// This peer's account identifier.
  final IdAccountType? accountId;

  /// Whether signal payloads are gzip-compressed.
  final bool useCompression;

  /// Whether to bind the SHSP sockets and STUN handlers.
  final bool initializeStunShsp;

  /// Whether to open the relay WebSockets straight away.
  ///
  /// Left opt-in so pure registration (e.g. in tests) stays offline; without
  /// it every publish/subscribe runs against a never-connected client.
  final bool connectSignaling;

  @override
  Future<void> beforeRegisterAllSingletonsErmesSignalingAsync({
    String key = 'default',
  }) async {
    if (initializeStunShsp) {
      await initializeStunShspStack(key: key);
    }
    final pair = keyPair;
    if (pair != null) {
      await NostrSignalingInjection(
        keyPair: pair,
        relayUrls: relayUrls ?? defaultRelayUrls,
        useCompression: useCompression,
      ).registerAllSingletonsNostrSignalingAsync(key: key);
      if (connectSignaling) {
        await RegistryManager.instance
            .getInstance<INostrSignaling>(key: key)
            .connect();
      }
    }
    final account = accountId;
    if (account != null) {
      RegistryManager.instance.setInstance<IdAccountType>(account, key: key);
    }
  }
}

/// Relays used when none are configured explicitly.
const List<String> defaultRelayUrls = ['wss://relay.damus.io'];

/// Binds the SHSP sockets and STUN handlers under [key].
///
/// Thin alias over stun_shsp's `initializeStunShsp`, kept so callers of this
/// package do not have to reach into stun_shsp directly, and so the name does
/// not collide with [ErmesSignalingInjector.initializeStunShsp].
Future<void> initializeStunShspStack({String key = 'default'}) =>
    initializeStunShsp(key: key);
