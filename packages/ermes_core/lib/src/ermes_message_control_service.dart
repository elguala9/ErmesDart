import 'dart:async';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

@includeInBarrelFile
class ErmesMessageControlServiceOpts {
  ErmesMessageControlServiceOpts({required this.frequencyIdSaveState});
  final int frequencyIdSaveState;
}

@includeInBarrelFile
class ErmesMessageControlService implements IErmesMessageControlService {
  ErmesMessageControlService(this._repository, this._opts) {
    _repository.setCallbackIdsToRequest(_handleIdsToRequest);
  }
  final IErmesMessageControlRepository _repository;
  final ErmesMessageControlServiceOpts _opts;

  /// Callback handler for external ID request listeners
  late final CallbackHandler<List<IdType>, Future<void>> _idsToRequestHandler =
      CallbackHandler<List<IdType>, Future<void>>();

  int _idsCountChange = 0;

  @override
  void idArrived(IdType id) {
    _repository.idArrived(id);
  }

  @override
  Future<List<IdType>> idsToRequest() => _repository.idsToRequest();

  @override
  int numberOfMissingIds() => _repository.numberOfMissingIds();

  @override
  void setCallbackIdsToRequest(CallbackIdsToRequest callback) {
    // Legacy API: clear and register single callback
    _idsToRequestHandler.clear();
    _idsToRequestHandler.register(callback);
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
      await _repository.saveState();
      _idsCountChange = 0;
    }
  }

  @override
  Future<void> clear() => _repository.clear();

  @override
  Future<void> destroy() => _repository.destroy();

  Future<void> saveState() => _repository.saveState();
}
