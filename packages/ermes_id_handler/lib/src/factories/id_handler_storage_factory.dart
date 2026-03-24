
import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

import '../storage/id_handler_storage_repository.dart';
import '../storage/id_handler_storage_service.dart';

/// Factory for creating ID handler storage components
class IdHandlerStorageFactory {
  IdHandlerStorageFactory._();

  /// Create a complete ID handler storage system with default in-memory work_db
  static IIdHandlerStorageService createDefault() =>
      IdHandlerStorageService.fromRepo(
        IdHandlerStorageRepository.fromDb(
          WorkDbFactory().create(const MemoryWorkDbFactoryInput()),
        ),
      );

  /// Create an ID handler storage system with a custom [IWorkDb] instance
  static IIdHandlerStorageService createWithDb(IWorkDb db,
          [String? collection]) =>
      IdHandlerStorageService.fromRepo(
        collection != null
            ? IdHandlerStorageRepository()
            : IdHandlerStorageRepository(),
      );
}

/// Simple in-memory implementation of ID handler storage
