import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

/// Listener registries for `ErmesReadRepo`: the decoded service-message and
/// data-arrived streams. Extracted to keep the read repository focused on
/// decoding and chunk reassembly. Exposes add/remove/clear plus `notify*`
/// helpers used internally.
mixin ErmesReadRepoListeners {
  /// Registry of listeners notified when a service message is decoded.
  final CallbackHandler<ServiceMessage, void> _serviceMessageHandler =
      CallbackHandler<ServiceMessage, void>();
  /// Registry of listeners notified when application data arrives.
  final CallbackHandler<TypeOfDataExternal, void> _onDataArrivedHandler =
      CallbackHandler<TypeOfDataExternal, void>();

  /// Registers a listener invoked for each decoded service message.
  void addServiceMessageListener(CallbackServiceMessage cb) =>
      _serviceMessageHandler.register(cb);
  /// Unregisters a previously added service-message listener.
  void removeServiceMessageListener(CallbackServiceMessage cb) =>
      _serviceMessageHandler.unregister(cb);

  /// Registers a listener invoked when application data arrives.
  void addOnDataArrivedListener(CallbackOnDataArrived cb) =>
      _onDataArrivedHandler.register(cb);
  /// Unregisters a previously added data-arrived listener.
  void removeOnDataArrivedListener(CallbackOnDataArrived cb) =>
      _onDataArrivedHandler.unregister(cb);
  /// Removes all registered data-arrived listeners.
  void clearOnDataArrivedListeners() => _onDataArrivedHandler.clear();

  /// Notifies registered service-message listeners.
  void notifyServiceMessage(ServiceMessage message) =>
      _serviceMessageHandler.call(message);

  /// Notifies registered data-arrived listeners.
  void notifyDataArrived(TypeOfDataExternal data) =>
      _onDataArrivedHandler.call(data);
}
