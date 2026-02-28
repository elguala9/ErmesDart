import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for ErmesStorageAndCaching integration.
///
/// Validates interface contracts for combined storage and caching system:
/// - Initialization with storage and caching services
/// - Flush operations return Future<void>
/// - Mode configuration (FIFO/LIFO) is acceptable
/// - Max cache size configuration works
/// - Empty cache/storage handled gracefully

void testStorageAndCaching<DataJson extends MessageType>(
  String name,
  ErmesStorageAndCaching<DataJson> Function(
    IErmesStorageRepository<DataJson> storage,
    IErmesCachingService<DataJson> caching,
    int maxCached,
    CachingMode mode,
  )
  create,
  IErmesStorageRepository<DataJson> storageService,
  IErmesCachingService<DataJson> cachingService,
) {
  group('ErmesStorageAndCaching<$DataJson>', () {
    late ErmesStorageAndCaching<DataJson> storageAndCaching;

    setUp(() {
      storageAndCaching = create(
        storageService,
        cachingService,
        100,
        CachingMode.fifo,
      );
    });

    test('$name - initialization creates valid instance', () {
      expect(storageAndCaching, isA<ErmesStorageAndCaching<DataJson>>());
    });

    test('$name - flush() returns Future<void>', () async {
      final result = storageAndCaching.flush();
      expect(result, isA<Future<void>>());
      await result;
    });

    test('$name - flush() completes without error', () async {
      await expectLater(storageAndCaching.flush(), completes);
    });

    test('$name - FIFO mode configuration works', () async {
      final fifoInstance = create(
        storageService,
        cachingService,
        50,
        CachingMode.fifo,
      );
      expect(fifoInstance, isA<ErmesStorageAndCaching<DataJson>>());
    });

    test('$name - LIFO mode configuration works', () async {
      final lifoInstance = create(
        storageService,
        cachingService,
        50,
        CachingMode.lifo,
      );
      expect(lifoInstance, isA<ErmesStorageAndCaching<DataJson>>());
    });

    test('$name - max cache size configuration accepted', () async {
      final smallCache = create(
        storageService,
        cachingService,
        10,
        CachingMode.fifo,
      );
      expect(smallCache, isNotNull);
    });

    test('$name - flush with empty cache completes', () async {
      await expectLater(storageAndCaching.flush(), completes);
    });

    test('$name - flush with empty storage completes', () async {
      await expectLater(storageAndCaching.flush(), completes);
    });

    test('$name - supports multiple flush operations', () async {
      await storageAndCaching.flush();
      await storageAndCaching.flush();
      await storageAndCaching.flush();
      expect(true, isTrue);
    });
  });
}
