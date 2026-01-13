void main() {
  // TODO: Le interfacce locali di ermes_storage non corrispondono
  // a quelle di iermes. Il test suite di ermes_test attende
  // le interfacce di iermes con MessageType bound, mentre
  // ermes_storage ha interfacce locali senza il bound per
  // supportare Map<String, dynamic>. Una soluzione futura
  // potrebbe essere usare gli adapter o consolidare le
  // interfacce.

  // Caching Repository Tests
  // testCachingRepository<Map<String, dynamic>>(
  //   'ErmesCachingRepository',
  //   (fromJson, toJson) =>
  //       createErmesCachingRepository<Map<String, dynamic>>(),
  //   (json) => json,
  //   (data) => data,
  // );

  // Storage Repository Tests con WorkDb in-memory
  // testStorageRepository<Map<String, dynamic>>(
  //   'ErmesStorageRepository',
  //   (fromJson, toJson) {
  //     final db = WorkDbFactory.createMemory();
  //     return createErmesStorageRepository<Map<String, dynamic>>(db);
  //   },
  //   (json) => json,
  //   (data) => data,
  // );

  // Storage and Caching Tests con WorkDb in-memory
  // testStorageAndCaching<Map<String, dynamic>>(
  //   'ErmesStorageAndCaching',
  //   (storageService, cachingService, maxCached, mode) =>
  //       ErmesStorageAndCaching<Map<String, dynamic>>(
  //         storageService,
  //         cachingService,
  //         maxNumberOfElementCached: maxCached,
  //         cachingMode: mode,
  //       ),
  //   createErmesStorageService<Map<String, dynamic>>(
  //     createErmesStorageRepository<Map<String, dynamic>>(
  //       WorkDbFactory.createMemory(),
  //     ),
  //   ),
  //   createErmesCachingService<Map<String, dynamic>>(),
  //   (json) => json,
  // );
}
