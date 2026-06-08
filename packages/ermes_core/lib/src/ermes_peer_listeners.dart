import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

/// Listener management for [ErmesPeer], extracted to keep the peer class
/// focused on connection lifecycle and send/offline-queue logic. Owns the
/// message / key-exchange / disconnect registries and exposes the public
/// `IErmesPeer` add/remove/clear surface plus small `notify*` helpers.
mixin ErmesPeerListeners {
  final CallbackHandler<TypeOfDataExternal, void> _onMessageHandler =
      CallbackHandler<TypeOfDataExternal, void>();
  final CallbackHandler<IdAccountType, void> _onKeyExchangeCompletedHandler =
      CallbackHandler<IdAccountType, void>();
  final List<void Function()> _onDisconnectCallbacks = [];

  void addOnMessageListener(CallbackOnDataArrived callback) =>
      _onMessageHandler.register(callback);

  void removeOnMessageListener(CallbackOnDataArrived callback) =>
      _onMessageHandler.unregister(callback);

  void clearOnMessageListeners() => _onMessageHandler.clear();

  void addOnDisconnectListener(void Function() callback) =>
      _onDisconnectCallbacks.add(callback);

  void removeOnDisconnectListener(void Function() callback) =>
      _onDisconnectCallbacks.remove(callback);

  /// Notifies registered message listeners.
  void notifyMessage(TypeOfDataExternal data) => _onMessageHandler.call(data);

  /// Notifies registered disconnect listeners.
  void notifyDisconnect() {
    for (final cb in List.of(_onDisconnectCallbacks)) {
      cb();
    }
  }

  /// Clears every listener registry owned by this mixin.
  void disposeListeners() {
    _onDisconnectCallbacks.clear();
    _onMessageHandler.clear();
    _onKeyExchangeCompletedHandler.clear();
  }
}
