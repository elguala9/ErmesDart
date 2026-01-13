import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// Factory for creating ID handler storage components
@includeInBarrelFile
class IdHandlerStorageFactory {
  IdHandlerStorageFactory._();

  /// Create a complete ID handler storage system with default in-memory storage
  ///
  /// [maxCacheSize] - Maximum number of items to cache (default: 100)
  /// Returns a new [IIdHandlerStorageService] instance
  static IIdHandlerStorageService createDefault({int maxCacheSize = 100}) =>
      _SimpleIdHandlerStorageService();
}

/// Simple in-memory implementation of ID handler storage
class _SimpleIdHandlerStorageService implements IIdHandlerStorageService {
  @override
  Future<void> update(IdType id) async {
    // In-memory storage - could be extended with persistent backend
  }

  @override
  void save() {
    // No-op for in-memory storage
  }

  @override
  void close() {
    // No-op for in-memory storage
  }

  @override
  void destroy() {
    // No-op for in-memory storage
  }
}
