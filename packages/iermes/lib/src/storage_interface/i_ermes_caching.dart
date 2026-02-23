import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Interface for message caching
///
/// Caching typically stores messages temporarily in memory for quick access.
/// This is useful for recently sent or received messages.
@includeInBarrelFile
abstract class IErmesCachingRepository<DataJson>
    implements IErmesStorageAndCachingReserved<DataJson> {}

/// Service interface for message caching
///
/// Provides the same caching functionality at the service layer.
@includeInBarrelFile
abstract class IErmesCachingService<DataJson>
    implements IErmesCachingRepository<DataJson> {}
