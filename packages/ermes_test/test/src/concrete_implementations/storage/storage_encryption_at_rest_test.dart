import 'dart:convert';
import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

// ---------------------------------------------------------------------------
// Real, minimal StorageType used by the encryption-at-rest tests.
// ---------------------------------------------------------------------------

class _SecretMsg implements StorageType {
  const _SecretMsg({required this.id, required this.content});

  factory _SecretMsg.fromJson(Map<String, dynamic> json) => _SecretMsg(
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
      other is _SecretMsg && id == other.id && content == other.content;

  @override
  int get hashCode => Object.hash(id, content);
}

/// Builds a deterministic 256-bit AES key from a single seed byte so each
/// test can use a distinct, fully-sized real key.
Uint8List _key256(int seed) =>
    Uint8List.fromList(List<int>.generate(32, (i) => (seed + i) & 0xff));

const String _encryptedMarker = '__encrypted';
const String _dataField = 'data';

/// Verifies AES encryption at rest: payloads are marked and unreadable,
/// round-trips succeed, plaintext maps pass through, and a wrong key cannot
/// recover the original plaintext.
void testStorageEncryptionAtRest() {
  group('AesStorageEncryptionService', () {
    late AesStorageEncryptionService service;

    setUp(() => service = AesStorageEncryptionService(_key256(1)));

    group('encrypt output shape', () {
      test('encrypted payload carries the __encrypted marker', () {
        final out = service.encrypt({'id': 1, 'content': 'topsecret'});
        expect(out[_encryptedMarker], isTrue);
        expect(out.containsKey(_dataField), isTrue);
      });

      test('encrypted data is base64 and not plaintext-readable', () {
        const plaintext = 'super-confidential-string';
        final out = service.encrypt({'id': 1, 'content': plaintext});

        final dataField = out[_dataField];
        expect(dataField, isA<String>());

        final encoded = dataField as String;
        // The ciphertext must not embed the plaintext.
        expect(encoded.contains(plaintext), isFalse);

        // It must be valid base64 whose decoded bytes are not the plaintext.
        final rawBytes = base64Decode(encoded);
        final asUtf8 = _tryDecodeUtf8(rawBytes);
        expect(asUtf8, isNot(equals(plaintext)));
      });

      test('encrypting the same map twice yields the same ciphertext '
          '(ECB, deterministic)', () {
        final a = service.encrypt({'id': 1, 'content': 'x'});
        final b = service.encrypt({'id': 1, 'content': 'x'});
        expect(a[_dataField], equals(b[_dataField]));
      });
    });

    group('round-trip', () {
      test('decrypt(encrypt(x)) returns x unchanged', () {
        final original = {'id': 42, 'content': 'round-trip-me'};
        final recovered = service.decrypt(service.encrypt(original));
        expect(recovered, equals(original));
      });

      test('round-trips a payload with nested structures', () {
        final original = <String, dynamic>{
          'id': 1,
          'meta': {'a': 1, 'b': 'two'},
          'list': [1, 2, 3],
        };
        final recovered = service.decrypt(service.encrypt(original));
        expect(recovered, equals(original));
      });
    });

    group('passthrough of unencrypted maps', () {
      test('decrypt of an unencrypted map returns it unchanged', () {
        final plain = {'id': 1, 'content': 'not-encrypted'};
        expect(service.decrypt(plain), equals(plain));
      });

      test('decrypt ignores a map without the marker even with a data field',
          () {
        final plain = {'data': 'looks-like-cipher-but-no-marker'};
        expect(service.decrypt(plain), equals(plain));
      });
    });

    group('wrong key', () {
      test('a different key cannot recover the original plaintext', () {
        final encryptor = AesStorageEncryptionService(_key256(1));
        final attacker = AesStorageEncryptionService(_key256(200));

        final original = {'id': 1, 'content': 'genuine-secret'};
        final encrypted = encryptor.encrypt(original);

        // Either it throws (bad padding / invalid utf8 / bad json) or it
        // yields a map that differs from the original. In no case may the
        // wrong key reproduce the original plaintext.
        Map<String, dynamic>? recovered;
        var threw = false;
        try {
          recovered = attacker.decrypt(encrypted);
        } on Object catch (_) {
          threw = true;
        }

        if (!threw) {
          expect(recovered, isNot(equals(original)));
        } else {
          expect(threw, isTrue);
        }
      });
    });

    group('end-to-end through the storage repository', () {
      late IWorkDb db;
      var counter = 0;
      late String collection;

      setUp(() {
        db = WorkDb.memory();
        counter++;
        collection = 'enc_$counter';
      });

      test('repository round-trips data with an encryption service', () async {
        final repo = ErmesStorageRepository<_SecretMsg>(
          db,
          collection,
          _SecretMsg.fromJson,
          AesStorageEncryptionService(_key256(5)),
        );

        await repo.store(const _SecretMsg(id: 1, content: 'at-rest'));
        final result = await repo.retrieve(1);
        expect(result?.content, equals('at-rest'));
      });

      test('the raw stored item is encrypted, not plaintext', () async {
        const secret = 'never-store-me-in-clear';
        final repo = ErmesStorageRepository<_SecretMsg>(
          db,
          collection,
          _SecretMsg.fromJson,
          AesStorageEncryptionService(_key256(6)),
        );

        await repo.store(const _SecretMsg(id: 1, content: secret));

        // Read the raw backing record straight from the db, bypassing the
        // repository's decryption, to confirm it is ciphertext at rest.
        final raw = await db.retrieve(
          ItemId(id: '1', collection: collection),
        );
        expect(raw, isNotNull);
        final stored = Map<String, dynamic>.from(raw!.item as Map);
        expect(stored[_encryptedMarker], isTrue);
        expect(jsonEncode(stored).contains(secret), isFalse);
      });

      test('a fresh repository with the right key reads encrypted data',
          () async {
        final key = _key256(7);
        final writer = ErmesStorageRepository<_SecretMsg>(
          db,
          collection,
          _SecretMsg.fromJson,
          AesStorageEncryptionService(key),
        );
        await writer.store(const _SecretMsg(id: 1, content: 'shared'));

        final reader = ErmesStorageRepository<_SecretMsg>(
          db,
          collection,
          _SecretMsg.fromJson,
          AesStorageEncryptionService(key),
        );
        expect((await reader.retrieve(1))?.content, equals('shared'));
      });
    });

    group('edge cases and error handling', () {
      test('encrypt/decrypt round-trips an empty map', () {
        final recovered = service.decrypt(service.encrypt(<String, dynamic>{}));
        expect(recovered, equals(<String, dynamic>{}));
      });

      test('decrypt throws when the marker is true but the data field is '
          'missing (null cast to String)', () {
        final malformed = {_encryptedMarker: true};
        expect(() => service.decrypt(malformed), throwsA(isA<TypeError>()));
      });

      test('decrypt throws FormatException when the data field is not '
          'valid base64', () {
        final malformed = {
          _encryptedMarker: true,
          _dataField: 'not-valid-base64!!!',
        };
        expect(() => service.decrypt(malformed),
            throwsA(isA<FormatException>()));
      });

      test('encrypt throws when the map contains a non-JSON-encodable value',
          () {
        final unencodable = <String, dynamic>{'when': DateTime.now()};
        expect(() => service.encrypt(unencodable), throwsA(anything));
      });

      test('decrypt is idempotent when applied twice to an already-decrypted '
          'plain map', () {
        final plain = {'id': 1, 'content': 'plain'};
        final once = service.decrypt(plain);
        final twice = service.decrypt(once);
        expect(twice, equals(plain));
      });

      test('decrypt treats an explicit false marker as unencrypted '
          'passthrough', () {
        final plain = {_encryptedMarker: false, 'content': 'plain'};
        expect(service.decrypt(plain), equals(plain));
      });
    });
  });
}

/// Attempts to decode bytes as UTF-8, returning null when they are invalid.
String? _tryDecodeUtf8(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on Object catch (_) {
    return null;
  }
}

void main() => testStorageEncryptionAtRest();
