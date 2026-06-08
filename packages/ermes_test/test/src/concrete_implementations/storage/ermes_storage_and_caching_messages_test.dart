import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

// ---------------------------------------------------------------------------
// Test data model
// ---------------------------------------------------------------------------

class _TestMsg implements StorageType {
  const _TestMsg({required this.id, required this.content});

  factory _TestMsg.fromJson(Map<String, dynamic> json) =>
      _TestMsg(id: json['id'] as int, content: json['content'] as String);

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
      other is _TestMsg && id == other.id && content == other.content;

  @override
  int get hashCode => Object.hash(id, content);
}

// ---------------------------------------------------------------------------
// Factory helper
// ---------------------------------------------------------------------------

ErmesStorageAndCachingMessages<_TestMsg> _makeMessages({int maxCached = 100}) =>
    ErmesStorageAndCachingMessages<_TestMsg>(
      ErmesStorageRepository<_TestMsg>(
        WorkDb.memory(),
        ErmesStorageRepository.defaultCollection,
        _TestMsg.fromJson,
      ),
      ErmesCachingService<_TestMsg>(
        ErmesCachingRepository<_TestMsg>(maxCached),
      ),
      maxNumberOfElementCached: maxCached,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ErmesStorageAndCachingMessages', () {
    late ErmesStorageAndCachingMessages<_TestMsg> sut;

    setUp(() => sut = _makeMessages());
    tearDown(() async => sut.destroy());

    group('deleteUntil', () {
      test('deletes only id 0 when called with 0', () async {
        await sut.store(const _TestMsg(id: 0, content: 'zero'));
        await sut.store(const _TestMsg(id: 1, content: 'one'));
        await sut.store(const _TestMsg(id: 2, content: 'two'));

        sut.deleteUntil(0);
        await Future<void>.delayed(Duration.zero);

        expect(await sut.retrieve(0), isNull);
        expect(await sut.retrieve(1), isNotNull);
        expect(await sut.retrieve(2), isNotNull);
      });

      test('deletes all ids from 0 to n inclusive', () async {
        for (var i = 0; i < 5; i++) {
          await sut.store(_TestMsg(id: i, content: 'msg$i'));
        }

        sut.deleteUntil(2);
        await Future<void>.delayed(Duration.zero);

        expect(await sut.retrieve(0), isNull);
        expect(await sut.retrieve(1), isNull);
        expect(await sut.retrieve(2), isNull);
        expect(await sut.retrieve(3), isNotNull);
        expect(await sut.retrieve(4), isNotNull);
      });

      test('leaves entries with id > n untouched', () async {
        for (var i = 0; i < 6; i++) {
          await sut.store(_TestMsg(id: i, content: 'msg$i'));
        }

        sut.deleteUntil(3);
        await Future<void>.delayed(Duration.zero);

        expect(await sut.retrieve(4), isNotNull);
        expect(await sut.retrieve(5), isNotNull);
      });

      test(
          'calling deleteUntil when storage is empty does not throw', () async {
        sut.deleteUntil(10);
        await Future<void>.delayed(Duration.zero);
        // no exception expected
      });

      test('deleteUntil last id removes all stored entries', () async {
        for (var i = 0; i < 4; i++) {
          await sut.store(_TestMsg(id: i, content: 'msg$i'));
        }

        sut.deleteUntil(3);
        await Future<void>.delayed(Duration.zero);

        final ids = await sut.listOfIds();
        expect(ids, isEmpty);
      });
    });

    group('inherited store and retrieve', () {
      test('stores and retrieves an entry by id', () async {
        const msg = _TestMsg(id: 7, content: 'hello');
        await sut.store(msg);
        final result = await sut.retrieve(7);
        expect(result?.id, equals(7));
        expect(result?.content, equals('hello'));
      });

      test('returns null for an id that was never stored', () async {
        expect(await sut.retrieve(999), isNull);
      });

      test('overwriting same id keeps latest value', () async {
        await sut.store(const _TestMsg(id: 1, content: 'first'));
        await sut.store(const _TestMsg(id: 1, content: 'second'));
        final result = await sut.retrieve(1);
        expect(result?.content, equals('second'));
      });
    });

    group('delete and clear', () {
      test('delete removes a specific entry', () async {
        await sut.store(const _TestMsg(id: 5, content: 'five'));
        final deleted = await sut.delete(5);
        expect(deleted, isTrue);
        expect(await sut.retrieve(5), isNull);
      });

      test('delete returns false for unknown id', () async {
        final deleted = await sut.delete(42);
        expect(deleted, isFalse);
      });

      test('clear removes all entries', () async {
        for (var i = 0; i < 3; i++) {
          await sut.store(_TestMsg(id: i, content: 'msg$i'));
        }
        await sut.clear();
        final ids = await sut.listOfIds();
        expect(ids, isEmpty);
      });
    });
  });

  // -------------------------------------------------------------------------

  group('ErmesStorageAndCachingMessagesHandlerBase', () {
    late ErmesStorageAndCachingMessagesHandlerBase<_TestMsg> handler;

    setUp(() =>
        handler = ErmesStorageAndCachingMessagesHandlerBase<_TestMsg>());

    test('get returns null for an unknown connection id', () {
      expect(handler.get('conn_unknown'), isNull);
    });

    test('get returns null when no connections have been registered', () {
      expect(handler.get('any_conn'), isNull);
    });
  });

  // -------------------------------------------------------------------------

  group('ErmesStorageAndCachingMessagesHandler singleton', () {
    test('instance returns the same object on repeated calls', () {
      final a = ErmesStorageAndCachingMessagesHandler.instance;
      final b = ErmesStorageAndCachingMessagesHandler.instance;
      expect(identical(a, b), isTrue);
    });

    test('instance is not null', () {
      expect(ErmesStorageAndCachingMessagesHandler.instance, isNotNull);
    });
  });
}
