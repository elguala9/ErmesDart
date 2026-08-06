import 'dart:async';


import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';


/// Configuration options for [ErmesMessageControlService].
class ErmesMessageControlServiceOpts {
  /// Creates options with an optional save-state [frequencyIdSaveState].
  ErmesMessageControlServiceOpts({this.frequencyIdSaveState = 10});
  /// Number of ID-change events between automatic state saves.
  final int frequencyIdSaveState;
}

/// Service coordinating message-control tracking on top of a repository.
@dependencyInjectable
class ErmesMessageControlService implements IErmesMessageControlService {
  /// Creates a service wired to [repository] with optional [opts],
  /// registering the internal missing-IDs callback.
  ErmesMessageControlService(
      this.repository, [ErmesMessageControlServiceOpts? opts])
      : _opts = opts ?? ErmesMessageControlServiceOpts() {
    repository.setCallbackIdsToRequest(_handleIdsToRequest);
  }

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ErmesMessageControlService.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final repository = RegistryManager.instance.getInstance<IErmesMessageControlRepository>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final opts = RegistryManager.instance.tryGetInstance<ErmesMessageControlServiceOpts>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesMessageControlService( // GENERATED CODE - DO NOT MODIFY BY HAND
      repository, // GENERATED CODE - DO NOT MODIFY BY HAND
      opts, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Creates a service wired to [repository] with optional [opts],
  /// registering the internal missing-IDs callback.
  ErmesMessageControlService.createWithRepository(
    IErmesMessageControlRepository repository, [
    ErmesMessageControlServiceOpts? opts,
  ]) : this(repository, opts);

  /// Repository backing this service's message-control state.
  @protected
  final IErmesMessageControlRepository repository;
  /// Configuration options controlling save-state behavior.
  final ErmesMessageControlServiceOpts _opts;

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
