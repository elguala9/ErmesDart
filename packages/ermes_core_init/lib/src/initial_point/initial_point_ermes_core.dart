import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'initial_point_ermes_cipher.dart';
import 'initial_point_ermes_signaling.dart';
import 'initial_point_messages.dart';

/// Wires all ermes_core dependencies into the singleton DI container.
///
/// If [keyPair] is provided, [initialPointNostrSignaling] is called
/// internally to satisfy the [INostrSignaling] dependency.
///
/// If [initializeStunShsp] is true, [initializePointStunShsp] is called
/// to bind SHSP sockets and initialize STUN (using initial points from
/// shsp and stun packages).
///
/// Additional prerequisites (when not auto-initialized):
///   - SignalingContract
///   - IStunShspHandler
///   - IShspSocket
///   - (optional) call initialPointErmesCipher() for encryption support
///
/// Call order:
///   1. initialPointErmesSignaling  → IErmesSignalingServer, IErmesBookService,
///      IErmesSignalingHandler<IShspPeer>, …
///   2. initialPointErmesCipher (async) — only if not already initialised
///   3. Bridge IErmesSignalingHandler<IShspPeer> →
///      IErmesSignalingHandler<ShspPeer> (OrcErmesDI needs concrete type)
///   4. ErmesConnectionsHandlerDI
///   5. OrcErmesDI  →  IOrcErmes
Future<void> initialPointErmesCore({
  NostrKeyPair? keyPair,
  List<String>? relayUrls,
  bool useCompression = false,
  IdAccountType? accountId,
  bool initializeStunShsp = false,
  bool connectSignaling = false,
}) async {
  // 0. Message storage/caching handlers — required by ErmesSendRepo and
  //    ErmesReadRepo at openConnection time. Idempotent: skipped if a test
  //    (or earlier call) already registered them.
  initialPointErmesStorage();

  // 1. Signaling stack (server, book repo/service, handler, signaling repo/service)
  await initialPointErmesSignaling(
    keyPair: keyPair,
    relayUrls: relayUrls,
    useCompression: useCompression,
    accountId: accountId,
    initializeStunShsp: initializeStunShsp,
    connectSignaling: connectSignaling,
  );

  // 2. Cipher stack — only if not already initialised by the caller
  if (!SingletonDIAccess.exists<IKeyExchange>()) {
    await initialPointErmesCipher();
  }

  // 3. OrcErmesDI pulls IErmesSignalingHandler<ShspPeer> but
  //    initialPointErmesSignaling registers it as <IShspPeer>.
  //    Bridge by adding the same instance under the concrete-type key.
  final handler = SingletonDIAccess.get<IErmesSignalingHandler<IShspPeer>>();
  SingletonDIAccess.addInstance<IErmesSignalingHandler<ShspPeer>>(
    handler as IErmesSignalingHandler<ShspPeer>,
  );

  // 4. ErmesConnectionsHandler (no injected deps)
  final connectionsHandler = ErmesConnectionsHandlerDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      ErmesConnectionsHandler, ErmesConnectionsHandlerDI>(connectionsHandler);

  // 5. OrcErmes — pulls all deps from DI
  final orcErmes = OrcErmesDI.initializeDI();
  SingletonDIAccess.addInstanceAs<IOrcErmes<BookData>, OrcErmesDI>(orcErmes);
}

/// Convenience getter — call after initialPointErmesCore completes.
IOrcErmes<BookData> getIOrcErmes() =>
    SingletonDIAccess.get<IOrcErmes<BookData>>();
