import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

InternalMessage _internalMessageFor(Uint8List data, int id) => InternalMessage(
      message: MessageType.data(MessageData(id: id, data: data)),
      type: MessageValue.base,
    );

void testErmesMessageRootCodec() {
  group('buildMessageRoot', () {
    tearDown(() => ErmesPeerCipherHandler().remove('peer-x'));

    test('produces a plaintext MessageRoot when no cipher is registered',
        () {
      final data = Uint8List.fromList([1, 2, 3]);
      final root = buildMessageRoot(MessageType.data(MessageData(id: 1, data: data)), 'peer-x');
      expect(root.digest, isNull);
      expect(root.messageJson, isNotNull);
      expect(root.messageSerialized, isEmpty);
    });

    test('produces an encrypted MessageRoot when an encrypt cipher is '
        'registered', () {
      final cipher = generateSymmetric('A' * 64, SymmetricAlgorithm.aes);
      ErmesPeerCipherHandler().set(
        'peer-x',
        ErmesPeerCipher()..addEncryptCipher(cipher),
      );

      final data = Uint8List.fromList([9, 8, 7]);
      final root = buildMessageRoot(MessageType.data(MessageData(id: 1, data: data)), 'peer-x');

      expect(root.digest, equals(cipher.keyId));
      expect(root.messageJson, isNull);
      expect(root.messageSerialized, isNotEmpty);
    });

    test('stays plaintext when the registered peer cipher has only a '
        'decrypt cipher (mid-handshake)', () {
      final cipher = generateSymmetric('B' * 64, SymmetricAlgorithm.aes);
      ErmesPeerCipherHandler().set(
        'peer-x',
        ErmesPeerCipher()..addDecryptCipher(cipher),
      );

      final data = Uint8List.fromList([4, 5, 6]);
      final root = buildMessageRoot(MessageType.data(MessageData(id: 1, data: data)), 'peer-x');

      expect(root.digest, isNull);
      expect(root.messageJson, isNotNull);
    });

    test('the integrity hash is computed over the plaintext, independent '
        'of encryption', () {
      final data = Uint8List.fromList([1, 1, 1]);
      final plainRoot = buildMessageRoot(MessageType.data(MessageData(id: 1, data: data)), 'peer-x');

      final cipher = generateSymmetric('C' * 64, SymmetricAlgorithm.aes);
      ErmesPeerCipherHandler().set(
        'peer-x',
        ErmesPeerCipher()..addEncryptCipher(cipher),
      );
      final encryptedRoot = buildMessageRoot(MessageType.data(MessageData(id: 1, data: data)), 'peer-x');

      expect(encryptedRoot.integrityCheckValue, equals(plainRoot.integrityCheckValue));
    });
  });

  group('decodeMessageEnvelope', () {
    tearDown(() => ErmesPeerCipherHandler().remove('peer-x'));

    test('returns null for an empty message', () {
      final result = decodeMessageEnvelope(Uint8List(0), 'peer-x', {});
      expect(result, isNull);
    });

    test('decodes a valid legacy (v1) plaintext MessageRoot', () {
      final internal = _internalMessageFor(Uint8List.fromList([1, 2, 3]), 1);
      final plainBytes = objectToUint8Array(internal);
      final root = MessageRoot(
        messageSerialized: plainBytes,
        integrityCheckValue: calculateHashSync(plainBytes),
      );

      final result = decodeMessageEnvelope(objectToUint8Array(root), 'peer-x', {});
      expect(result, isNotNull);
      expect(result!.plainBytes, equals(plainBytes));
    });

    test('decodes a valid v2 plaintext MessageRoot (messageJson set)', () {
      final internal = _internalMessageFor(Uint8List.fromList([4, 5, 6]), 2);
      final plainBytes = objectToUint8Array(internal);
      final root = MessageRoot(
        messageJson: internal.toJson(),
        messageSerialized: Uint8List(0),
        integrityCheckValue: calculateHashSync(plainBytes),
      );

      final result = decodeMessageEnvelope(objectToUint8Array(root), 'peer-x', {});
      expect(result, isNotNull);
      expect(result!.plainBytes, equals(plainBytes));
    });

    test('rejects a message whose integrity hash does not match the '
        'payload', () {
      final internal = _internalMessageFor(Uint8List.fromList([1, 2, 3]), 1);
      final plainBytes = objectToUint8Array(internal);
      final root = MessageRoot(
        messageSerialized: plainBytes,
        integrityCheckValue: 'tampered-hash-value',
      );

      final result = decodeMessageEnvelope(objectToUint8Array(root), 'peer-x', {});
      expect(result, isNull);
    });

    test('rejects a message whose hash was already processed (replay/'
        'duplicate protection)', () {
      final internal = _internalMessageFor(Uint8List.fromList([1, 2, 3]), 1);
      final plainBytes = objectToUint8Array(internal);
      final root = MessageRoot(
        messageSerialized: plainBytes,
        integrityCheckValue: calculateHashSync(plainBytes),
      );
      final encoded = objectToUint8Array(root);
      final processedHashes = <String>{};

      final first = decodeMessageEnvelope(encoded, 'peer-x', processedHashes);
      final second = decodeMessageEnvelope(encoded, 'peer-x', processedHashes);

      expect(first, isNotNull);
      expect(second, isNull);
      expect(processedHashes, hasLength(1));
    });

    test('drops an encrypted message when no cipher is registered for '
        'the peer, instead of throwing', () {
      final internal = _internalMessageFor(Uint8List.fromList([1, 2, 3]), 1);
      final plainBytes = objectToUint8Array(internal);
      final root = MessageRoot(
        messageSerialized: Uint8List.fromList([9, 9, 9]),
        integrityCheckValue: calculateHashSync(plainBytes),
        digest: Digest(utf8.encode('unknown-key-id')),
      );

      final result = decodeMessageEnvelope(objectToUint8Array(root), 'peer-x', {});
      expect(result, isNull);
    });

    test('drops an encrypted message that fails to decrypt (wrong/foreign '
        'key), instead of throwing', () {
      final wrongCipher = generateSymmetric('D' * 64, SymmetricAlgorithm.aes);
      ErmesPeerCipherHandler().set(
        'peer-x',
        ErmesPeerCipher()..addDecryptCipher(wrongCipher),
      );

      final internal = _internalMessageFor(Uint8List.fromList([1, 2, 3]), 1);
      final plainBytes = objectToUint8Array(internal);
      final root = MessageRoot(
        messageSerialized: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        integrityCheckValue: calculateHashSync(plainBytes),
        digest: Digest(utf8.encode('some-other-key-id')),
      );

      final result = decodeMessageEnvelope(objectToUint8Array(root), 'peer-x', {});
      expect(result, isNull);
    });

    test('decodes a correctly encrypted message when the matching '
        'decrypt cipher is registered', () {
      final cipher = generateSymmetric('E' * 64, SymmetricAlgorithm.aes);
      ErmesPeerCipherHandler().set(
        'peer-x',
        ErmesPeerCipher()..addDecryptCipher(cipher),
      );

      final internal = _internalMessageFor(Uint8List.fromList([7, 7, 7]), 3);
      final plainBytes = objectToUint8Array(internal);
      final encrypted = cipher.encrypt(plainBytes);
      final root = MessageRoot(
        messageSerialized: Uint8List.fromList(encrypted),
        integrityCheckValue: calculateHashSync(plainBytes),
        digest: cipher.keyId,
      );

      final result = decodeMessageEnvelope(objectToUint8Array(root), 'peer-x', {});
      expect(result, isNotNull);
      expect(result!.plainBytes, equals(plainBytes));
    });

    test('build-then-decode round trip recovers the original message '
        'through a shared symmetric cipher', () {
      final cipher = generateSymmetric('F' * 64, SymmetricAlgorithm.aes);
      ErmesPeerCipherHandler().set(
        'peer-x',
        ErmesPeerCipher()
          ..addEncryptCipher(cipher)
          ..addDecryptCipher(cipher),
      );

      final data = Uint8List.fromList([42, 43, 44]);
      final built = buildMessageRoot(MessageType.data(MessageData(id: 5, data: data)), 'peer-x');
      final encoded = objectToUint8Array(built);

      final decoded = decodeMessageEnvelope(encoded, 'peer-x', {});
      expect(decoded, isNotNull);

      final internal = uint8ArrayToObject<InternalMessage>(decoded!.plainBytes);
      final recovered = internal.message.asData();
      expect(recovered, isNotNull);
      expect(recovered!.data, equals(data));
    });
  });

  group('objectToUint8Array', () {
    test('produces UTF-8 encoded JSON bytes for a serializable object', () {
      final internal = _internalMessageFor(Uint8List.fromList([1]), 1);
      final bytes = objectToUint8Array(internal);
      final decodedJson = jsonDecode(utf8.decode(bytes));
      expect(decodedJson, equals(internal.toJson()));
    });
  });
}

void main() {
  testErmesMessageRootCodec();
}
