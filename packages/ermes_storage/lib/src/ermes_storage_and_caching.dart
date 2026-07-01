import 'package:iermes/iermes.dart';

import 'cache_eviction_strategy.dart';
import 'caching_mode.dart';

export 'caching_mode.dart' show CachingMode;

/// Combines persistent storage with an in-memory cache, reading from cache
/// first and falling back to storage, while applying an eviction strategy.
class ErmesStorageAndCaching<DataJson extends StorageType>
    extends IErmesStorageAndCaching<DataJson> {
  /// Creates a combined storage/caching layer with the given services and
  /// cache size/eviction configuration.
  ErmesStorageAndCaching(
    IErmesStorageRepository<DataJson> storageService,
    IErmesCachingService<DataJson> cachingService, {
    int maxNumberOfElementCached = 100,
    CachingMode cachingMode = CachingMode.fifo,
  }) {
    storage = storageService;
    caching = cachingService;
    final opts = ErmesCachingServiceOptions(
      maxNumberOfElementCached: maxNumberOfElementCached,
      cachingMode: cachingMode,
    );
    _eviction = CacheEvictionStrategy<DataJson>(cachingService, opts);
  }

  /// The persistent storage backend.
  late IErmesStorageRepository<DataJson> storage;
  /// The in-memory cache layer.
  late IErmesCachingService<DataJson> caching;
  late CacheEvictionStrategy<DataJson> _eviction;

  /// Persists all currently cached items to storage.
  @override
  Future<void> flush() async {
    final cacheIds = await caching.listOfIds();
    for (final id in cacheIds) {
      final cachedItem = await caching.retrieve(id);
      if (cachedItem != null) {
        await storage.store(cachedItem);
      }
    }
  }

  /// Stores [data] in persistent storage and adds it to the cache.
  @override
  Future<void> store(DataJson data) async {
    await storage.store(data);
    await _eviction.storeInCache(data);
  }

  /// Retrieves the item for [id], checking the cache before storage and
  /// populating the cache on a storage hit.
  @override
  Future<DataJson?> retrieve(IdType id) async {
    var result = await caching.retrieve(id);
    if (result != null) {
      return result;
    }

    result = await storage.retrieve(id);
    if (result != null) {
      await caching.store(result);
    }
    return result;
  }

  /// Deletes the item for [id] from both cache and storage.
  @override
  Future<bool> delete(IdType id) async {
    final results = await Future.wait<bool>([
      caching.delete(id),
      storage.delete(id),
    ]);
    return results[0] && results[1];
  }

  /// Clears both the cache and persistent storage.
  @override
  Future<void> clear() async {
    await Future.wait<void>([caching.clear(), storage.clear()]);
  }

  /// Returns the number of items in persistent storage.
  @override
  int numberOfElements() => storage.numberOfElements();

  /// Returns the union of IDs held in storage and cache.
  @override
  Future<List<int>> listOfIds() async {
    final results = await Future.wait<List<IdType>>([
      storage.listOfIds(),
      caching.listOfIds(),
    ]);
    final combined = <int>{...results[0], ...results[1]};
    return combined.toList();
  }

  /// Flushes cached items to storage, then destroys both layers.
  @override
  Future<void> destroy() async {
    await flush();
    await Future.wait<void>([caching.destroy(), storage.destroy()]);
  }
}
