import 'iermes_storage_reserved.dart';

/// Interfaccia per il sistema combinato di storage e caching
abstract class IErmesStorageAndCaching<DataJson>
    extends IErmesStorageAndCachingReserved<DataJson> {
  /// Svuota la cache e salva tutto nello storage persistente
  Future<void> flush();
}
