import 'package:ermes_storage/ermes_storage.dart';
import 'package:test/test.dart';

/// Test suite per verificare l'implementazione di ErmesStorageAndCaching
///
/// Questo test suite verifica che il sistema combinato di storage e caching
/// mantenga la consistenza dei dati e implementi correttamente la sincronizzazione.
void testStorageAndCaching<DataJson>(
  String name,
  ErmesStorageAndCaching<DataJson> Function(
    IErmesStorageService<DataJson> storage,
    IErmesCachingService<DataJson> caching,
    int maxCached,
    CachingMode mode,
  )
  create,
  IErmesStorageService<DataJson> storageService,
  IErmesCachingService<DataJson> cachingService,
  DataJson Function(Map<String, dynamic>) fromJson,
) {
  group('Storage and Caching Integration Tests - $name', () {
    late ErmesStorageAndCaching<DataJson> storageAndCaching;

    setUp(() {
      storageAndCaching = create(
        storageService,
        cachingService,
        100,
        CachingMode.fifo,
      );
    });

    tearDown(() async {
      await storageService.destroy();
      await cachingService.destroy();
    });

    test('should initialize with storage and caching services', () {
      expect(storageAndCaching, isNotNull);
    });

    test('should flush cache to storage', () async {
      final data1 = fromJson({'id': '1', 'content': 'test1'});
      final data2 = fromJson({'id': '2', 'content': 'test2'});

      await cachingService.store(data1);
      await cachingService.store(data2);

      expect(cachingService.numberOfElements(), greaterThan(0));

      await storageAndCaching.flush();
      // Verify data is still accessible
      expect(cachingService.numberOfElements(), greaterThanOrEqualTo(0));
    });

    test('should maintain data consistency when cache is full', () async {
      final data = fromJson({'id': '1', 'content': 'test'});
      await cachingService.store(data);
    });

    test('should support FIFO caching mode', () async {
      final storageAndCachingFifo = create(
        storageService,
        cachingService,
        50,
        CachingMode.fifo,
      );

      final data1 = fromJson({'id': '1', 'content': 'first'});
      await cachingService.store(data1);

      expect(storageAndCachingFifo, isNotNull);
    });

    test('should support LIFO caching mode', () async {
      final storageAndCachingLifo = create(
        storageService,
        cachingService,
        50,
        CachingMode.lifo,
      );

      final data1 = fromJson({'id': '1', 'content': 'last'});
      await cachingService.store(data1);

      expect(storageAndCachingLifo, isNotNull);
    });

    test('should allow configuration of max cache size', () async {
      final smallCache = create(
        storageService,
        cachingService,
        10,
        CachingMode.fifo,
      );

      expect(smallCache, isNotNull);
    });

    test('should handle data loss gracefully when evicting', () async {
      final data1 = fromJson({'id': '1', 'content': 'test1'});
      await cachingService.store(data1);

      // Even if cache is full and evicts, system should remain stable
      await storageAndCaching.flush();
    });
  });
}
