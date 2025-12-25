import 'iermes_storage_reserved.dart';

/// Repository che gestisce il caching dei messaggi,
/// sia ricevuti che inviati
abstract class IErmesCachingRepository<DataJson>
    extends IErmesStorageAndCachingReserved<DataJson> {}

/// Service che gestisce il caching dei messaggi,
/// sia ricevuti che inviati
abstract class IErmesCachingService<DataJson>
    extends IErmesCachingRepository<DataJson> {}
