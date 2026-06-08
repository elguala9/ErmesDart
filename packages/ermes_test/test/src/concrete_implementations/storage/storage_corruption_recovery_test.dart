import 'dart:convert';
import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

// ---------------------------------------------------------------------------
// Real, minimal StorageType used by the corruption / recovery tests.
// ---------------------------------------------------------------------------

class _Record implements StorageType {
  const _Record({required this.id, required this.content});

  factory _Record.fromJson(Map<String, dynamic> json) => _Record(
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
      other is _Record && id == other.id && content == other.content;

  @override
  int get hashCode => Object.hash(id, content);
}

Uint8List _key256(int seed) =>
    Uint8List.fromList(List<int>.generate(32, (i) => (seed + i) & 0xff));

const String _encryptedMarker = '__encrypted';
const String _dataField = 'data';

/// Verifies that corrupted stored payloads cause sensible failures at
/// decrypt/deserialize time rather than silently returning wrong data, and
/// that intact data is still recoverable afterwards.
void testStorageCorruptionRecovery() {
  group('storage corruption and recovery', () {
    group('AesStorageEncryptionService.decrypt on corrupted payloads', () {
      late AesStorageEncryptionService service;

      setUp(() => service = AesStorageEncryptionService(_key256(1)));

      test('throws on invalid base64 in the data field', () {
        final corrupted = {
          _encryptedMarker: true,
          _dataField: 'not!valid!base64!!!',
        };
        expect(() => service.decrypt(corrupted), throwsA(isA<Object>()));
      });

      test('throws on truncated ciphertext', () {
        final good = service.encrypt({'id': 1, 'content': 'intact'});
        final encoded = good[_dataField] as String;
        final bytes = base64Decode(encoded);
        // Drop the trailing block so PKCS7 padding / block size is invalid.
        final truncated = bytes.sublist(0, bytes.length - 8);

        final corrupted = {
          _encryptedMarker: true,
          _dataField: base64Encode(truncated),
        };
        expect(() => service.decrypt(corrupted), throwsA(isA<Object>()));
      });

      test('throws when ciphertext decrypts to non-JSON bytes', () {
        // Random bytes that are a valid block length but not our ciphertext.
        final garbage = Uint8List.fromList(
          List<int>.generate(16, (i) => (i * 37 + 5) & 0xff),
        );
        final corrupted = {
          _encryptedMarker: true,
          _dataField: base64Encode(garbage),
        };
        expect(() => service.decrypt(corrupted), throwsA(isA<Object>()));
      });

      test('intact data still round-trips after a corrupted attempt', () {
        final bad = {
          _encryptedMarker: true,
          _dataField: 'totally-broken',
        };
        expect(() => service.decrypt(bad), throwsA(isA<Object>()));

        // The service is stateless per call: a good payload still works.
        final original = {'id': 1, 'content': 'still-fine'};
        expect(
          service.decrypt(service.encrypt(original)),
          equals(original),
        );
      });
    });

    group('deserialization of corrupted records', () {
      test('fromJson factory throws on a malformed record map', () {
        // The stored map is missing the required typed fields.
        final malformed = <String, dynamic>{'unexpected': 'shape'};
        expect(() => _Record.fromJson(malformed), throwsA(isA<Object>()));
      });

      test('MessageType.fromJson throws on an unknown message type', () {
        final malformed = <String, dynamic>{
          'type': 'bogus',
          'message': <String, dynamic>{},
        };
        expect(
          () => MessageType.fromJson(malformed),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('repository recovery after a corrupted record', () {
      late IWorkDb db;
      var counter = 0;
      late String collection;

      setUp(() {
        db = WorkDb.memory();
        counter++;
        collection = 'corrupt_$counter';
      });

      test('retrieving a corrupted encrypted record throws', () async {
        final key = _key256(2);
        final repo = ErmesStorageRepository<_Record>(
          db,
          collection,
          _Record.fromJson,
          AesStorageEncryptionService(key),
        );

        // Inject a corrupted record directly into the backing store.
        await db.createOrUpdate(
          ItemWithId(
            id: '1',
            collection: collection,
            item: {
              _encryptedMarker: true,
              _dataField: 'garbled-base64-@@@',
            },
          ),
        );

        await expectLater(repo.retrieve(1), throwsA(isA<Object>()));
      });

      test('a valid record stored alongside a corrupted one is still '
          'recoverable', () async {
        final key = _key256(3);
        final repo = ErmesStorageRepository<_Record>(
          db,
          collection,
          _Record.fromJson,
          AesStorageEncryptionService(key),
        );

        // Inject corruption at id 1.
        await db.createOrUpdate(
          ItemWithId(
            id: '1',
            collection: collection,
            item: {_encryptedMarker: true, _dataField: 'broken'},
          ),
        );

        // Store a genuine record at id 2 through the repository.
        await repo.store(const _Record(id: 2, content: 'healthy'));

        // The corrupted one fails, the healthy one succeeds.
        await expectLater(repo.retrieve(1), throwsA(isA<Object>()));
        expect((await repo.retrieve(2))?.content, equals('healthy'));
      });

      test('retrieving a record with a malformed plaintext map throws on '
          'deserialization', () async {
        final repo = ErmesStorageRepository<_Record>(
          db,
          collection,
          _Record.fromJson,
        );

        // Stored without encryption but with the wrong shape for _Record.
        await db.createOrUpdate(
          ItemWithId(
            id: '5',
            collection: collection,
            item: <String, dynamic>{'wrong': 'fields'},
          ),
        );

        await expectLater(repo.retrieve(5), throwsA(isA<Object>()));
      });

      test('repository keeps working for new writes after a failed read',
          () async {
        final repo = ErmesStorageRepository<_Record>(
          db,
          collection,
          _Record.fromJson,
        );

        await db.createOrUpdate(
          ItemWithId(
            id: '9',
            collection: collection,
            item: <String, dynamic>{'corrupt': true},
          ),
        );

        await expectLater(repo.retrieve(9), throwsA(isA<Object>()));

        // New writes and reads continue to work normally.
        await repo.store(const _Record(id: 10, content: 'after-failure'));
        expect((await repo.retrieve(10))?.content, equals('after-failure'));
      });
    });
  });
}

void main() => testStorageCorruptionRecovery();
