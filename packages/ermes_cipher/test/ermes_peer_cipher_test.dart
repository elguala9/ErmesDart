import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesPeerCipher', () {
    late ErmesPeerCipher cipher;
    late ISymmetricCipher aesCipher;

    setUp(() {
      cipher = ErmesPeerCipher();
      aesCipher = AESCipher.createFull(InputAESCipher(
        parent: InputSymmetricCipher(
          parent: InputCipher(
            parent: InputExpirationBase(
              expirationDate: DateTime.now().add(const Duration(hours: 1)),
            ),
          ),
          key: '0123456789abcdef0123456789abcdef',
        ),
      ));
    });

    test('should encrypt and decrypt data', () {
      cipher
        ..addEncryptCipher(aesCipher)
        ..addDecryptCipher(aesCipher);

      final originalData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final encrypted = cipher.encrypt(originalData);
      final decrypted = cipher.decrypt(encrypted);

      expect(decrypted, equals(originalData));
    });

    test('should throw CipherException when no encryption cipher', () {
      expect(
        () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });

    test('should throw CipherException when decrypt key not found', () {
      final encrypted = DataEncrypted(
        Digest([1, 2, 3]),
        Uint8List.fromList([1, 2, 3]),
      );
      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('should remove encrypt cipher', () {
      cipher
        ..addEncryptCipher(aesCipher)
        ..removeEncryptCipher(aesCipher.keyId);
      expect(
        () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });

    test('should remove decrypt cipher', () {
      cipher
        ..addDecryptCipher(aesCipher)
        ..removeDecryptCipher(aesCipher.keyId)
        ..addEncryptCipher(aesCipher);
      final encrypted = cipher.encrypt(Uint8List.fromList([1, 2, 3]));
      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('should handle multiple ciphers', () {
      final aesCipher2 = AESCipher.createFull(const InputAESCipher(
        parent: InputSymmetricCipher(
          parent: InputCipher(
            parent: InputExpirationBase(),
          ),
          key: 'fedcba9876543210fedcba9876543210',
        ),
      ));

      cipher
        ..addEncryptCipher(aesCipher)
        ..addEncryptCipher(aesCipher2)
        ..addDecryptCipher(aesCipher)
        ..addDecryptCipher(aesCipher2);

      final data = Uint8List.fromList([10, 20, 30]);
      final encrypted = cipher.encrypt(data);
      final decrypted = cipher.decrypt(encrypted);

      expect(decrypted, equals(data));
    });

    test('should handle expired ciphers gracefully', () {
      final expiredCipher = AESCipher.createFull(InputAESCipher(
        parent: InputSymmetricCipher(
          parent: InputCipher(
            parent: InputExpirationBase(
              expirationDate: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ),
          key: '0123456789abcdef0123456789abcdef',
        ),
      ));

      cipher
        ..addEncryptCipher(expiredCipher)
        ..addDecryptCipher(expiredCipher)
        ..clearOldEncryptCipher()
        ..clearOldDecryptCipher();

      expect(
        () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });
  });
}
