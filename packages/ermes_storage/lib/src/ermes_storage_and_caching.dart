import 'package:iermes/iermes.dart';

import 'cache_eviction_strategy.dart';
import 'caching_mode.dart';

export 'caching_mode.dart' show CachingMode;

class ErmesStorageAndCaching<DataJson extends StorageType>
    extends IErmesStorageAndCaching<DataJson> {
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

  late IErmesStorageRepository<DataJson> storage;
  late IErmesCachingService<DataJson> caching;
  late CacheEvictionStrategy<DataJson> _eviction;

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

  @override
  Future<void> store(DataJson data) async {
    await storage.store(data);
    await _eviction.storeInCache(data);
  }

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

  @override
  Future<bool> delete(IdType id) async {
    final results = await Future.wait<bool>([
      caching.delete(id),
      storage.delete(id),
    ]);
    return results[0] && results[1];
  }

  @override
  Future<void> clear() async {
    await Future.wait<void>([caching.clear(), storage.clear()]);
  }

  @override
  int numberOfElements() => storage.numberOfElements();

  @override
  Future<List<int>> listOfIds() async {
    final results = await Future.wait<List<IdType>>([
      storage.listOfIds(),
      caching.listOfIds(),
    ]);
    final combined = <int>{...results[0], ...results[1]};
    return combined.toList();
  }

  @override
  Future<void> destroy() async {
    await flush();
    await Future.wait<void>([caching.destroy(), storage.destroy()]);
  }
}
