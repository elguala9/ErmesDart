
import 'package:iermes/iermes.dart';

/// Service for managing ID generation with optional persistent storage

class IdHandlerService implements IIdHandlerService {
  /// Creates an IdHandlerService
  ///
  /// [repo] - Repository for ID generation
  /// [storage] - Optional storage service for persisting IDs
  IdHandlerService({
    required IIdHandlerRepository repo,
    IIdHandlerStorageService? storage,
  }) : _repo = repo,
       _storage = storage;
  final IIdHandlerRepository _repo;
  final IIdHandlerStorageService? _storage;

  void _storeNewId(IdType newId) {
    _storage?.update(newId);
  }

  @override
  int getNewId() {
    final newId = _repo.getNewId();
    _storeNewId(newId);
    return newId;
  }

  @override
  void reset() {
    _repo.reset();
  }

  @override
  void setCounter(int counter) {
    _repo.setCounter(counter);
    _storeNewId(counter);
  }

  @override
  int getCurrent() => _repo.getCurrent();
}
