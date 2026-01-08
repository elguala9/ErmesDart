import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'iermes_storage_reserved.dart';

/// Repository che gestisce il caching dei messaggi,
/// sia ricevuti che inviati
@includeInBarrelFile
abstract class IErmesCachingRepository<DataJson>
    extends IErmesStorageAndCachingReserved<DataJson> {}

/// Service che gestisce il caching dei messaggi,
/// sia ricevuti che inviati
@includeInBarrelFile
abstract class IErmesCachingService<DataJson>
    extends IErmesCachingRepository<DataJson> {}
