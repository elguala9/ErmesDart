import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesPeerCipherImplementation();
}

void testErmesPeerCipherImplementation() {
  group('ErmesPeerCipher', () {
    late ErmesPeerCipher cipher;
    late ISymmetricCipher realCipher1;
    late ISymmetricCipher realCipher2;

    setUp(() {
      cipher = ErmesPeerCipher();
      realCipher1 = generateSymmetric('1' * 64, SymmetricAlgorithm.aes);
      realCipher2 = generateSymmetric('2' * 64, SymmetricAlgorithm.aes);
    });

    test('encrypt throws CipherException when no encryption cipher available',
        () {
      expect(
        () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });

    test('addEncryptCipher adds cipher to encryption list', () {
      cipher.addEncryptCipher(realCipher1);
      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = cipher.encrypt(data);
      expect(encrypted.encryptedData, isNotEmpty);
      expect(encrypted.keyId, equals(realCipher1.keyId));
    });

    test('addDecryptCipher allows decryption with correct keyId', () {
      final realCipher = generateSymmetric('3' * 64, SymmetricAlgorithm.aes);
      cipher.addDecryptCipher(realCipher);

      // Encrypt actual data first to get valid encrypted output
      final plaintext = Uint8List.fromList(
        [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
      );
      final encryptedData = realCipher.encrypt(plaintext);
      final encrypted = DataEncrypted(
        realCipher.keyId,
        Uint8List.fromList(encryptedData),
      );

      expect(
        () => cipher.decrypt(encrypted),
        returnsNormally,
      );
    });

    test('decrypt throws CipherException when cipher not found', () {
      final unknownCipher = generateSymmetric(
        '999' * 21 + '9' * 1,
        SymmetricAlgorithm.aes,
      );
      final plaintext = Uint8List.fromList(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      );
      final encryptedData = unknownCipher.encrypt(plaintext);
      final encrypted = DataEncrypted(
        unknownCipher.keyId,
        Uint8List.fromList(encryptedData),
      );

      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test(
      'encrypt uses one of the available ciphers when multiple are added',
      () {
        cipher
          ..addEncryptCipher(realCipher1)
          ..addEncryptCipher(realCipher2);

        final data = Uint8List.fromList([1, 2, 3]);
        final encrypted = cipher.encrypt(data);

        // Should use one of the two ciphers
        expect(
          encrypted.keyId,
          anyOf(equals(realCipher1.keyId), equals(realCipher2.keyId)),
        );
      },
    );

    test('clearOldEncryptCipher removes expired encryption ciphers', () {
      cipher
        ..addEncryptCipher(realCipher1)
        ..clearOldEncryptCipher();

      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = cipher.encrypt(data);

      // Should use realCipher1 since it's not expired
      expect(encrypted.keyId, equals(realCipher1.keyId));
    });

    test('clearOldDecryptCipher removes expired decryption ciphers', () {
      final realCipher = generateSymmetric('5' * 64, SymmetricAlgorithm.aes);
      cipher
        ..addDecryptCipher(realCipher)
        ..clearOldDecryptCipher();

      final plaintext = Uint8List.fromList(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      );
      final encryptedData = realCipher.encrypt(plaintext);
      final encrypted = DataEncrypted(
        realCipher.keyId,
        Uint8List.fromList(encryptedData),
      );

      expect(
        () => cipher.decrypt(encrypted),
        returnsNormally,
      );
    });

    test('removeEncryptCipher removes specific encryption cipher', () {
      cipher
        ..addEncryptCipher(realCipher1)
        ..addEncryptCipher(realCipher2)
        ..removeEncryptCipher(realCipher2.keyId);

      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = cipher.encrypt(data);

      expect(encrypted.keyId, equals(realCipher1.keyId));
    });

    test('removeDecryptCipher removes specific decryption cipher', () {
      cipher
        ..addDecryptCipher(realCipher1)
        ..removeDecryptCipher(realCipher1.keyId);

      final plaintext = Uint8List.fromList(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      );
      final encryptedData = realCipher1.encrypt(plaintext);
      final encrypted = DataEncrypted(
        realCipher1.keyId,
        Uint8List.fromList(encryptedData),
      );

      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('roundtrip encrypt and decrypt', () {
      final testCipher = generateSymmetric('10' * 32, SymmetricAlgorithm.aes);

      cipher
        ..addEncryptCipher(testCipher)
        ..addDecryptCipher(testCipher);

      // "Hello"
      final originalData = Uint8List.fromList([72, 101, 108, 108, 111]);
      final encrypted = cipher.encrypt(originalData);
      final decrypted = cipher.decrypt(encrypted);

      expect(decrypted, equals(originalData));
    });
  });
}
