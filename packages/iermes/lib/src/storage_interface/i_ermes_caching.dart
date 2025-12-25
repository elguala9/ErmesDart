import 'package:ermes_types/ermes_types.dart';

import 'i_ermes_storage_reserved.dart';

/// Interface for message caching
///
/// Caching typically stores messages temporarily in memory for quick access.
/// This is useful for recently sent or received messages.
abstract class IErmesCachingRepository<DataJson extends MessageType>
    implements IErmesStorageAndCachingReserved<DataJson> {}

/// Service interface for message caching
///
/// Provides the same caching functionality at the service layer.
abstract class IErmesCachingService<DataJson extends MessageType>
    implements IErmesCachingRepository<DataJson> {}
