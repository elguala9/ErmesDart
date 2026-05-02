import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

/// Test data model for testing factory method parameter
class TestStorageItem implements StorageType {
  TestStorageItem({
    required this.id,
    required this.content,
    required this.version,
  });

  factory TestStorageItem.fromJson(Map<String, dynamic> json) =>
      TestStorageItem(
        id: json['id'] as int,
        content: json['content'] as String,
        version: json['version'] as int? ?? 1,
      );

  @override
  final int id;
  final String content;
  final int version;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'version': version,
      };

  @override
  Map<String, dynamic> get json => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestStorageItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          version == other.version;

  @override
  int get hashCode => Object.hash(id, content, version);
}

void main() {
  group('ErmesStorageRepository factory method parameter', () {
    late IWorkDb db;

    setUp(() {
      final factory = WorkDbFactory();
      db = factory.create(const MemoryWorkDbFactoryInput());
    });

    test('should work with custom factory method', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final item = TestStorageItem(id: 1, content: 'test', version: 2);
      await repo.store(item);

      final retrieved = await repo.retrieve(1);

      expect(retrieved, isNotNull);
      expect(retrieved?.content, equals('test'));
      expect(retrieved?.version, equals(2));
    });

    test('should correctly deserialize with custom factory', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final original = TestStorageItem(
        id: 42,
        content: 'complex data',
        version: 5,
      );
      await repo.store(original);

      final retrieved = await repo.retrieve(42);

      expect(retrieved, equals(original));
    });

    test('should work with multiple items using factory', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final items = [
        TestStorageItem(id: 1, content: 'item_1', version: 1),
        TestStorageItem(id: 2, content: 'item_2', version: 2),
        TestStorageItem(id: 3, content: 'item_3', version: 3),
      ];

      for (final item in items) {
        await repo.store(item);
      }

      expect(repo.numberOfElements(), equals(3));

      final retrieved = await repo.retrieve(2);
      expect(retrieved?.content, equals('item_2'));
      expect(retrieved?.version, equals(2));
    });

    test('should handle updates with factory method', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final original = TestStorageItem(id: 1, content: 'v1', version: 1);
      await repo.store(original);

      final updated = TestStorageItem(id: 1, content: 'v2', version: 2);
      await repo.store(updated);

      expect(repo.numberOfElements(), equals(1));

      final retrieved = await repo.retrieve(1);
      expect(retrieved?.content, equals('v2'));
      expect(retrieved?.version, equals(2));
    });

    test('should use factory method in service layer', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final service = ErmesStorageService<TestStorageItem>(repo);

      final item = TestStorageItem(id: 1, content: 'service_test', version: 1);
      await service.store(item);

      final retrieved = await service.retrieve(1);

      expect(retrieved?.content, equals('service_test'));
    });

    test('should list all IDs with factory method', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final items = [
        TestStorageItem(id: 10, content: 'a', version: 1),
        TestStorageItem(id: 20, content: 'b', version: 1),
        TestStorageItem(id: 30, content: 'c', version: 1),
      ];

      for (final item in items) {
        await repo.store(item);
      }

      final ids = await repo.listOfIds();
      expect(ids.length, equals(3));
      expect(ids, containsAll([10, 20, 30]));
    });

    test('should delete with factory method', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final item = TestStorageItem(id: 1, content: 'test', version: 1);
      await repo.store(item);

      expect(repo.numberOfElements(), equals(1));

      await repo.delete(1);

      expect(repo.numberOfElements(), equals(0));

      final retrieved = await repo.retrieve(1);
      expect(retrieved, isNull);
    });

    test('should clear with factory method', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final items = [
        TestStorageItem(id: 1, content: 'a', version: 1),
        TestStorageItem(id: 2, content: 'b', version: 1),
      ];

      for (final item in items) {
        await repo.store(item);
      }

      await repo.clear();

      expect(repo.numberOfElements(), equals(0));
      expect(await repo.listOfIds(), isEmpty);
    });

    test('should work with default collection name', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'default_test_collection',
        TestStorageItem.fromJson,
      );

      final item = TestStorageItem(
        id: 1,
        content: 'default_collection',
        version: 1,
      );
      await repo.store(item);

      final retrieved = await repo.retrieve(1);
      expect(retrieved?.content, equals('default_collection'));
    });

    test('should handle complex data types with factory', () async {
      final repo = ErmesStorageRepository<TestStorageItem>(
        db,
        'test_collection',
        TestStorageItem.fromJson,
      );

      final item = TestStorageItem(
        id: 999,
        content: 'complex_!@#_special_^&*()',
        version: 999,
      );

      await repo.store(item);
      final retrieved = await repo.retrieve(999);

      expect(retrieved?.id, equals(999));
      expect(retrieved?.content, equals('complex_!@#_special_^&*()'));
      expect(retrieved?.version, equals(999));
    });
  });

  group('ErmesStorageRepository with MessageRootStorage', () {
    late IWorkDb db;

    setUp(() {
      final factory = WorkDbFactory();
      db = factory.create(const MemoryWorkDbFactoryInput());
    });

    test('should work with MessageRootStorage factory method', () async {
      final repo = ErmesStorageRepository<MessageRootStorage>(
        db,
        'message_test',
        MessageRootStorage.fromJson,
      );

      final item = MessageRootStorage(
        id: 1,
        messageSerialized: Uint8List(0),
        integrityCheckValue: 'test_value',
      );

      await repo.store(item);
      final retrieved = await repo.retrieve(1);

      expect(retrieved, isNotNull);
      expect(retrieved?.id, equals(1));
      expect(retrieved?.integrityCheckValue, equals('test_value'));
    });
  });
}
