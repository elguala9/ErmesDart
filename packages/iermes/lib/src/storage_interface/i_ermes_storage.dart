

import '../../iermes.dart';

/// Repository interface for message storage
///
/// Storage typically persists messages to disk or a database for long-term
/// access. This is useful for message history and recovery after restarts.
abstract class IErmesStorageRepository<DataJson>
    implements IErmesStorageAndCachingReserved<DataJson> {}

/// Service interface for message storage
///
/// Provides the same storage functionality at the service layer.
abstract class IErmesStorageService<DataJson>
    implements IErmesStorageRepository<DataJson> {}
