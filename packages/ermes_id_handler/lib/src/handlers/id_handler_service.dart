
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../../ermes_id_handler.dart';

/// Service for managing ID generation with optional persistent storage
@dependencyInjectable
class IdHandlerService implements IIdHandlerService {
  /// Creates an IdHandlerService from its generating [repo] and the [storage]
  /// service used to persist every generated ID.
  IdHandlerService({
    required this.repo,
    required this.storage,
  });

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory IdHandlerService.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final repo = RegistryManager.instance.getInstance<IIdHandlerRepository>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final storage = RegistryManager.instance.getInstance<IIdHandlerStorageService>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return IdHandlerService( // GENERATED CODE - DO NOT MODIFY BY HAND
      repo: repo, // GENERATED CODE - DO NOT MODIFY BY HAND
      storage: storage, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Creates an IdHandlerService
  ///
  /// [repo] - Repository for ID generation
  /// [storage] - Optional storage service for persisting IDs
  IdHandlerService.fromRepo({
    required this.repo,
    IIdHandlerStorageService? storage,
  }) : storage = storage ?? IdHandlerStorageService.inMemory();

  /// Repository responsible for generating sequential IDs.
  final IIdHandlerRepository repo;
  /// Storage service used to persist the latest generated ID.
  final IIdHandlerStorageService storage;

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
