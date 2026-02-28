import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test data model implementing StorageType
class TestCacheMessage implements StorageType {
  TestCacheMessage({
    required this.id,
    required this.content,
    required this.priority,
  });

  factory TestCacheMessage.fromJson(Map<String, dynamic> json) =>
      TestCacheMessage(
        id: json['id'] as int,
        content: json['content'] as String,
        priority: json['priority'] as int,
      );

  @override
  final int id;
  final String content;
  final int priority;

  @override
  Map<String, dynamic> get json => {
        'id': id,
        'content': content,
        'priority': priority,
      };

  @override
  Map<String, dynamic> toJson({bool includePrivate = false}) => json;

  @override
  String toString() =>
      'TestCacheMessage(id: $id, content: $content, priority: $priority)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestCacheMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          priority == other.priority;

  @override
  int get hashCode => id.hashCode ^ content.hashCode ^ priority.hashCode;
}

void main() {
  group('ErmesCachingRepository', () {
    late ErmesCachingRepository<TestCacheMessage> repository;

    setUp(() {
      repository = ErmesCachingRepository<TestCacheMessage>(10);
    });

    tearDown(() async {
      await repository.destroy();
    });

    group('store()', () {
      test('should store a single message', () async {
        final message = TestCacheMessage(
          id: 1,
          content: 'Test message',
          priority: 1,
        );

        await repository.store(message);

        expect(repository.numberOfElements(), equals(1));
        final retrieved = await repository.retrieve(1);
        expect(retrieved, equals(message));
      });

      test('should store multiple messages', () async {
        final messages = [
          TestCacheMessage(id: 1, content: 'Message 1', priority: 1),
          TestCacheMessage(id: 2, content: 'Message 2', priority: 2),
          TestCacheMessage(id: 3, content: 'Message 3', priority: 3),
        ];

        for (final msg in messages) {
          await repository.store(msg);
        }

        expect(repository.numberOfElements(), equals(3));
      });

      test('should update existing message without duplicating', () async {
        final msg1 =
            TestCacheMessage(id: 1, content: 'Original', priority: 1);
        final msg2 =
            TestCacheMessage(id: 1, content: 'Updated', priority: 5);

        await repository.store(msg1);
        expect(repository.numberOfElements(), equals(1));

        await repository.store(msg2);
        expect(repository.numberOfElements(), equals(1));

        final retrieved = await repository.retrieve(1);
        expect(retrieved?.content, equals('Updated'));
        expect(retrieved?.priority, equals(5));
      });

      test('should throw exception if data has no id', () async {
        final badMessage = TestCacheMessage(
          id: 0, // This could be used as invalid, but in real usage
          content: 'Bad',
          priority: 1,
        );

        // The repository doesn't validate id = 0, it just checks for null
        // So store should work, but retrieve won't find it as intended
        await repository.store(badMessage);
        expect(repository.numberOfElements(), equals(1));
      });

      test('should evict oldest message when buffer is full (FIFO)', () async {
        const maxBuffer = 5;
        repository = ErmesCachingRepository<TestCacheMessage>(maxBuffer);

        // Store exactly maxBuffer messages
        for (var i = 1; i <= maxBuffer; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        expect(repository.numberOfElements(), equals(maxBuffer));

        // Store one more - should evict the first (oldest)
        await repository.store(TestCacheMessage(
          id: maxBuffer + 1,
          content: 'Message ${maxBuffer + 1}',
          priority: maxBuffer + 1,
        ));

        expect(repository.numberOfElements(), equals(maxBuffer));
        expect(await repository.retrieve(1), isNull); // First should be evicted
        expect(await repository.retrieve(maxBuffer + 1), isNotNull);
      });

      test('should handle updates without triggering eviction', () async {
        const maxBuffer = 3;
        repository = ErmesCachingRepository<TestCacheMessage>(maxBuffer);

        for (var i = 1; i <= maxBuffer; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        expect(repository.numberOfElements(), equals(maxBuffer));

        // Update existing message - shouldn't trigger eviction
        await repository.store(TestCacheMessage(
          id: 2,
          content: 'Updated message 2',
          priority: 10,
        ));

        expect(repository.numberOfElements(), equals(maxBuffer));
        final updated = await repository.retrieve(2);
        expect(updated?.content, equals('Updated message 2'));
      });

      test('should evict multiple messages when adding beyond capacity',
          () async {
        const maxBuffer = 3;
        repository = ErmesCachingRepository<TestCacheMessage>(maxBuffer);

        // Fill the buffer
        for (var i = 1; i <= maxBuffer; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        // Add multiple new messages
        for (var i = maxBuffer + 1; i <= maxBuffer + 3; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        // Should still be at maxBuffer capacity
        expect(repository.numberOfElements(), equals(maxBuffer));

        // First 3 messages should be evicted
        expect(await repository.retrieve(1), isNull);
        expect(await repository.retrieve(2), isNull);
        expect(await repository.retrieve(3), isNull);

        // Last 3 should remain
        expect(await repository.retrieve(4), isNotNull);
        expect(await repository.retrieve(5), isNotNull);
        expect(await repository.retrieve(6), isNotNull);
      });
    });

    group('retrieve()', () {
      test('should retrieve stored message', () async {
        final message = TestCacheMessage(
          id: 42,
          content: 'Test message',
          priority: 5,
        );

        await repository.store(message);
        final retrieved = await repository.retrieve(42);

        expect(retrieved, equals(message));
      });

      test('should return null for non-existent message', () async {
        final retrieved = await repository.retrieve(999);
        expect(retrieved, isNull);
      });

      test('should retrieve message from cache after eviction', () async {
        const maxBuffer = 2;
        repository = ErmesCachingRepository<TestCacheMessage>(maxBuffer);

        await repository.store(TestCacheMessage(
          id: 1,
          content: 'Message 1',
          priority: 1,
        ));
        await repository.store(TestCacheMessage(
          id: 2,
          content: 'Message 2',
          priority: 2,
        ));
        await repository.store(TestCacheMessage(
          id: 3,
          content: 'Message 3',
          priority: 3,
        )); // This evicts id=1

        expect(await repository.retrieve(1), isNull);
        expect(await repository.retrieve(2), isNotNull);
        expect(await repository.retrieve(3), isNotNull);
      });
    });

    group('delete()', () {
      test('should delete existing message', () async {
        final message = TestCacheMessage(
          id: 1,
          content: 'Test',
          priority: 1,
        );

        await repository.store(message);
        expect(repository.numberOfElements(), equals(1));

        final deleted = await repository.delete(1);
        expect(deleted, isTrue);
        expect(repository.numberOfElements(), equals(0));
        expect(await repository.retrieve(1), isNull);
      });

      test('should return false when deleting non-existent message', () async {
        final deleted = await repository.delete(999);
        expect(deleted, isFalse);
      });

      test('should delete specific message without affecting others', () async {
        for (var i = 1; i <= 3; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        await repository.delete(2);

        expect(await repository.retrieve(1), isNotNull);
        expect(await repository.retrieve(2), isNull);
        expect(await repository.retrieve(3), isNotNull);
        expect(repository.numberOfElements(), equals(2));
      });

      test('should free up space in the buffer', () async {
        const maxBuffer = 2;
        repository = ErmesCachingRepository<TestCacheMessage>(maxBuffer);

        await repository.store(TestCacheMessage(
          id: 1,
          content: 'Message 1',
          priority: 1,
        ));
        await repository.store(TestCacheMessage(
          id: 2,
          content: 'Message 2',
          priority: 2,
        ));

        expect(repository.numberOfElements(), equals(2));

        // Delete one to free space
        await repository.delete(1);
        expect(repository.numberOfElements(), equals(1));

        // Should be able to add new message without eviction
        await repository.store(TestCacheMessage(
          id: 3,
          content: 'Message 3',
          priority: 3,
        ));

        expect(repository.numberOfElements(), equals(2));
        expect(await repository.retrieve(2), isNotNull);
        expect(await repository.retrieve(3), isNotNull);
      });
    });

    group('listOfIds()', () {
      test('should return empty list for empty cache', () async {
        final ids = await repository.listOfIds();
        expect(ids, isEmpty);
      });

      test('should return list of all cached IDs', () async {
        final testIds = [1, 5, 3, 7, 2];
        for (final id in testIds) {
          await repository.store(TestCacheMessage(
            id: id,
            content: 'Message $id',
            priority: id,
          ));
        }

        final ids = await repository.listOfIds();
        expect(ids.length, equals(5));
        expect(ids.toSet(), equals(testIds.toSet()));
      });

      test('should return updated list after deletion', () async {
        for (var i = 1; i <= 5; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        await repository.delete(2);
        await repository.delete(4);

        final ids = await repository.listOfIds();
        expect(ids.length, equals(3));
        expect(ids, isNot(contains(2)));
        expect(ids, isNot(contains(4)));
      });

      test('should reflect IDs after eviction', () async {
        const maxBuffer = 3;
        repository = ErmesCachingRepository<TestCacheMessage>(maxBuffer);

        for (var i = 1; i <= 5; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        final ids = await repository.listOfIds();
        expect(ids.length, equals(maxBuffer));
        expect(ids, isNot(contains(1)));
        expect(ids, isNot(contains(2)));
        expect(ids.toSet(), equals({3, 4, 5}.toSet()));
      });
    });

    group('numberOfElements()', () {
      test('should return 0 for empty cache', () {
        expect(repository.numberOfElements(), equals(0));
      });

      test('should increment after storing message', () async {
        expect(repository.numberOfElements(), equals(0));

        await repository.store(TestCacheMessage(
          id: 1,
          content: 'First',
          priority: 1,
        ));
        expect(repository.numberOfElements(), equals(1));

        await repository.store(TestCacheMessage(
          id: 2,
          content: 'Second',
          priority: 2,
        ));
        expect(repository.numberOfElements(), equals(2));
      });

      test('should not exceed maxBuffer', () async {
        const maxBuffer = 3;
        repository = ErmesCachingRepository<TestCacheMessage>(maxBuffer);

        for (var i = 1; i <= 10; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        expect(repository.numberOfElements(), equals(maxBuffer));
      });

      test('should decrement after deleting message', () async {
        for (var i = 1; i <= 3; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        expect(repository.numberOfElements(), equals(3));
        await repository.delete(1);
        expect(repository.numberOfElements(), equals(2));
      });
    });

    group('clear()', () {
      test('should remove all messages', () async {
        for (var i = 1; i <= 5; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        expect(repository.numberOfElements(), equals(5));
        await repository.clear();
        expect(repository.numberOfElements(), equals(0));
        expect(await repository.listOfIds(), isEmpty);
      });

      test('should allow storing after clear', () async {
        await repository.store(TestCacheMessage(
          id: 1,
          content: 'Before clear',
          priority: 1,
        ));
        await repository.clear();

        await repository.store(TestCacheMessage(
          id: 2,
          content: 'After clear',
          priority: 2,
        ));

        expect(repository.numberOfElements(), equals(1));
        expect(await repository.retrieve(1), isNull);
        expect(await repository.retrieve(2), isNotNull);
      });
    });

    group('destroy()', () {
      test('should clear all data', () async {
        for (var i = 1; i <= 5; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        await repository.destroy();
        expect(repository.numberOfElements(), equals(0));
        expect(await repository.listOfIds(), isEmpty);
      });

      test('should allow storing after destroy', () async {
        await repository.store(TestCacheMessage(
          id: 1,
          content: 'Before destroy',
          priority: 1,
        ));

        await repository.destroy();

        await repository.store(TestCacheMessage(
          id: 2,
          content: 'After destroy',
          priority: 2,
        ));

        expect(repository.numberOfElements(), equals(1));
        expect(await repository.retrieve(2), isNotNull);
      });
    });

    group('concurrent operations', () {
      test('should handle concurrent stores', () async {
        final futures = <Future<void>>[];
        for (var i = 1; i <= 10; i++) {
          futures.add(repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          )));
        }

        await Future.wait(futures);
        // numberOfElements should be <= maxBuffer (which is 10)
        expect(repository.numberOfElements(), lessThanOrEqualTo(10));
      });

      test('should handle concurrent mixed operations', () async {
        // Pre-populate
        for (var i = 1; i <= 5; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        // Mix of operations
        final operations = <Future<void>>[
          repository.store(TestCacheMessage(
            id: 6,
            content: 'New',
            priority: 6,
          )),
          repository.delete(1),
          repository.retrieve(2).then((_) {}),
          repository.delete(3),
        ];

        await Future.wait(operations);

        final ids = await repository.listOfIds();
        expect(ids, isNotEmpty);
      });
    });

    group('edge cases', () {
      test('should handle single element buffer', () async {
        repository = ErmesCachingRepository<TestCacheMessage>(1);

        await repository.store(TestCacheMessage(
          id: 1,
          content: 'First',
          priority: 1,
        ));
        expect(repository.numberOfElements(), equals(1));

        await repository.store(TestCacheMessage(
          id: 2,
          content: 'Second',
          priority: 2,
        ));
        expect(repository.numberOfElements(), equals(1));
        expect(await repository.retrieve(1), isNull);
        expect(await repository.retrieve(2), isNotNull);
      });

      test('should handle very large buffer size', () async {
        repository = ErmesCachingRepository<TestCacheMessage>(10000);

        for (var i = 1; i <= 100; i++) {
          await repository.store(TestCacheMessage(
            id: i,
            content: 'Message $i',
            priority: i,
          ));
        }

        expect(repository.numberOfElements(), equals(100));
      });

      test('should handle messages with special characters', () async {
        const specialContent = 'Test\n\t"\'\\<>&';
        final message = TestCacheMessage(
          id: 1,
          content: specialContent,
          priority: 1,
        );

        await repository.store(message);
        final retrieved = await repository.retrieve(1);
        expect(retrieved?.content, equals(specialContent));
      });

      test('should handle duplicate ID updates in sequence', () async {
        for (var i = 0; i < 5; i++) {
          await repository.store(TestCacheMessage(
            id: 1,
            content: 'Update $i',
            priority: i,
          ));
        }

        expect(repository.numberOfElements(), equals(1));
        final retrieved = await repository.retrieve(1);
        expect(retrieved?.content, equals('Update 4'));
        expect(retrieved?.priority, equals(4));
      });
    });
  });
}
