import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesPeerCipherCurrentKey();
}

/// Tests the explicit current-outbound-key pointer (RFC 7.4) against the
/// [IErmesPeerCipher] interface.
void testErmesPeerCipherCurrentKey() {
  group('IErmesPeerCipher current outbound key', () {
    late IErmesPeerCipher cipher;
    late ISymmetricCipher k0;
    late ISymmetricCipher k1;
    final data = Uint8List.fromList([1, 2, 3, 4]);

    setUp(() {
      cipher = ErmesPeerCipher();
      k0 = generateSymmetric('0' * 64, SymmetricAlgorithm.aes);
      k1 = generateSymmetric('1' * 64, SymmetricAlgorithm.aes);
    });

    test('the last key added as current encrypts, regardless of expiry', () {
      cipher
        ..addEncryptCipher(k0)
        ..addEncryptCipher(k1);
      expect(cipher.currentEncryptKeyId, equals(k1.keyId));
      expect(cipher.encrypt(data).keyId, equals(k1.keyId));
    });

    test('makeCurrent: false keeps the previous key current', () {
      cipher
        ..addEncryptCipher(k0)
        ..addEncryptCipher(k1, makeCurrent: false);
      expect(cipher.encrypt(data).keyId, equals(k0.keyId));
    });

    test('first key becomes current even with makeCurrent: false', () {
      cipher.addEncryptCipher(k0, makeCurrent: false);
      expect(cipher.currentEncryptKeyId, equals(k0.keyId));
    });

    test('setCurrentEncryptCipher moves the pointer', () {
      cipher
        ..addEncryptCipher(k0)
        ..addEncryptCipher(k1, makeCurrent: false)
        ..setCurrentEncryptCipher(k1.keyId);
      expect(cipher.encrypt(data).keyId, equals(k1.keyId));
    });

    test('setCurrentEncryptCipher throws for an unknown key', () {
      cipher.addEncryptCipher(k0);
      expect(
        () => cipher.setCurrentEncryptCipher(k1.keyId),
        throwsA(isA<CipherException>()),
      );
      expect(cipher.currentEncryptKeyId, equals(k0.keyId));
    });

    test('currentEncryptKeyId and encrypt throw when no key is set', () {
      expect(() => cipher.currentEncryptKeyId, throwsA(isA<CipherException>()));
      expect(() => cipher.encrypt(data), throwsA(isA<CipherException>()));
      expect(cipher.hasEncryptCipher, isFalse);
    });

    test('removing the current key falls back to the remaining one', () {
      cipher
        ..addEncryptCipher(k0)
        ..addEncryptCipher(k1)
        ..removeEncryptCipher(k1.keyId);
      expect(cipher.currentEncryptKeyId, equals(k0.keyId));
      cipher.removeEncryptCipher(k0.keyId);
      expect(cipher.hasEncryptCipher, isFalse);
    });

    test('an expired current key is dropped', () {
      final expired = generateSymmetric(
        '2' * 64,
        SymmetricAlgorithm.aes,
        DateTime.now().subtract(const Duration(seconds: 1)),
      );
      cipher
        ..addEncryptCipher(k0)
        ..addEncryptCipher(expired);
      expect(cipher.currentEncryptKeyId, equals(k0.keyId));
    });
  });
}
