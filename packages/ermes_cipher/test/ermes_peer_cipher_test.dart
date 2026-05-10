import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptdart/cryptdart.dart';
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
      cipher.addEncryptCipher(aesCipher);
      cipher.addDecryptCipher(aesCipher);

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
      cipher.addEncryptCipher(aesCipher);
      cipher.removeEncryptCipher(aesCipher.keyId);
      expect(
        () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });

    test('should remove decrypt cipher', () {
      cipher.addDecryptCipher(aesCipher);
      cipher.removeDecryptCipher(aesCipher.keyId);

      cipher.addEncryptCipher(aesCipher);
      final encrypted = cipher.encrypt(Uint8List.fromList([1, 2, 3]));
      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('should handle multiple ciphers', () {
      final aesCipher2 = AESCipher.createFull(InputAESCipher(
        parent: InputSymmetricCipher(
          parent: InputCipher(
            parent: InputExpirationBase(),
          ),
          key: 'fedcba9876543210fedcba9876543210',
        ),
      ));

      cipher.addEncryptCipher(aesCipher);
      cipher.addEncryptCipher(aesCipher2);
      cipher.addDecryptCipher(aesCipher);
      cipher.addDecryptCipher(aesCipher2);

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

      cipher.addEncryptCipher(expiredCipher);
      cipher.addDecryptCipher(expiredCipher);
      cipher.clearOldEncryptCipher();
      cipher.clearOldDecryptCipher();

      expect(
        () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });
  });
}
