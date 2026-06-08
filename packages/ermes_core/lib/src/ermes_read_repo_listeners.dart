import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

/// Listener registries for `ErmesReadRepo`: the decoded service-message and
/// data-arrived streams. Extracted to keep the read repository focused on
/// decoding and chunk reassembly. Exposes add/remove/clear plus `notify*`
/// helpers used internally.
mixin ErmesReadRepoListeners {
  final CallbackHandler<ServiceMessage, void> _serviceMessageHandler =
      CallbackHandler<ServiceMessage, void>();
  final CallbackHandler<TypeOfDataExternal, void> _onDataArrivedHandler =
      CallbackHandler<TypeOfDataExternal, void>();

  void addServiceMessageListener(CallbackServiceMessage cb) =>
      _serviceMessageHandler.register(cb);
  void removeServiceMessageListener(CallbackServiceMessage cb) =>
      _serviceMessageHandler.unregister(cb);

  void addOnDataArrivedListener(CallbackOnDataArrived cb) =>
      _onDataArrivedHandler.register(cb);
  void removeOnDataArrivedListener(CallbackOnDataArrived cb) =>
      _onDataArrivedHandler.unregister(cb);
  void clearOnDataArrivedListeners() => _onDataArrivedHandler.clear();

  /// Notifies registered service-message listeners.
  void notifyServiceMessage(ServiceMessage message) =>
      _serviceMessageHandler.call(message);

  /// Notifies registered data-arrived listeners.
  void notifyDataArrived(TypeOfDataExternal data) =>
      _onDataArrivedHandler.call(data);
}
