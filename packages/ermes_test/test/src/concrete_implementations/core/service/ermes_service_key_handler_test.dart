import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesServiceKeyHandler();
}

/// Encrypts a byte with an unrelated real cipher so its digest never matches
/// any decrypt cipher a peer under test might hold.
DataEncrypted _foreignEncryptedProbe() {
  final foreignCipher = generateSymmetric('f' * 32, SymmetricAlgorithm.aes);
  final probe = ErmesPeerCipher()..addEncryptCipher(foreignCipher);
  return probe.encrypt(Uint8List.fromList([1, 2, 3]));
}

void testErmesServiceKeyHandler() {
  group('ErmesServiceKeyHandler', () {
    var peerCounter = 0;
    late String peerId;

    setUp(() {
      peerCounter++;
      peerId = 'key-handler-peer-$peerCounter';
    });

    tearDown(() {
      ErmesPeerCipherHandler().remove(peerId);
    });

    group('buildNewKeyMessage()', () {
      test('builds a ServiceMessageNewKey with the required fields', () {
        final message = buildNewKeyMessage(
          newId: 7,
          algorithm: SymmetricAlgorithm.aes,
          key: 'a' * 32,
        );

        expect(message.id, equals(7));
        expect(message.algorithm, equals(SymmetricAlgorithm.aes));
        expect(message.key, equals('a' * 32));
        expect(message.start, isNull);
        expect(message.expiration, isNull);
      });

      test('builds a ServiceMessageNewKey carrying every optional field', () {
        final start = DateTime(2024);
        final expiration = DateTime(2025);
        final message = buildNewKeyMessage(
          newId: 9,
          algorithm: SymmetricAlgorithm.aes,
          key: 'b' * 32,
          start: start,
          expiration: expiration,
          startMessage: 10,
          endMessage: 20,
        );

        expect(message.start, equals(start));
        expect(message.expiration, equals(expiration));
        expect(message.startMessage, equals(10));
        expect(message.endMessage, equals(20));
      });
    });

    group('handleNewKeyMessage()', () {
      test('registers a decryption cipher for a new peer', () {
        final message = buildNewKeyMessage(
          newId: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'c' * 32,
        );

        handleNewKeyMessage(message, peerId);

        final peerCipher = ErmesPeerCipherHandler().get(peerId);
        expect(peerCipher, isNotNull);
      });

      test('adds a decryption cipher to an existing peer cipher', () {
        final existing = ErmesPeerCipher();
        ErmesPeerCipherHandler().set(peerId, existing);

        final message = buildNewKeyMessage(
          newId: 2,
          algorithm: SymmetricAlgorithm.aes,
          key: 'd' * 32,
        );

        handleNewKeyMessage(message, peerId);

        expect(ErmesPeerCipherHandler().get(peerId), same(existing));
      });

      test('round-trips through buildNewKeyMessage and back', () {
        final built = buildNewKeyMessage(
          newId: 3,
          algorithm: SymmetricAlgorithm.aes,
          key: 'e' * 32,
        );

        expect(() => handleNewKeyMessage(built, peerId), returnsNormally);
        expect(ErmesPeerCipherHandler().get(peerId), isNotNull);
      });

      test(
          'BUG: an odd-length hex key throws RangeError instead of being '
          'swallowed, because handleNewKeyMessage only catches on Exception '
          'and _hexStringToBytes throws RangeError (an Error, not an '
          'Exception) for a substring past the end of an odd-length string. '
          'Not fixed here, only documented.', () {
        final message = buildNewKeyMessage(
          newId: 4,
          algorithm: SymmetricAlgorithm.aes,
          key: 'abc', // odd-length hex is not parseable byte-by-byte
        );

        expect(
          () => handleNewKeyMessage(message, peerId),
          throwsA(isA<RangeError>()),
        );
      });

      test('logs and swallows a non-hex key without throwing', () {
        final message = buildNewKeyMessage(
          newId: 5,
          algorithm: SymmetricAlgorithm.aes,
          key: 'not-hex-at-all!!',
        );

        expect(() => handleNewKeyMessage(message, peerId), returnsNormally);
        // The peer cipher shell is still created/registered, but no working
        // decrypt cipher was added to it.
        final peerCipher = ErmesPeerCipherHandler().get(peerId);
        expect(peerCipher, isNotNull);
        expect(
          () => peerCipher!.decrypt(_foreignEncryptedProbe()),
          throwsA(isA<CipherException>()),
        );
      });

      test('logs and swallows a wrong-length AES key without throwing', () {
        final message = buildNewKeyMessage(
          newId: 6,
          algorithm: SymmetricAlgorithm.aes,
          key: 'ab', // 8 bits: not 128/192/256
        );

        expect(() => handleNewKeyMessage(message, peerId), returnsNormally);
        final peerCipher = ErmesPeerCipherHandler().get(peerId);
        expect(peerCipher, isNotNull);
        expect(
          () => peerCipher!.decrypt(_foreignEncryptedProbe()),
          throwsA(isA<CipherException>()),
        );
      });

      test('registers the peer cipher shell even when key material is '
          'invalid', () {
        final message = buildNewKeyMessage(
          newId: 8,
          algorithm: SymmetricAlgorithm.aes,
          key: 'zz', // invalid hex digits
        );

        handleNewKeyMessage(message, peerId);

        expect(ErmesPeerCipherHandler().contains(peerId), isTrue);
      });
    });
  });
}
