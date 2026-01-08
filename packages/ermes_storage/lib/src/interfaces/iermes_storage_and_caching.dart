import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'iermes_storage_reserved.dart';

/// Interfaccia per il sistema combinato di storage e caching
@includeInBarrelFile
abstract class IErmesStorageAndCaching<DataJson>
    extends IErmesStorageAndCachingReserved<DataJson> {
  /// Svuota la cache e salva tutto nello storage persistente
  Future<void> flush();
}
