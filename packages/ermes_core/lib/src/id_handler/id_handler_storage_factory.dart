import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import 'id_handler_storage_repository.dart'; // IA: fix import for repository
import 'id_handler_storage_service.dart'; // IA: fix import for service

/// Factory for creating ID handler storage components
@includeInBarrelFile
class IdHandlerStorageFactory {
  IdHandlerStorageFactory._();

  /// Create a complete ID handler storage system with default in-memory storage
  ///
  /// [maxCacheSize] - Maximum number of items to cache (default: 100)
  /// Returns a new [IIdHandlerStorageService] instance
  static IIdHandlerStorageService createDefault({int maxCacheSize = 100}) =>
      IdHandlerStorageService(
        IdHandlerStorageRepository(),
      ); // IA: use real in-memory impl
}

/// Simple in-memory implementation of ID handler storage
