import 'package:ermes_cipher/src/initial_point_ermes_cipher.dart';
import 'package:ermes_signaling/src/initial_point_ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_connections_handler.dart';
import '../generated/ermes_connections_handler_di.dart';
import '../generated/orc_ermes_di.dart';
import '../orc_ermes.dart';

/// Wires all ermes_core dependencies into the singleton DI container and
/// returns a fully initialised IOrcErmes instance.
///
/// Call order:
///   1. Register IdAccountType (needed by ErmesSignalingServerDI)
///   2. initialPointErmesSignaling  → IErmesSignalingServer, IErmesBookService,
///      IErmesSignalingHandler<IShspPeer>, IShspSocket, …
///   3. initialPointErmesCipher (async) — only when enableEncryption=true
///   4. Bridge IErmesSignalingHandler<IShspPeer> → IErmesSignalingHandler<ShspPeer>
///      so OrcErmesDI can resolve the field typed ShspPeer
///   5. ErmesConnectionsHandlerDI
///   6. OrcErmesDI  →  IOrcErmes
Future<void> initialPointErmesCore({
  required SignalingContract contract,
  required IdAccountType accountId,
  required IStunShspHandler stunShspHandler,
  required IShspSocket socket,
  bool enableEncryption = true,
}) async {
  // 0. accountId must be in DI before signaling server is created
  SingletonDIAccess.addInstance<IdAccountType>(accountId);

  // 1. Signaling stack (server, book repo/service, handler, signaling repo/service)
  initialPointErmesSignaling(
    contract: contract,
    stunShspHandler: stunShspHandler,
    socket: socket,
  );

  // 2. Cipher stack — async key-pair generation
  if (enableEncryption) {
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
