import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'iermes_storage_reserved.dart';

/// Repository che gestisce lo storage dei messaggi,
/// sia ricevuti che inviati
@includeInBarrelFile
abstract class IErmesStorageRepository<DataJson>
    extends IErmesStorageAndCachingReserved<DataJson> {}

/// Service che gestisce lo storage dei messaggi,
/// sia ricevuti che inviati
@includeInBarrelFile
abstract class IErmesStorageService<DataJson>
    extends IErmesStorageRepository<DataJson> {}
