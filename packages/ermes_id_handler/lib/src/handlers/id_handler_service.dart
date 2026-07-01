
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../../ermes_id_handler.dart';

/// Service for managing ID generation with optional persistent storage
@isSingleton
class IdHandlerService implements IIdHandlerService {
  /// Default constructor used by the dependency injection framework.
  IdHandlerService();
  /// Creates an IdHandlerService
  ///
  /// [repo] - Repository for ID generation
  /// [storage] - Optional storage service for persisting IDs
  IdHandlerService.fromRepo({
    required this.repo,
    IIdHandlerStorageService? storage,
  }) : storage = storage ?? IdHandlerStorageService();

  /// Repository responsible for generating sequential IDs.
  @isInjected
  late IIdHandlerRepository repo = IdHandlerRepository();
  /// Storage service used to persist the latest generated ID.
  @isInjected
  late IIdHandlerStorageService storage = IdHandlerStorageService();

  /// Persists the given [newId] through the storage service.
  void _storeNewId(IdType newId) {
    storage.update(newId);
  }

  /// Generates a new ID from the repository and persists it before returning.
  @override
  int getNewId() {
    final newId = repo.getNewId();
    _storeNewId(newId);
    return newId;
  }

  /// Resets the underlying repository counter to zero.
  @override
  void reset() {
    repo.reset();
  }

  /// Sets the repository counter to [counter] and persists the value.
  @override
  void setCounter(int counter) {
    repo.setCounter(counter);
    _storeNewId(counter);
  }

  /// Returns the current counter value from the repository.
  @override
  int getCurrent() => repo.getCurrent();
}
