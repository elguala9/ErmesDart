import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

import '../repository/ermes_send_repo.dart';

/// Encryption public-key rotation surface of `ErmesService` (RFC 8.6):
/// sends `newpubkey` and notifies listeners when the peer announces one.
///
/// The service itself owns no key pair, so re-deriving the directional
/// session keys is left to the listener (the orchestrator, which holds the
/// local `IKeyExchange`).
mixin ErmesServicePubKeyHandler {
  /// Id handler used to mint message ids.
  IIdHandlerService get idHandler;

  /// Transport repository the service sends through.
  ErmesSendRepo get ermesSendRepo;

  /// Registry of listeners notified when a newpubkey arrives.
  final CallbackHandler<ServiceMessageNewPubKey, void> _onNewPubKeyHandler =
      CallbackHandler<ServiceMessageNewPubKey, void>();

  /// Sends a `newpubkey` carrying the new public [key]. Completes once the
  /// frame is dispatched (under the current outbound key, if any), so the
  /// caller can switch its outbound key only afterwards.
  Future<void> sendNewPubKey({required String key}) async {
    final msg = ServiceMessageNewPubKey(id: idHandler.getNewId(), key: key);
    await ermesSendRepo.sendMessageType([MessageType.service(msg)]);
  }

  /// Registers a listener invoked when the peer announces a new public key.
  void addOnNewPubKeyListener(CallbackOnNewPubKey cb) =>
      _onNewPubKeyHandler.register(cb);

  /// Clears every newpubkey listener.
  void clearOnNewPubKeyListeners() => _onNewPubKeyHandler.clear();

  /// Notifies newpubkey listeners of [message].
  void notifyNewPubKey(ServiceMessageNewPubKey message) =>
      _onNewPubKeyHandler.call(message);
}
