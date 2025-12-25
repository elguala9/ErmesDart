import 'iermes_storage_reserved.dart';

/// Repository che gestisce lo storage dei messaggi,
/// sia ricevuti che inviati
abstract class IErmesStorageRepository<DataJson>
    extends IErmesStorageAndCachingReserved<DataJson> {}

/// Service che gestisce lo storage dei messaggi,
/// sia ricevuti che inviati
abstract class IErmesStorageService<DataJson>
    extends IErmesStorageRepository<DataJson> {}
