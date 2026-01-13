import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'iermes_storage_reserved.dart';

/// Repository che gestisce lo storage dei messaggi,
/// sia ricevuti che inviati
///
/// Nota: Questo è un'interfaccia locale (non da iermes) per supportare
/// tipi di dato arbitrari come Map<String, dynamic> nei test
@includeInBarrelFile
abstract class IErmesStorageRepository<DataJson>
    extends IErmesStorageAndCachingReserved<DataJson> {}

/// Service che gestisce lo storage dei messaggi,
/// sia ricevuti che inviati
@includeInBarrelFile
abstract class IErmesStorageService<DataJson>
    extends IErmesStorageRepository<DataJson> {}
