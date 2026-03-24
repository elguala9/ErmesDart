import 'dart:async';


import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../ermes_message_control.dart';


class ErmesMessageControlServiceOpts {
  ErmesMessageControlServiceOpts({this.frequencyIdSaveState = 10});
  final int frequencyIdSaveState;
}

@isSingleton
class ErmesMessageControlService implements IErmesMessageControlService {
  ErmesMessageControlService();

  ErmesMessageControlService.createWithRepository(this.repository, [ErmesMessageControlServiceOpts? opts])
      : _opts = opts ?? ErmesMessageControlServiceOpts() {
    repository.setCallbackIdsToRequest(_handleIdsToRequest);
  }
  @isInjected
  @protected
  late IErmesMessageControlRepository repository = ErmesMessageControlRepository();
  late  ErmesMessageControlServiceOpts _opts = ErmesMessageControlServiceOpts();

  /// Callback handler for external ID request listeners
  late final CallbackHandler<List<IdType>, Future<void>> _idsToRequestHandler =
      CallbackHandler<List<IdType>, Future<void>>();

  int _idsCountChange = 0;

  @override
  void idArrived(IdType id) {
    repository.idArrived(id);
  }

  @override
  Future<List<IdType>> idsToRequest() => repository.idsToRequest();

  @override
  int numberOfMissingIds() => repository.numberOfMissingIds();

  @override
  void setCallbackIdsToRequest(CallbackIdsToRequest callback) {
    // Legacy API: clear and register single callback
    _idsToRequestHandler
      ..clear()
      ..register(callback);
  }

  /// Register a listener for IDs to request
  void addIdsToRequestListener(CallbackIdsToRequest callback) {
    _idsToRequestHandler.register(callback);
  }

  /// Remove a listener for IDs to request
  void removeIdsToRequestListener(CallbackIdsToRequest callback) {
    _idsToRequestHandler.unregister(callback);
  }

  /// Clear all IDs to request listeners
  void clearIdsToRequestListeners() {
    _idsToRequestHandler.clear();
  }

  Future<void> _handleIdsToRequest(List<IdType> ids) async {
    await _performInternalOperations(ids);

    // Invoke all registered external callbacks and wait for all futures
    final results = _idsToRequestHandler.call(ids);
    if (results.isNotEmpty) {
      await Future.wait(results.values);
    }
  }

  Future<void> _performInternalOperations(List<IdType> ids) async {
    _idsCountChange += 1;
    if (_idsCountChange >= _opts.frequencyIdSaveState) {
      await repository.saveState();
      _idsCountChange = 0;
    }
  }

  @override
  Future<void> clear() => repository.clear();

  @override
  Future<void> destroy() => repository.destroy();

  @override
  IdType? getLastReceivedId() => repository.getLastReceivedId();

  Future<void> saveState() => repository.saveState();
}
