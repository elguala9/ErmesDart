import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Repository for storing ID handler state persistently
@includeInBarrelFile
class IdHandlerStorageRepository implements IIdHandlerStorageRepository {
  /// Creates an IdHandlerStorageRepository
  IdHandlerStorageRepository();

  @override
  Future<void> update(IdType id) async {
    // In-memory storage - could be extended with persistent backend
  }

  @override
  void save() {
    // For in-memory storage, this is typically a no-op
  }

  @override
  void close() {
    // Close any open connections or resources
  }

  @override
  void destroy() {
    // No-op for in-memory storage
  }
}
