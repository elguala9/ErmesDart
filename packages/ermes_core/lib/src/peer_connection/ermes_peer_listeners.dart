import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

/// Listener management for [ErmesPeer], extracted to keep the peer class
/// focused on connection lifecycle and send/offline-queue logic. Owns the
/// message / key-exchange / disconnect registries and exposes the public
/// `IErmesPeer` add/remove/clear surface plus small `notify*` helpers.
mixin ErmesPeerListeners {
  /// Registry of listeners notified when a message arrives.
  final CallbackHandler<TypeOfDataExternal, void> _onMessageHandler =
      CallbackHandler<TypeOfDataExternal, void>();
  /// Registry of listeners notified when a key exchange completes.
  final CallbackHandler<IdAccountType, void> _onKeyExchangeCompletedHandler =
      CallbackHandler<IdAccountType, void>();
  /// Callbacks invoked when the peer disconnects.
  final List<void Function()> _onDisconnectCallbacks = [];

  /// Registers a listener invoked on each incoming message.
  void addOnMessageListener(CallbackOnDataArrived callback) =>
      _onMessageHandler.register(callback);

  /// Unregisters a previously added message listener.
  void removeOnMessageListener(CallbackOnDataArrived callback) =>
      _onMessageHandler.unregister(callback);

  /// Removes all registered message listeners.
  void clearOnMessageListeners() => _onMessageHandler.clear();

  /// Registers a listener invoked when the peer disconnects.
  void addOnDisconnectListener(void Function() callback) =>
      _onDisconnectCallbacks.add(callback);

  /// Unregisters a previously added disconnect listener.
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
