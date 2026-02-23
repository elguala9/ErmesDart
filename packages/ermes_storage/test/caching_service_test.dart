import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test data model implementing StorageType
class TestCachingServiceMessage implements StorageType {
  TestCachingServiceMessage({
    required this.id,
    required this.data,
    required this.timestamp,
  });

  factory TestCachingServiceMessage.fromJson(
    Map<String, dynamic> json,
  ) =>
      TestCachingServiceMessage(
        id: json['id'] as int,
        data: json['data'] as String,
        timestamp: json['timestamp'] as int,
      );

  @override
  final int id;
  final String data;
  final int timestamp;

  @override
  Map<String, dynamic> get json => {
        'id': id,
        'data': data,
        'timestamp': timestamp,
      };

  @override
  Map<String, dynamic> toJson({bool includePrivate = false}) => json;

  @override
  String toString() =>
      'TestCachingServiceMessage(id: $id, data: $data, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestCachingServiceMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data &&
          timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ data.hashCode ^ timestamp.hashCode;
}

void main() {
  group('ErmesCachingService', () {
    late ErmesCachingRepository<TestCachingServiceMessage> repository;
    late ErmesCachingService<TestCachingServiceMessage> service;

    setUp(() {
      repository = ErmesCachingRepository<TestCachingServiceMessage>(10);
      service = ErmesCachingService<TestCachingServiceMessage>(repository);
    });

    tearDown(() async {
      await service.destroy();
    });

    group('store()', () {
      test('should delegate store to repository', () async {
        final message = TestCachingServiceMessage(
          id: 1,
          data: 'Test data',
          timestamp: 1000,
        );

        await service.store(message);

        expect(service.numberOfElements(), equals(1));
        final retrieved = await service.retrieve(1);
        expect(retrieved, equals(message));
      });

      test('should store multiple messages', () async {
        final messages = [
          TestCachingServiceMessage(id: 1, data: 'Data 1', timestamp: 1000),
          TestCachingServiceMessage(id: 2, data: 'Data 2', timestamp: 2000),
          TestCachingServiceMessage(id: 3, data: 'Data 3', timestamp: 3000),
        ];

        for (final msg in messages) {
          await service.store(msg);
        }

        expect(service.numberOfElements(), equals(3));
      });

      test('should update existing message', () async {
        final msg1 = TestCachingServiceMessage(
          id: 1,
          data: 'Original',
          timestamp: 1000,
        );
        final msg2 = TestCachingServiceMessage(
          id: 1,
          data: 'Updated',
          timestamp: 2000,
        );

        await service.store(msg1);
        expect(service.numberOfElements(), equals(1));

        await service.store(msg2);
        expect(service.numberOfElements(), equals(1));

        final retrieved = await service.retrieve(1);
        expect(retrieved?.data, equals('Updated'));
      });
    });

    group('retrieve()', () {
      test('should delegate retrieve to repository', () async {
        final message = TestCachingServiceMessage(
          id: 42,
          data: 'Test data',
          timestamp: 5000,
        );

        await service.store(message);
        final retrieved = await service.retrieve(42);

        expect(retrieved, equals(message));
      });

      test('should return null for non-existent message', () async {
        final retrieved = await service.retrieve(999);
        expect(retrieved, isNull);
      });
    });

    group('delete()', () {
      test('should delegate delete to repository', () async {
        final message = TestCachingServiceMessage(
          id: 1,
          data: 'Test',
          timestamp: 1000,
        );

        await service.store(message);
        final deleted = await service.delete(1);

        expect(deleted, isTrue);
        expect(await service.retrieve(1), isNull);
      });

      test('should return false for non-existent message', () async {
        final deleted = await service.delete(999);
        expect(deleted, isFalse);
      });
    });

    group('clear()', () {
      test('should delegate clear to repository', () async {
        for (var i = 1; i <= 5; i++) {
          await service.store(TestCachingServiceMessage(
            id: i,
            data: 'Data $i',
            timestamp: i * 1000,
          ));
        }

        expect(service.numberOfElements(), equals(5));
        await service.clear();
        expect(service.numberOfElements(), equals(0));
      });
    });

    group('listOfIds()', () {
      test('should delegate listOfIds to repository', () async {
        final testIds = [1, 5, 3];
        for (final id in testIds) {
          await service.store(TestCachingServiceMessage(
            id: id,
            data: 'Data $id',
            timestamp: id * 1000,
          ));
        }

        final ids = await service.listOfIds();

        expect(ids.length, equals(3));
        expect(ids.toSet(), equals(testIds.toSet()));
      });

      test('should return empty list for empty cache', () async {
        final ids = await service.listOfIds();
        expect(ids, isEmpty);
      });
    });

    group('numberOfElements()', () {
      test('should delegate numberOfElements to repository', () {
        expect(service.numberOfElements(), equals(0));
      });

      test('should update as messages are added', () async {
        await service.store(TestCachingServiceMessage(
          id: 1,
          data: 'Data 1',
          timestamp: 1000,
        ));

        expect(service.numberOfElements(), equals(1));

        await service.store(TestCachingServiceMessage(
          id: 2,
          data: 'Data 2',
          timestamp: 2000,
        ));

        expect(service.numberOfElements(), equals(2));
      });
    });

    group('destroy()', () {
      test('should delegate destroy to repository', () async {
        for (var i = 1; i <= 5; i++) {
          await service.store(TestCachingServiceMessage(
            id: i,
            data: 'Data $i',
            timestamp: i * 1000,
          ));
        }

        await service.destroy();
        expect(service.numberOfElements(), equals(0));
      });

      test('should allow storing after destroy', () async {
        await service.store(TestCachingServiceMessage(
          id: 1,
          data: 'Before destroy',
          timestamp: 1000,
        ));

        await service.destroy();

        await service.store(TestCachingServiceMessage(
          id: 2,
          data: 'After destroy',
          timestamp: 2000,
        ));

        expect(service.numberOfElements(), equals(1));
        expect(await service.retrieve(2), isNotNull);
      });
    });

    group('caching behavior', () {
      test('should respect buffer size limit', () async {
        repository = ErmesCachingRepository<TestCachingServiceMessage>(3);
        service = ErmesCachingService<TestCachingServiceMessage>(repository);

        for (var i = 1; i <= 5; i++) {
          await service.store(TestCachingServiceMessage(
            id: i,
            data: 'Data $i',
            timestamp: i * 1000,
          ));
        }

        expect(service.numberOfElements(), equals(3));
      });

      test('should evict oldest when adding beyond capacity', () async {
        repository = ErmesCachingRepository<TestCachingServiceMessage>(2);
        service = ErmesCachingService<TestCachingServiceMessage>(repository);

        await service.store(TestCachingServiceMessage(
          id: 1,
          data: 'Data 1',
          timestamp: 1000,
        ));
        await service.store(TestCachingServiceMessage(
          id: 2,
          data: 'Data 2',
          timestamp: 2000,
        ));
        await service.store(TestCachingServiceMessage(
          id: 3,
          data: 'Data 3',
          timestamp: 3000,
        ));

        expect(service.numberOfElements(), equals(2));
        expect(await service.retrieve(1), isNull);
        expect(await service.retrieve(2), isNotNull);
        expect(await service.retrieve(3), isNotNull);
      });
    });

    group('integration', () {
      test('should maintain consistency across multiple operations', () async {
        // Store messages
        for (var i = 1; i <= 5; i++) {
          await service.store(TestCachingServiceMessage(
            id: i,
            data: 'Data $i',
            timestamp: i * 1000,
          ));
        }

        expect(service.numberOfElements(), equals(5));

        // Delete some
        await service.delete(2);
        await service.delete(4);

        expect(service.numberOfElements(), equals(3));

        // Check remaining
        final ids = await service.listOfIds();
        expect(ids.toSet(), equals({1, 3, 5}.toSet()));

        // Clear all
        await service.clear();
        expect(service.numberOfElements(), equals(0));
      });

      test('should handle concurrent operations', () async {
        final operations = <Future<void>>[];

        for (var i = 1; i <= 10; i++) {
          operations.add(service.store(TestCachingServiceMessage(
            id: i,
            data: 'Data $i',
            timestamp: i * 1000,
          )));
        }

        await Future.wait(operations);
        expect(service.numberOfElements(), equals(10));

        final ids = await service.listOfIds();
        expect(ids.length, equals(10));
      });

      test('should handle interleaved operations', () async {
        await service.store(TestCachingServiceMessage(
          id: 1,
          data: 'Data 1',
          timestamp: 1000,
        ));

        await service.delete(1);

        final retrieved = await service.retrieve(1);
        expect(retrieved, isNull);

        await service.store(TestCachingServiceMessage(
          id: 1,
          data: 'Data 1 (new)',
          timestamp: 2000,
        ));

        expect(await service.retrieve(1), isNotNull);
      });
    });
  });
}
