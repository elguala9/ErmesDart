import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'initial_point_ermes_cipher.dart';
import 'initial_point_ermes_signaling.dart';
import 'package:ermes_core/src/ermes_connections_handler.dart';
import 'package:ermes_core/src/generated/ermes_connections_handler_di.dart';
import 'package:ermes_core/src/generated/orc_ermes_di.dart';

/// Wires all ermes_core dependencies into the singleton DI container.
///
/// Prerequisites — register in SingletonDIAccess before calling:
///   - SignalingContract
///   - IdAccountType
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
Future<void> initialPointErmesCore() async {
  // 1. Signaling stack (server, book repo/service, handler, signaling repo/service)
  initialPointErmesSignaling();

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
  SingletonDIAccess.addInstanceAs<IOrcErmes, OrcErmesDI>(orcErmes);
}

/// Convenience getter — call after initialPointErmesCore completes.
IOrcErmes getIOrcErmes() => SingletonDIAccess.get<IOrcErmes>();
