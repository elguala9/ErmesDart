import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

import 'ermes_read_repo.dart';

/// Listener management for [ErmesService], extracted to keep the service class
/// focused on coordination. Owns the callback registries and exposes both the
/// public `IErmesService` add/remove/clear surface and small `notify*` /
/// `clearAllListeners` helpers used internally by the service.
mixin ErmesServiceListeners {
  /// The read repository that owns the data-arrived listeners.
  ErmesReadRepo get ermesReadRepo;

  final List<void Function()> _onRemoteCloseCallbacks = [];
  final CallbackHandler<TypeOfData, void> _onDataSendingHandler =
      CallbackHandler<TypeOfData, void>();
  final CallbackHandler<TypeOfData, void> _onDataSentHandler =
      CallbackHandler<TypeOfData, void>();
  final CallbackHandler<ServiceMessageNewKey, void> _onNewKeyHandler =
      CallbackHandler<ServiceMessageNewKey, void>();

  void addOnDataSendingListener(CallbackOnDataSending cb) =>
      _onDataSendingHandler.register(cb);
  void removeOnDataSendingListener(CallbackOnDataSending cb) =>
      _onDataSendingHandler.unregister(cb);
  void clearOnDataSendingListeners() => _onDataSendingHandler.clear();

  void addOnDataSentListener(CallbackOnDataSent cb) =>
      _onDataSentHandler.register(cb);
  void removeOnDataSentListener(CallbackOnDataSent cb) =>
      _onDataSentHandler.unregister(cb);
  void clearOnDataSentListeners() => _onDataSentHandler.clear();

  void addOnNewKeyListener(CallbackOnNewKey cb) =>
      _onNewKeyHandler.register(cb);
  void removeOnNewKeyListener(CallbackOnNewKey cb) =>
      _onNewKeyHandler.unregister(cb);
  void clearOnNewKeyListeners() => _onNewKeyHandler.clear();

  void addOnRemoteCloseListener(void Function() cb) =>
      _onRemoteCloseCallbacks.add(cb);
  void removeOnRemoteCloseListener(void Function() cb) =>
      _onRemoteCloseCallbacks.remove(cb);
  void clearOnRemoteCloseListeners() => _onRemoteCloseCallbacks.clear();

  void addOnMessageDataListener(CallbackOnDataArrived cb) =>
      ermesReadRepo.addOnDataArrivedListener(cb);
  void removeOnMessageDataListener(CallbackOnDataArrived cb) =>
      ermesReadRepo.removeOnDataArrivedListener(cb);
  void clearOnMessageDataListeners() =>
      ermesReadRepo.clearOnDataArrivedListeners();

  /// Notifies registered "data sending" listeners.
  void notifyDataSending(TypeOfData message) =>
      _onDataSendingHandler.call(message);

  /// Notifies registered "data sent" listeners.
  void notifyDataSent(TypeOfData message) => _onDataSentHandler.call(message);

  /// Notifies registered "new key" listeners.
  void notifyNewKey(ServiceMessageNewKey message) =>
      _onNewKeyHandler.call(message);

  /// Notifies registered "remote close" listeners.
  void notifyRemoteClose() {
    for (final cb in List.of(_onRemoteCloseCallbacks)) {
      cb();
    }
  }

  /// Clears every registered listener owned by this mixin.
  void clearAllListeners() {
    _onDataSendingHandler.clear();
    _onDataSentHandler.clear();
    _onNewKeyHandler.clear();
    _onRemoteCloseCallbacks.clear();
  }
}
