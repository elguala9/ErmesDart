import '../caching_implementation/ermes_caching_repository.dart';
import '../caching_implementation/ermes_caching_service.dart';
import '../ermes_storage_and_caching.dart';
import '../interfaces/iermes_storage_and_caching.dart';
import 'ermes_caching_factories.dart';
import 'ermes_storage_factories.dart';

/// Crea un sistema combinato di storage e caching
IErmesStorageAndCaching<T> createErmesStorageAndCaching<T>(
  dynamic db, {
  String collection = "ermes_messages",
  int maxNumberOfElementCached = 100,
  CachingMode cachingMode = CachingMode.fifo,
}) {
  // Crea il repository e il service di storage
  final storageRepo = createErmesStorageRepository<T>(db, collection: collection);
  final storageService = createErmesStorageService<T>(storageRepo);

  // Crea il repository e il service di caching
  final cachingRepo = ErmesCachingRepository<T>(maxNumberOfElementCached);
  final cachingService = ErmesCachingService<T>(cachingRepo);

  // Crea e ritorna il sistema combinato di storage e caching
  return ErmesStorageAndCaching<T>(
    storageService,
    cachingService,
    maxNumberOfElementCached: maxNumberOfElementCached,
    cachingMode: cachingMode,
  );
}
