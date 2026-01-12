import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import 'id_handler_storage_repository.dart';

/// Service implementation for ID handler persistent storage
@includeInBarrelFile
class IdHandlerStorageService implements IIdHandlerStorageService {
  IdHandlerStorageService(this._repository);

  final IdHandlerStorageRepository _repository;
  bool _closed = false;

  @override
  Future<void> update(IdType id) async {
    if (_closed) {
      throw StateError('Cannot update on closed storage service');
    }

    try {
      await _repository.update(id);
    } catch (e) {
      throw Exception('Storage service failed to update ID: $e');
    }
  }

  @override
  void save() {
    if (_closed) {
      return;
    }

    try {
      _repository.save();
    } catch (e) {
      throw Exception('Storage service failed to save ID: $e');
    }
  }

  @override
  void close() {
    if (_closed) {
      return;
    }

    _repository.close();
    _closed = true;
  }

  @override
  void destroy() {
    _repository.destroy();
    _closed = true;
  }

  /// Get the current stored ID
  IdType? get currentId => _repository.currentId;

  /// Check if service is closed
  bool get isClosed => _closed;

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_closed) {
      throw StateError('Cannot initialize closed storage service');
    }

    await _repository.initialize();
  }

  /// Load the stored ID
  Future<IdType?> load() async {
    if (_closed) {
      throw StateError('Cannot load from closed storage service');
    }

    return _repository.load();
  }

  /// Get the underlying repository
  IdHandlerStorageRepository get repository => _repository;
}
