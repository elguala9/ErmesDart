import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

// ---------------------------------------------------------------------------
// Real, minimal StorageType used by the persistence tests.
// ---------------------------------------------------------------------------

class _PersistMsg implements StorageType {
  const _PersistMsg({required this.id, required this.content});

  factory _PersistMsg.fromJson(Map<String, dynamic> json) => _PersistMsg(
        id: json['id'] as int,
        content: json['content'] as String,
      );

  @override
  final int id;
  final String content;

  @override
  Map<String, dynamic> get json => {'id': id, 'content': content};

  @override
  Map<String, dynamic> toJson({bool includePrivate = false}) => json;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PersistMsg && id == other.id && content == other.content;

  @override
  int get hashCode => Object.hash(id, content);
}

ErmesStorageRepository<_PersistMsg> _repo(IWorkDb db, String collection) =>
    ErmesStorageRepository<_PersistMsg>(
      db,
      collection,
      _PersistMsg.fromJson,
    );

/// Verifies that data written through the storage layer survives and is
/// retrievable, including through a freshly built repository over the same
/// backing store, and that deletions and overwrites persist.
void testStoragePersistence() {
  group('ErmesStorageRepository persistence', () {
    late IWorkDb db;
    var counter = 0;
    late String collection;

    setUp(() {
      db = WorkDb.memory();
      counter++;
      collection = 'persist_$counter';
    });

    group('read-back persistence', () {
      test('stored data is retrievable from the same repository', () async {
        final repo = _repo(db, collection);
        await repo.store(const _PersistMsg(id: 1, content: 'alpha'));

        final result = await repo.retrieve(1);
        expect(result, isNotNull);
        expect(result?.id, equals(1));
        expect(result?.content, equals('alpha'));
      });

      test('stored data is retrievable via a fresh repository instance over '
          'the same backing store', () async {
        final writer = _repo(db, collection);
        await writer.store(const _PersistMsg(id: 2, content: 'beta'));
        await writer.store(const _PersistMsg(id: 3, content: 'gamma'));

        // A brand new repository pointed at the same db and collection.
        final reader = _repo(db, collection);

        expect((await reader.retrieve(2))?.content, equals('beta'));
        expect((await reader.retrieve(3))?.content, equals('gamma'));
      });

      test('all ids are listable after multiple stores', () async {
        final repo = _repo(db, collection);
        for (var i = 0; i < 5; i++) {
          await repo.store(_PersistMsg(id: i, content: 'msg$i'));
        }

        final ids = await repo.listOfIds();
        ids.sort();
        expect(ids, equals(<int>[0, 1, 2, 3, 4]));
        expect(repo.numberOfElements(), equals(5));
      });

      test('listOfIds is visible from a fresh repository instance', () async {
        final writer = _repo(db, collection);
        for (var i = 10; i < 13; i++) {
          await writer.store(_PersistMsg(id: i, content: 'm$i'));
        }

        final reader = _repo(db, collection);
        final ids = await reader.listOfIds();
        ids.sort();
        expect(ids, equals(<int>[10, 11, 12]));
      });
    });

    group('overwrite persistence', () {
      test('overwriting an id keeps the latest value', () async {
        final repo = _repo(db, collection);
        await repo.store(const _PersistMsg(id: 1, content: 'first'));
        await repo.store(const _PersistMsg(id: 1, content: 'second'));

        expect((await repo.retrieve(1))?.content, equals('second'));
      });

      test('overwrite does not increase the element count', () async {
        final repo = _repo(db, collection);
        await repo.store(const _PersistMsg(id: 1, content: 'a'));
        await repo.store(const _PersistMsg(id: 1, content: 'b'));
        await repo.store(const _PersistMsg(id: 1, content: 'c'));

        expect(repo.numberOfElements(), equals(1));
      });

      test('overwrite is visible from a fresh repository instance', () async {
        final writer = _repo(db, collection);
        await writer.store(const _PersistMsg(id: 7, content: 'old'));
        await writer.store(const _PersistMsg(id: 7, content: 'new'));

        final reader = _repo(db, collection);
        expect((await reader.retrieve(7))?.content, equals('new'));
      });
    });

    group('deletion persistence', () {
      test('a deleted entry stays deleted', () async {
        final repo = _repo(db, collection);
        await repo.store(const _PersistMsg(id: 4, content: 'doomed'));

        expect(await repo.delete(4), isTrue);
        expect(await repo.retrieve(4), isNull);
      });

      test('deletion is visible from a fresh repository instance', () async {
        final writer = _repo(db, collection);
        await writer.store(const _PersistMsg(id: 8, content: 'x'));
        await writer.store(const _PersistMsg(id: 9, content: 'y'));
        expect(await writer.delete(8), isTrue);

        final reader = _repo(db, collection);
        expect(await reader.retrieve(8), isNull);
        expect((await reader.retrieve(9))?.content, equals('y'));
      });

      test('deleting an unknown id returns false and persists nothing',
          () async {
        final repo = _repo(db, collection);
        await repo.store(const _PersistMsg(id: 1, content: 'keep'));

        expect(await repo.delete(999), isFalse);
        expect((await repo.retrieve(1))?.content, equals('keep'));
      });

      test('clear removes everything and persists the empty state', () async {
        final writer = _repo(db, collection);
        for (var i = 0; i < 3; i++) {
          await writer.store(_PersistMsg(id: i, content: 'msg$i'));
        }
        await writer.clear();

        final reader = _repo(db, collection);
        expect(await reader.listOfIds(), isEmpty);
        expect(await reader.retrieve(0), isNull);
      });
    });

    group('collection isolation under persistence', () {
      test('data in one collection is invisible to another collection',
          () async {
        final repoA = _repo(db, '${collection}_a');
        final repoB = _repo(db, '${collection}_b');

        await repoA.store(const _PersistMsg(id: 1, content: 'only-in-a'));

        expect((await repoA.retrieve(1))?.content, equals('only-in-a'));
        expect(await repoB.retrieve(1), isNull);
      });
    });
  });
}

void main() => testStoragePersistence();
