import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_cipher/src/factories/ermes_cipher_factories.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesPeerKeyExchange();
}

void testErmesPeerKeyExchange() {
  group('ErmesPeerKeyExchange - Two Peer Cipher Exchange', () {
    late ECDHKeyExchangeService peer1KeyExchange;
    late ECDHKeyExchangeService peer2KeyExchange;
    late IErmesPeerCipher peer1Cipher;
    late IErmesPeerCipher peer2Cipher;
    late ISymmetricCipher peer1ToP2Cipher;
    late ISymmetricCipher peer2ToP1Cipher;
    late ErmesPeerKeyExchange peer1KeyExchangeHandler;
    late ErmesPeerKeyExchange peer2KeyExchangeHandler;

    setUp(() async {
      // Each peer generates its own key pair
      peer1KeyExchange = await ECDHKeyExchangeService.generateNew()
          as ECDHKeyExchangeService;
      peer2KeyExchange = await ECDHKeyExchangeService.generateNew()
          as ECDHKeyExchangeService;

      // Create peer ciphers for managing encryption/decryption
      peer1Cipher = createErmesPeerCipher();
      peer2Cipher = createErmesPeerCipher();

      // Each peer generates a symmetric cipher using the other's public key
      final peer2Serialized = peer2KeyExchange.serialize();
      peer1ToP2Cipher = peer1KeyExchange.generateISymmetric(peer2Serialized);

      final peer1Serialized = peer1KeyExchange.serialize();
      peer2ToP1Cipher = peer2KeyExchange.generateISymmetric(peer1Serialized);

      // Register ciphers for asymmetric encryption/decryption
      peer1Cipher
        ..addEncryptCipher(peer1ToP2Cipher)
        ..addDecryptCipher(peer2ToP1Cipher);

      peer2Cipher
        ..addEncryptCipher(peer2ToP1Cipher)
        ..addDecryptCipher(peer1ToP2Cipher);

      // Create key exchange handlers
      peer1KeyExchangeHandler = ErmesPeerKeyExchange(peer1Cipher);
      peer2KeyExchangeHandler = ErmesPeerKeyExchange(peer2Cipher);
    });

    group('Symmetric Cipher Exchange', () {
      test('peer1 can prepare encrypted symmetric cipher for peer2', () {
        // Use hex-encoded key (64 chars = 32 bytes = 256-bit AES key)
        final symmetricCipher = generateSymmetric(
          'a' * 64,
          SymmetricAlgorithm.aes,
        );

        final encrypted = peer1KeyExchangeHandler
            .prepareEncryptedSymmetricKey(symmetricCipher);

        expect(encrypted, isNotNull);
        expect(encrypted.keyId, isNotNull);
        expect(encrypted.encryptedData, isNotEmpty);
      });

      test('peer2 can deserialize cipher prepared by peer1', () {
        final originalCipher = generateSymmetric(
          'b' * 64,
          SymmetricAlgorithm.aes,
        );

        // Peer1 prepares the encrypted cipher
        final encrypted =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(originalCipher);

        // Peer2 deserializes it
        final deserializedCipher =
            peer2KeyExchangeHandler.deserialize(encrypted);

        expect(deserializedCipher, isNotNull);
        expect(deserializedCipher.algorithm, equals(originalCipher.algorithm));
        expect(deserializedCipher.key, equals(originalCipher.key));
      });

      test('exchanged cipher works for encryption/decryption', () {
        final originalCipher = generateSymmetric(
          'c' * 64,
          SymmetricAlgorithm.aes,
        );

        // Peer1 prepares and encrypts the symmetric cipher
        final encrypted =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(originalCipher);

        // Peer2 deserializes it
        final deserializedCipher =
            peer2KeyExchangeHandler.deserialize(encrypted);

        // Verify the deserialized cipher can encrypt/decrypt
        final testData = [72, 101, 108, 108, 111]; // "Hello"
        final encryptedData = deserializedCipher.encrypt(testData);
        final decryptedData = deserializedCipher.decrypt(encryptedData);

        expect(decryptedData, equals(testData));
      });

      test('bidirectional exchange of symmetric ciphers', () {
        // Peer1 creates a cipher and sends it to peer2
        final peer1Symmetric = generateSymmetric(
          'd' * 64,
          SymmetricAlgorithm.aes,
        );
        final encrypted1 = peer1KeyExchangeHandler
            .prepareEncryptedSymmetricKey(peer1Symmetric);
        final deserializedAt2 = peer2KeyExchangeHandler.deserialize(encrypted1);

        // Peer2 creates a cipher and sends it to peer1
        final peer2Symmetric = generateSymmetric(
          'e' * 64,
          SymmetricAlgorithm.aes,
        );
        final encrypted2 = peer2KeyExchangeHandler
            .prepareEncryptedSymmetricKey(peer2Symmetric);
        final deserializedAt1 = peer1KeyExchangeHandler.deserialize(encrypted2);

        // Both deserialized ciphers should work correctly
        expect(deserializedAt2.key, equals(peer1Symmetric.key));
        expect(deserializedAt1.key, equals(peer2Symmetric.key));

        // And they should work for encryption/decryption
        final testMsg = [1, 2, 3, 4, 5];
        final enc1 = deserializedAt2.encrypt(testMsg);
        final dec1 = deserializedAt2.decrypt(enc1);
        expect(dec1, equals(testMsg));

        final enc2 = deserializedAt1.encrypt(testMsg);
        final dec2 = deserializedAt1.decrypt(enc2);
        expect(dec2, equals(testMsg));
      });
    });

    group('Algorithm Preservation', () {
      test('AES algorithm is preserved during exchange', () {
        final aesCipher = generateSymmetric(
          'f' * 64,
          SymmetricAlgorithm.aes,
        );

        final encrypted =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(aesCipher);
        final deserialized = peer2KeyExchangeHandler.deserialize(encrypted);

        expect(deserialized.algorithm, equals(SymmetricAlgorithm.aes));
      });

      test('DES algorithm is preserved during exchange', () {
        // DES requires 16-char hex key (8 bytes)
        final desCipher = generateSymmetric(
          '1234567890abcdef',
          SymmetricAlgorithm.des,
        );

        final encrypted =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(desCipher);
        final deserialized = peer2KeyExchangeHandler.deserialize(encrypted);

        expect(deserialized.algorithm, equals(SymmetricAlgorithm.des));
      });
    });

    group('Key Material Integrity', () {
      test('original key material is recovered exactly', () {
        final originalKey = 'g' * 64;
        final cipher = generateSymmetric(
          originalKey,
          SymmetricAlgorithm.aes,
        );

        final encrypted =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher);
        final deserialized = peer2KeyExchangeHandler.deserialize(encrypted);

        expect(deserialized.key, equals(originalKey));
      });

      test('different keys produce different encrypted output', () {
        final cipher1 = generateSymmetric(
          'h' * 64,
          SymmetricAlgorithm.aes,
        );
        final cipher2 = generateSymmetric(
          'i' * 64,
          SymmetricAlgorithm.aes,
        );

        final encrypted1 =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher1);
        final encrypted2 =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher2);

        expect(encrypted1.encryptedData, isNot(equals(encrypted2.encryptedData)));
      });
    });

    group('Error Handling', () {
      test('deserialize with wrong peer cipher fails appropriately', () async {
        // Create a third peer with different key agreement
        final peer3KeyExchange =
            await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
        final peer3Cipher = createErmesPeerCipher();

        // Create cipher that peer3 can decrypt (but NOT the one from peer1->peer2)
        final peer3ToP1 =
            peer3KeyExchange.generateISymmetric(peer1KeyExchange.serialize());
        peer3Cipher.addDecryptCipher(peer3ToP1);

        // Create handler for peer3
        final peer3Handler = ErmesPeerKeyExchange(peer3Cipher);

        // Prepare cipher from peer1 (encrypted with peer1->peer2 asymmetric cipher)
        final originalCipher = generateSymmetric(
          'j' * 64,
          SymmetricAlgorithm.aes,
        );
        final encrypted =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(originalCipher);

        // Peer3 trying to decrypt with wrong cipher should fail
        expect(
          () => peer3Handler.deserialize(encrypted),
          throwsA(isA<CipherException>()),
        );
      });

      test('unsupported algorithm throws exception', () {
        // Manually create an encrypted data with invalid algorithm byte
        final invalidEncrypted = DataEncrypted(
          peer1ToP2Cipher.keyId,
          [0xFF, 1, 2, 3], // 0xFF is not a valid algorithm byte
        );

        expect(
          () => peer2KeyExchangeHandler.deserialize(invalidEncrypted),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Multiple Sequential Exchanges', () {
      test('can exchange multiple AES ciphers in sequence', () {
        for (var i = 0; i < 3; i++) {
          final cipher = generateSymmetric(
            String.fromCharCode(97 + i) * 64, // 'a' * 64, 'b' * 64, 'c' * 64
            SymmetricAlgorithm.aes,
          );

          final encrypted =
              peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher);
          final deserialized = peer2KeyExchangeHandler.deserialize(encrypted);

          expect(deserialized.key, equals(cipher.key));
          expect(deserialized.algorithm, equals(cipher.algorithm));
        }
      });

      test('bidirectional multiple exchanges maintain integrity', () {
        const exchanges = 3;

        for (var i = 0; i < exchanges; i++) {
          // Peer1 -> Peer2
          final cipher1 = generateSymmetric(
            String.fromCharCode(107 + (i * 2)) * 64,
            SymmetricAlgorithm.aes,
          );
          final enc1 =
              peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher1);
          final dec1 = peer2KeyExchangeHandler.deserialize(enc1);
          expect(dec1.key, equals(cipher1.key));

          // Peer2 -> Peer1
          final cipher2 = generateSymmetric(
            String.fromCharCode(108 + (i * 2)) * 64,
            SymmetricAlgorithm.aes,
          );
          final enc2 =
              peer2KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher2);
          final dec2 = peer1KeyExchangeHandler.deserialize(enc2);
          expect(dec2.key, equals(cipher2.key));
        }
      });
    });

    group('Encrypted Data Integrity', () {
      test('encrypted data cannot be decrypted by peer with only decrypt cipher',
          () async {
        // Setup: Create a new cipher that peer1 doesn't have in their decrypt ciphers
        // This ensures peer1 can encrypt but cannot decrypt their own encrypted data
        final peer3KeyExchange =
            await ECDHKeyExchangeService.generateNew()
                as ECDHKeyExchangeService;
        final peer3ToP1Cipher =
            peer3KeyExchange.generateISymmetric(peer1KeyExchange.serialize());

        // Create a test cipher
        final cipher = generateSymmetric(
          '5' * 64,
          SymmetricAlgorithm.aes,
        );

        // Manually encrypt data with a cipher that peer1 doesn't have for decryption
        final peer3Cipher = createErmesPeerCipher();
        peer3Cipher.addEncryptCipher(peer3ToP1Cipher);

        final peer3KeyExchangeHandler = ErmesPeerKeyExchange(peer3Cipher);
        final encrypted =
            peer3KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher);

        // Now try to decrypt with peer1's handler
        // peer1 doesn't have the decrypt cipher for peer3's encryption
        expect(
          () => peer1KeyExchangeHandler.deserialize(encrypted),
          throwsA(isA<CipherException>()),
        );
      });

      test('tampering with encrypted data fails during decryption', () {
        final cipher = generateSymmetric(
          '6' * 64,
          SymmetricAlgorithm.aes,
        );

        final encrypted =
            peer1KeyExchangeHandler.prepareEncryptedSymmetricKey(cipher);

        if (encrypted.encryptedData.length > 6) {
          // Tamper with the encrypted data
          final tamperedData = [
            ...encrypted.encryptedData.sublist(0, 5),
            0xFF,
            ...encrypted.encryptedData.sublist(6),
          ];
          final tamperedEncrypted =
              DataEncrypted(encrypted.keyId, tamperedData);

          // Tampering should cause decryption to fail
          expect(
            () => peer2KeyExchangeHandler.deserialize(tamperedEncrypted),
            throwsA(isA<Exception>()),
          );
        }
      });
    });
  });
}
