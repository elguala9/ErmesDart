import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesCipherFactories', () {
    test('createErmesPeerCipher should return a valid cipher', () {
      final cipher = createErmesPeerCipher();
      expect(cipher, isA<IErmesPeerCipher>());
    });

    test('createCipher should create symmetric cipher from KeyInfo', () {
      final now = DateTime.now();
      final keyInfo = KeyInfo(
        '0123456789abcdef0123456789abcdef',
        now,
        now.add(const Duration(hours: 1)),
        SymmetricAlgorithm.aes,
      );

      final cipher = createCipher(keyInfo);
      expect(cipher, isA<ISymmetricCipher>());
      expect(cipher.algorithm, equals(SymmetricAlgorithm.aes));
    });

    test('createCipher should reject invalid AES key length', () {
      final now = DateTime.now();
      final keyInfo = KeyInfo(
        '0123456789abcdef',
        now,
        now.add(const Duration(hours: 1)),
        SymmetricAlgorithm.aes,
      );

      expect(() => createCipher(keyInfo), throwsException);
    });

    test('createSigner should create HMAC signer', () {
      final now = DateTime.now();
      final keyInfo = KeyInfo(
        'my-hmac-key',
        now,
        now.add(const Duration(hours: 1)),
        SymmetricAlgorithm.hmac,
      );

      final signer = createSigner(keyInfo);
      expect(signer, isA<ISign>());
    });

    test('generateSymmetric should create AES cipher', () {
      final cipher = generateSymmetric(
        '0123456789abcdef0123456789abcdef',
        SymmetricAlgorithm.aes,
      );

      expect(cipher, isA<ISymmetricCipher>());
      expect(cipher.algorithm, equals(SymmetricAlgorithm.aes));
    });

    test('generateSymmetric should create DES cipher', () {
      final cipher = generateSymmetric(
        '0123456789abcdef',
        SymmetricAlgorithm.des,
      );

      expect(cipher, isA<ISymmetricCipher>());
      expect(cipher.algorithm, equals(SymmetricAlgorithm.des));
    });

    test('generateSymmetric should accept Uint8List key', () {
      final keyBytes = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        keyBytes[i] = i;
      }

      final cipher = generateSymmetric(keyBytes, SymmetricAlgorithm.aes);
      expect(cipher, isA<ISymmetricCipher>());
    });
  });
}
