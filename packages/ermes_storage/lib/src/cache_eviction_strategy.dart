import 'package:iermes/iermes.dart';

import 'caching_mode.dart';

class CacheEvictionStrategy<DataJson extends StorageType> {
  CacheEvictionStrategy(this._caching, this._opts);

  final IErmesCachingService<DataJson> _caching;
  final ErmesCachingServiceOptions _opts;

  Future<void> storeInCache(DataJson data) async {
    final maxCacheSize = _opts.maxNumberOfElementCached;
    final currentCacheSize = _caching.numberOfElements();

    if (currentCacheSize < maxCacheSize) {
      await _caching.store(data);
    } else {
      await _evictAndStore(data);
    }
  }

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
