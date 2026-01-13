import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Local repository interface for ID handler storage
/// Provides persistent storage for ID counters in the repository layer
@includeInBarrelFile
abstract class IIdHandlerStorageRepositoryLocal
    implements IIdHandlerStorageRepository {
  // Inherits all methods from the interface
}

/// Local service interface for ID handler storage
/// Provides persistent storage for ID counters in the service layer
@includeInBarrelFile
abstract class IIdHandlerStorageServiceLocal
    implements IIdHandlerStorageService {
  // Inherits all methods from the interface
}
