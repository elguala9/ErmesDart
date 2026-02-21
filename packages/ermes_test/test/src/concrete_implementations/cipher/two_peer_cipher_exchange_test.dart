import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testTwoPeerCipherExchange();
}

void testTwoPeerCipherExchange() {
  group('Two-Peer Cipher Exchange Integration', () {
    late ECDHKeyExchangeService peer1KeyExchange;
    late ECDHKeyExchangeService peer2KeyExchange;
    late IErmesPeerCipher peer1Cipher;
    late IErmesPeerCipher peer2Cipher;
    late ISymmetricCipher peer1ToP2Cipher;
    late ISymmetricCipher peer2ToP1Cipher;

    setUp(() async {
      // Each peer generates its own key pair
      peer1KeyExchange = await ECDHKeyExchangeService.generateNew()
          as ECDHKeyExchangeService;
      peer2KeyExchange = await ECDHKeyExchangeService.generateNew()
          as ECDHKeyExchangeService;

      // Create peer ciphers for managing multiple keys
      peer1Cipher = createErmesPeerCipher();
      peer2Cipher = createErmesPeerCipher();

      // Peer 1 generates cipher using Peer 2's public key
      final peer2Serialized = peer2KeyExchange.serialize();
      peer1ToP2Cipher = peer1KeyExchange.generateISymmetric(peer2Serialized);

      // Peer 2 generates cipher using Peer 1's public key
      final peer1Serialized = peer1KeyExchange.serialize();
      peer2ToP1Cipher = peer2KeyExchange.generateISymmetric(peer1Serialized);

      // Register ciphers for encryption/decryption
      peer1Cipher
        ..addEncryptCipher(peer1ToP2Cipher)
        ..addDecryptCipher(peer2ToP1Cipher);

      peer2Cipher
        ..addEncryptCipher(peer2ToP1Cipher)
        ..addDecryptCipher(peer1ToP2Cipher);
    });

    group('Key Exchange Setup', () {
      test('each peer has unique public key', () {
        expect(
          peer1KeyExchange.publicKey,
          isNot(equals(peer2KeyExchange.publicKey)),
        );
      });

      test('each peer has unique private key', () {
        expect(
          peer1KeyExchange.privateKey,
          isNot(equals(peer2KeyExchange.privateKey)),
        );
      });

      test('keys are not expired', () {
        expect(peer1KeyExchange.isExpired(), isFalse);
        expect(peer2KeyExchange.isExpired(), isFalse);
      });

      test('both peers can generate shared secret', () {
        final secret1 = peer1KeyExchange.generateSharedSecret(
          peer2KeyExchange.publicKey,
        );
        final secret2 = peer2KeyExchange.generateSharedSecret(
          peer1KeyExchange.publicKey,
        );

        expect(secret1, isNotEmpty);
        expect(secret2, isNotEmpty);
        expect(secret1, equals(secret2));
      });
    });

    group('Cipher Setup', () {
      test('peer1 has encrypt and decrypt ciphers', () {
        final encrypted = peer1Cipher.encrypt(Uint8List.fromList([1, 2, 3]));
        expect(encrypted, isNotNull);

        final decrypted = peer1Cipher.decrypt(encrypted);
        expect(decrypted, isNotNull);
      });

      test('peer2 has encrypt and decrypt ciphers', () {
        final encrypted = peer2Cipher.encrypt(Uint8List.fromList([4, 5, 6]));
        expect(encrypted, isNotNull);

        final decrypted = peer2Cipher.decrypt(encrypted);
        expect(decrypted, isNotNull);
      });

      test('peer1 cipher can decrypt peer2 encrypted data', () {
        // "Hello"
        final originalData = Uint8List.fromList([72, 101, 108, 108, 111]);
        final encrypted = peer2Cipher.encrypt(originalData);

        final decrypted = peer1Cipher.decrypt(encrypted);

        expect(decrypted, equals(originalData));
      });

      test('peer2 cipher can decrypt peer1 encrypted data', () {
        // "World"
        final originalData = Uint8List.fromList([87, 111, 114, 108, 100]);
        final encrypted = peer1Cipher.encrypt(originalData);

        final decrypted = peer2Cipher.decrypt(encrypted);

        expect(decrypted, equals(originalData));
      });
    });

    group('Bidirectional Communication', () {
      test('peer1 encrypts, peer2 decrypts message', () {
        final message = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

        final encrypted = peer1Cipher.encrypt(message);
        final decrypted = peer2Cipher.decrypt(encrypted);

        expect(decrypted, equals(message));
      });

      test('peer2 encrypts, peer1 decrypts message', () {
        final message = Uint8List.fromList(
          [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
        );

        final encrypted = peer2Cipher.encrypt(message);
        final decrypted = peer1Cipher.decrypt(encrypted);

        expect(decrypted, equals(message));
      });

      test('roundtrip messages in both directions', () {
        final message1 = Uint8List.fromList([1, 2, 3]);
        final message2 = Uint8List.fromList([4, 5, 6]);

        // Peer1 -> Peer2
        final encrypted1 = peer1Cipher.encrypt(message1);
        final decrypted1 = peer2Cipher.decrypt(encrypted1);
        expect(decrypted1, equals(message1));

        // Peer2 -> Peer1
        final encrypted2 = peer2Cipher.encrypt(message2);
        final decrypted2 = peer1Cipher.decrypt(encrypted2);
        expect(decrypted2, equals(message2));
      });

      test('encrypted message uses correct keyId', () {
        final message = Uint8List.fromList([1, 2, 3]);

        final encrypted = peer1Cipher.encrypt(message);

        expect(encrypted.keyId, isNotNull);
        expect(encrypted.keyId, equals(peer1ToP2Cipher.keyId));
      });
    });

    group('Large Message Transfer', () {
      test('can encrypt and decrypt large message', () {
        final largeMessage = Uint8List.fromList(
          List<int>.generate(10000, (i) => i % 256),
        );

        final encrypted = peer1Cipher.encrypt(largeMessage);
        final decrypted = peer2Cipher.decrypt(encrypted);

        expect(decrypted.length, equals(largeMessage.length));
        expect(decrypted, equals(largeMessage));
      });

      test('can transfer message multiple times', () {
        final message = Uint8List.fromList([1, 2, 3, 4, 5]);

        for (var i = 0; i < 10; i++) {
          final encrypted = peer1Cipher.encrypt(message);
          final decrypted = peer2Cipher.decrypt(encrypted);
          expect(decrypted, equals(message));
        }
      });

      test('interleaved bidirectional transfer preserves integrity', () {
        final messages = [
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList([4, 5, 6]),
          Uint8List.fromList([7, 8, 9]),
          Uint8List.fromList([10, 11, 12]),
        ];

        // Peer1 -> Peer2 (message 0)
        var enc = peer1Cipher.encrypt(messages[0]);
        var dec = peer2Cipher.decrypt(enc);
        expect(dec, equals(messages[0]));

        // Peer2 -> Peer1 (message 1)
        enc = peer2Cipher.encrypt(messages[1]);
        dec = peer1Cipher.decrypt(enc);
        expect(dec, equals(messages[1]));

        // Peer1 -> Peer2 (message 2)
        enc = peer1Cipher.encrypt(messages[2]);
        dec = peer2Cipher.decrypt(enc);
        expect(dec, equals(messages[2]));

        // Peer2 -> Peer1 (message 3)
        enc = peer2Cipher.encrypt(messages[3]);
        dec = peer1Cipher.decrypt(enc);
        expect(dec, equals(messages[3]));
      });
    });

    group('Multi-Cipher Scenarios', () {
      test('peer can add additional decrypt cipher', () async {
        // Create a third key exchange for a new peer
        final peer3KeyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final peer3ToP1Cipher = peer1KeyExchange
            .generateISymmetric(peer3KeyExchange.serialize());

        // Peer1 adds cipher from peer3 for decryption
        peer1Cipher.addDecryptCipher(peer3ToP1Cipher);

        // Peer3 can now encrypt and peer1 can decrypt
        final message = Uint8List.fromList([99, 98, 97]);
        final encrypted = peer3ToP1Cipher.encrypt(message);
        final dataEncrypted = DataEncrypted(
          peer3ToP1Cipher.keyId,
          Uint8List.fromList(encrypted),
        );

        final decrypted = peer1Cipher.decrypt(dataEncrypted);
        expect(decrypted, equals(message));
      });

      test('peer can add additional encrypt cipher and uses latest', () async {
        // Create a third key exchange
        final peer3KeyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final peer3FromP1Cipher = peer3KeyExchange
            .generateISymmetric(peer1KeyExchange.serialize());

        // Peer1 adds cipher to peer3 for encryption
        peer1Cipher.addEncryptCipher(peer3FromP1Cipher);

        final message = Uint8List.fromList([11, 22, 33]);
        // Encrypt will use one of the available ciphers
        final encrypted = peer1Cipher.encrypt(message);

        expect(encrypted.encryptedData, isNotEmpty);
      });

      test('removing decrypt cipher prevents decryption', () {
        final keyId = peer2ToP1Cipher.keyId;

        // Remove the cipher
        peer1Cipher.removeDecryptCipher(keyId);

        // Now peer1 cannot decrypt peer2's messages
        final message = Uint8List.fromList([5, 6, 7]);
        final encrypted = peer2Cipher.encrypt(message);

        expect(
          () => peer1Cipher.decrypt(encrypted),
          throwsA(isA<CipherException>()),
        );
      });

      test('clearing old ciphers removes only expired ones', () {
        // Ciphers are fresh, so clearing old should have no effect
        final testMessage = Uint8List.fromList([8, 9, 10]);

        peer1Cipher.clearOldDecryptCipher();

        // Should still be able to decrypt
        final encrypted = peer2Cipher.encrypt(testMessage);
        final decrypted = peer1Cipher.decrypt(encrypted);
        expect(decrypted, equals(testMessage));
      });
    });

    group('Serialization and Restoration', () {
      test('can serialize both peer key exchanges', () {
        final peer1Serialized = peer1KeyExchange.serialize();
        final peer2Serialized = peer2KeyExchange.serialize();

        expect(peer1Serialized, isNotEmpty);
        expect(peer2Serialized, isNotEmpty);
        expect(peer1Serialized, isNot(equals(peer2Serialized)));
      });

      test('can restore from serialization and re-establish secure channel',
          () async {
        // Serialize both key exchanges
        final peer1Serialized = peer1KeyExchange.serialize();
        final peer2Serialized = peer2KeyExchange.serialize();

        // In a new context, restore the keys
        final restoredPeer1 =
            ECDHKeyExchangeService.deserialize(peer1Serialized);
        final restoredPeer2 =
            ECDHKeyExchangeService.deserialize(peer2Serialized);

        // Create new ciphers from restored keys
        final newPeer1Cipher = createErmesPeerCipher();
        final newPeer2Cipher = createErmesPeerCipher();

        // Re-establish secure channel
        final newP1ToP2Cipher =
            restoredPeer1.generateISymmetric(peer2Serialized);
        final newP2ToP1Cipher =
            restoredPeer2.generateISymmetric(peer1Serialized);

        newPeer1Cipher
          ..addEncryptCipher(newP1ToP2Cipher)
          ..addDecryptCipher(newP2ToP1Cipher);

        newPeer2Cipher
          ..addEncryptCipher(newP2ToP1Cipher)
          ..addDecryptCipher(newP1ToP2Cipher);

        // Test communication with restored ciphers
        final message = Uint8List.fromList([100, 101, 102]);
        final encrypted = newPeer1Cipher.encrypt(message);
        final decrypted = newPeer2Cipher.decrypt(encrypted);

        expect(decrypted, equals(message));
      });
    });

    group('Data Encryption Wrapper', () {
      test('DataEncrypted contains correct keyId and encrypted data', () {
        final plaintext = Uint8List.fromList([1, 2, 3]);
        final encrypted = peer1Cipher.encrypt(plaintext);

        expect(encrypted, isA<DataEncrypted>());
        expect(encrypted.keyId, equals(peer1ToP2Cipher.keyId));
        expect(encrypted.encryptedData, isNotEmpty);
      });

      test('DataEncrypted can be used to decrypt message', () {
        final plaintext = Uint8List.fromList([42, 43, 44]);
        final encrypted = peer1Cipher.encrypt(plaintext);

        // Use the DataEncrypted object directly
        final decrypted = peer2Cipher.decrypt(encrypted);

        expect(decrypted, equals(plaintext));
      });
    });

    group('Algorithm Variants', () {
      test('works with DES algorithm', () async {
        final p1 = await ECDHKeyExchangeService.generateNew(
          SymmetricCipherAlgorithmEnum.des,
        ) as ECDHKeyExchangeService;
        final p2 = await ECDHKeyExchangeService.generateNew(
          SymmetricCipherAlgorithmEnum.des,
        ) as ECDHKeyExchangeService;

        final cipher1 = p1.generateISymmetric(p2.serialize());
        final cipher2 = p2.generateISymmetric(p1.serialize());

        final c1 = createErmesPeerCipher()
          ..addEncryptCipher(cipher1)
          ..addDecryptCipher(cipher2);

        final c2 = createErmesPeerCipher()
          ..addEncryptCipher(cipher2)
          ..addDecryptCipher(cipher1);

        final message = Uint8List.fromList([4, 5, 6]);
        final encrypted = c1.encrypt(message);
        final decrypted = c2.decrypt(encrypted);

        expect(decrypted, equals(message));
      });
    });
  });
}
