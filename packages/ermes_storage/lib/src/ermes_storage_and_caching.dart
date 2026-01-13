import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// Opzioni configurabili per il servizio di caching
@includeInBarrelFile
class _ErmesCachingServiceOptions {
  _ErmesCachingServiceOptions({
    required this.maxNumberOfElementCached,
    required this.cachingMode,
  });
  final int maxNumberOfElementCached;
  final CachingMode cachingMode;

  _ErmesCachingServiceOptions copyWith({
    int? maxNumberOfElementCached,
    CachingMode? cachingMode,
  }) => _ErmesCachingServiceOptions(
    maxNumberOfElementCached:
        maxNumberOfElementCached ?? this.maxNumberOfElementCached,
    cachingMode: cachingMode ?? this.cachingMode,
  );
}

/// Modalità di caching
@includeInBarrelFile
enum CachingMode { lifo, fifo }

/// Sistema combinato di storage persistente e caching in memoria
@includeInBarrelFile
class ErmesStorageAndCaching<DataJson extends MessageType>
    extends IErmesStorageAndCaching<DataJson> {
  ErmesStorageAndCaching(
    IErmesStorageRepository<DataJson> storageService,
    IErmesCachingService<DataJson> cachingService, {
    int maxNumberOfElementCached = 100,
    CachingMode cachingMode = CachingMode.fifo,
  }) {
    storage = storageService;
    caching = cachingService;
    _opts = _ErmesCachingServiceOptions(
      maxNumberOfElementCached: maxNumberOfElementCached,
      cachingMode: cachingMode,
    );
  }

  late IErmesStorageRepository<DataJson> storage;
  late IErmesCachingService<DataJson> caching;
  late _ErmesCachingServiceOptions _opts;

  @override
  Future<void> flush() async {
    // Ottieni tutti gli ID dalla cache
    final cacheIds = await caching.listOfIds();

    // Per ogni elemento in cache, recuperalo e salvalo nello storage
    for (final id in cacheIds) {
      final cachedItem = await caching.retrieve(id);
      if (cachedItem != null) {
        await storage.store(cachedItem);
      }
    }
  }

  Future<void> _storeInCache(DataJson data) async {
    final maxCacheSize = _opts.maxNumberOfElementCached;
    final currentCacheSize = caching.numberOfElements();

    if (currentCacheSize < maxCacheSize) {
      // La cache ha spazio, salva direttamente
      await caching.store(data);
    } else {
      // La cache è piena, applica la politica di eviction
      await _evictAndStore(data);
    }
  }

  Future<void> _evictAndStore(DataJson data) async {
    final cachingMode = _opts.cachingMode;
    final cacheIds = await caching.listOfIds();

    if (cacheIds.isEmpty) {
      // La cache è vuota, salva direttamente
      await caching.store(data);
      return;
    }

    if (cachingMode == CachingMode.fifo) {
      await _evictFifo(cacheIds);
    } else if (cachingMode == CachingMode.lifo) {
      await _evictLifo(cacheIds);
    }

    await caching.store(data);
  }

  Future<void> _evictFifo(List<IdType> cacheIds) async {
    // FIFO: Rimuovi l'elemento più vecchio (primo inserito)
    final oldestId = cacheIds.first;
    await caching.delete(oldestId);
  }

  Future<void> _evictLifo(List<IdType> cacheIds) async {
    // LIFO: Rimuovi l'elemento più nuovo (ultimo inserito)
    final newestId = cacheIds.last;
    await caching.delete(newestId);
  }

  @override
  Future<void> store(DataJson data) async {
    // Salva sempre nello storage persistente per primo
    await storage.store(data);

    // Poi gestisci il caching con le politiche di eviction
    await _storeInCache(data);
  }

  @override
  Future<DataJson?> retrieve(IdType id) async {
    // Prova la cache per prima (più veloce)
    var result = await caching.retrieve(id);

    if (result != null) {
      return result;
    }

    // Se non in cache, prova lo storage persistente
    result = await storage.retrieve(id);

    if (result != null) {
      // Salva in cache per i recuperi futuri
      await caching.store(result);
    }

    return result;
  }

  @override
  Future<bool> delete(IdType id) async {
    // Elimina da cache e storage persistente in parallelo
    final results = await Future.wait<bool>([
      caching.delete(id),
      storage.delete(id),
    ]);

    return results[0] && results[1];
  }

  @override
  Future<void> clear() async {
    // Pulisci cache e storage persistente
    await Future.wait<void>([caching.clear(), storage.clear()]);
  }

  @override
  int numberOfElements() => storage.numberOfElements();

  @override
  Future<List<int>> listOfIds() async {
    // Ritorna gli ID dallo storage persistente (fonte autorevole)
    final results = await Future.wait<List<IdType>>([
      storage.listOfIds(),
      caching.listOfIds(),
    ]);

    final storageIds = results[0];
    final cacheIds = results[1];

    // Combina gli array e assicura unicità
    final combined = <int>{...storageIds, ...cacheIds};
    return combined.toList();
  }

  @override
  Future<void> destroy() async {
    // Distruggi cache e storage
    await flush();
    await Future.wait<void>([caching.destroy(), storage.destroy()]);
  }
}
