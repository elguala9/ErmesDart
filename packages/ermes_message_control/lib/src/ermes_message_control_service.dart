import 'dart:async';


import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../ermes_message_control.dart';


/// Configuration options for [ErmesMessageControlService].
class ErmesMessageControlServiceOpts {
  /// Creates options with an optional save-state [frequencyIdSaveState].
  ErmesMessageControlServiceOpts({this.frequencyIdSaveState = 10});
  /// Number of ID-change events between automatic state saves.
  final int frequencyIdSaveState;
}

/// Service coordinating message-control tracking on top of a repository.
@isSingleton
class ErmesMessageControlService implements IErmesMessageControlService {
  /// Default constructor used by the dependency injection framework.
  ErmesMessageControlService();

  /// Creates a service wired to [repository] with optional [opts],
  /// registering the internal missing-IDs callback.
  ErmesMessageControlService.createWithRepository(
      this.repository, [ErmesMessageControlServiceOpts? opts])
      : _opts = opts ?? ErmesMessageControlServiceOpts() {
    repository.setCallbackIdsToRequest(_handleIdsToRequest);
  }
  /// Repository backing this service's message-control state.
  @isInjected
  @protected
  late IErmesMessageControlRepository repository =
      ErmesMessageControlRepository();
  /// Configuration options controlling save-state behavior.
  late ErmesMessageControlServiceOpts _opts =
      ErmesMessageControlServiceOpts();

  /// Callback handler for external ID request listeners
  late final CallbackHandler<List<IdType>, Future<void>> _idsToRequestHandler =
      CallbackHandler<List<IdType>, Future<void>>();

  /// Counts ID-change events since the last automatic save-state.
  int _idsCountChange = 0;

  /// Forwards an incoming [id] to the repository for tracking.
  @override
  void idArrived(IdType id) {
    repository.idArrived(id);
  }

  /// Returns the list of IDs that still need to be requested.
  @override
  Future<List<IdType>> idsToRequest() => repository.idsToRequest();

  /// Returns the count of currently missing IDs.
  @override
  int numberOfMissingIds() => repository.numberOfMissingIds();

  /// Legacy API: clears existing listeners and registers a single [callback].
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

  /// Runs internal bookkeeping then invokes all registered external listeners.
  Future<void> _handleIdsToRequest(List<IdType> ids) async {
    await _performInternalOperations(ids);

    // Invoke all registered external callbacks and wait for all futures
    final results = _idsToRequestHandler.call(ids);
    if (results.isNotEmpty) {
      await Future.wait(results.values);
    }
  }

  /// Increments the change counter and saves state when the threshold is hit.
  Future<void> _performInternalOperations(List<IdType> ids) async {
    _idsCountChange += 1;
    if (_idsCountChange >= _opts.frequencyIdSaveState) {
      await repository.saveState();
      _idsCountChange = 0;
    }
  }

  /// Clears the tracked set of missing IDs.
  @override
  Future<void> clear() => repository.clear();

  /// Resets all message-control state in the repository.
  @override
  Future<void> destroy() => repository.destroy();

  /// Returns the highest sequential ID received so far.
  @override
  IdType? getLastReceivedId() => repository.getLastReceivedId();

  /// Persists the current message-control state.
  Future<void> saveState() => repository.saveState();
}
