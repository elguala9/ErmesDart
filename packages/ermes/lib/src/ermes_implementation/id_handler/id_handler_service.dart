import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// Service for managing ID generation with optional persistent storage
@includeInBarrelFile
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

  void setCounter(int counter) {
    _repo.setCounter(counter);
    _storeNewId(counter);
  }

  int getCurrent() => _repo.getCurrent();
}
