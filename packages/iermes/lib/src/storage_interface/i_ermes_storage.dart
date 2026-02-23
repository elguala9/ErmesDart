import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Repository interface for message storage
///
/// Storage typically persists messages to disk or a database for long-term
/// access. This is useful for message history and recovery after restarts.
@includeInBarrelFile
abstract class IErmesStorageRepository<DataJson>
    implements IErmesStorageAndCachingReserved<DataJson> {}

/// Service interface for message storage
///
/// Provides the same storage functionality at the service layer.
@includeInBarrelFile
abstract class IErmesStorageService<DataJson>
    implements IErmesStorageRepository<DataJson> {}
