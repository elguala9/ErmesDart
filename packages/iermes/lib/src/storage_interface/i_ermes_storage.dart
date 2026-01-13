import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';

import 'i_ermes_storage_reserved.dart';

/// Repository interface for message storage
///
/// Storage typically persists messages to disk or a database for long-term
/// access. This is useful for message history and recovery after restarts.
@includeInBarrelFile
abstract class IErmesStorageRepository<DataJson extends MessageType>
    implements IErmesStorageAndCachingReserved<DataJson> {}

/// Service interface for message storage
///
/// Provides the same storage functionality at the service layer.
@includeInBarrelFile
abstract class IErmesStorageService<DataJson extends MessageType>
    implements IErmesStorageRepository<DataJson> {}
