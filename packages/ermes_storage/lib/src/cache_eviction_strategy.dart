import 'package:iermes/iermes.dart';

import 'caching_mode.dart';

/// Applies the configured eviction policy when storing items into the cache,
/// removing the oldest or newest entries once the maximum size is reached.
class CacheEvictionStrategy<DataJson extends StorageType> {
  /// Creates a strategy bound to a caching service and its options.
  CacheEvictionStrategy(this._caching, this._opts);

  /// The caching service the eviction operates on.
  final IErmesCachingService<DataJson> _caching;
  /// Options controlling the maximum size and eviction mode.
  final ErmesCachingServiceOptions _opts;

  /// Stores [data] in the cache, evicting an entry first if the cache is full.
  Future<void> storeInCache(DataJson data) async {
    final maxCacheSize = _opts.maxNumberOfElementCached;
    final currentCacheSize = _caching.numberOfElements();

    if (currentCacheSize < maxCacheSize) {
      await _caching.store(data);
    } else {
      await _evictAndStore(data);
    }
  }

  /// Evicts one entry according to the caching mode, then stores [data].
  Future<void> _evictAndStore(DataJson data) async {
    final cacheIds = await _caching.listOfIds();

    if (cacheIds.isEmpty) {
      await _caching.store(data);
      return;
    }

    switch (_opts.cachingMode) {
      case CachingMode.fifo:
        await _caching.delete(cacheIds.first);
      case CachingMode.lifo:
        await _caching.delete(cacheIds.last);
    }

    await _caching.store(data);
  }
}
