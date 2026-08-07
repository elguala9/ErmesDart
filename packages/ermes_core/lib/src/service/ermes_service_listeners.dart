import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

import '../repository/ermes_read_repo.dart';

/// Listener management for [ErmesService], extracted to keep the service class
/// focused on coordination. Owns the callback registries and exposes both the
/// public `IErmesService` add/remove/clear surface and small `notify*` /
/// `clearAllListeners` helpers used internally by the service.
mixin ErmesServiceListeners {
  /// The read repository that owns the data-arrived listeners.
  ErmesReadRepo get ermesReadRepo;

  /// Callbacks invoked when the remote peer closes the connection.
  final List<void Function()> _onRemoteCloseCallbacks = [];
  /// Registry of listeners notified before data is sent.
  final CallbackHandler<TypeOfData, void> _onDataSendingHandler =
      CallbackHandler<TypeOfData, void>();
  /// Registry of listeners notified after data is sent.
  final CallbackHandler<TypeOfData, void> _onDataSentHandler =
      CallbackHandler<TypeOfData, void>();
  /// Registry of listeners notified when a new key is received.
  final CallbackHandler<ServiceMessageNewKey, void> _onNewKeyHandler =
      CallbackHandler<ServiceMessageNewKey, void>();

  /// Registers a listener invoked before data is sent.
  void addOnDataSendingListener(CallbackOnDataSending cb) =>
      _onDataSendingHandler.register(cb);
  /// Unregisters a previously added data-sending listener.
  void removeOnDataSendingListener(CallbackOnDataSending cb) =>
      _onDataSendingHandler.unregister(cb);
  /// Removes all data-sending listeners.
  void clearOnDataSendingListeners() => _onDataSendingHandler.clear();

  /// Registers a listener invoked after data is sent.
  void addOnDataSentListener(CallbackOnDataSent cb) =>
      _onDataSentHandler.register(cb);
  /// Unregisters a previously added data-sent listener.
  void removeOnDataSentListener(CallbackOnDataSent cb) =>
      _onDataSentHandler.unregister(cb);
  /// Removes all data-sent listeners.
  void clearOnDataSentListeners() => _onDataSentHandler.clear();

  /// Registers a listener invoked when a new key is received.
  void addOnNewKeyListener(CallbackOnNewKey cb) =>
      _onNewKeyHandler.register(cb);
  /// Unregisters a previously added new-key listener.
  void removeOnNewKeyListener(CallbackOnNewKey cb) =>
      _onNewKeyHandler.unregister(cb);
  /// Removes all new-key listeners.
  void clearOnNewKeyListeners() => _onNewKeyHandler.clear();

  /// Registers a listener invoked when the remote peer closes the connection.
  void addOnRemoteCloseListener(void Function() cb) =>
      _onRemoteCloseCallbacks.add(cb);
  /// Unregisters a previously added remote-close listener.
  void removeOnRemoteCloseListener(void Function() cb) =>
      _onRemoteCloseCallbacks.remove(cb);
  /// Removes all remote-close listeners.
  void clearOnRemoteCloseListeners() => _onRemoteCloseCallbacks.clear();

  /// Registers a listener invoked when application data arrives.
  void addOnMessageDataListener(CallbackOnDataArrived cb) =>
      ermesReadRepo.addOnDataArrivedListener(cb);
  /// Unregisters a previously added data-arrived listener.
  void removeOnMessageDataListener(CallbackOnDataArrived cb) =>
      ermesReadRepo.removeOnDataArrivedListener(cb);
  /// Removes all data-arrived listeners.
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
