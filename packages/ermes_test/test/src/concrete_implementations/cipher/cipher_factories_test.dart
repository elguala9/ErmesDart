import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testCipherFactories();
}

void testCipherFactories() {
  group('Cipher Factories', () {
    group('createErmesPeerCipher', () {
      test('creates new instance each time', () {
        final cipher1 = createErmesPeerCipher();
        final cipher2 = createErmesPeerCipher();

        expect(identical(cipher1, cipher2), isFalse);
      });

      test('returns IErmesPeerCipher interface', () {
        final cipher = createErmesPeerCipher();

        expect(cipher, isA<IErmesPeerCipher>());
      });

      test('new cipher throws on encrypt without ciphers', () {
        final cipher = createErmesPeerCipher();

        expect(
          () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
          throwsA(isA<CipherException>()),
        );
      });
    });

    group('createCipher', () {
      test('creates AES cipher from KeyInfo', () {
        final now = DateTime.now();
        final keyInfo = KeyInfo(
          'a' * 64, // 32 bytes hex = 256-bit key
          now,
          now.add(const Duration(hours: 1)),
          SymmetricCipherAlgorithmEnum.aes,
        );

        final cipher = createCipher(keyInfo);

        expect(cipher, isA<ISymmetricCipher>());
        expect(cipher, isA<AESCipher>());
      });

      test('creates DES cipher from KeyInfo', () {
        final now = DateTime.now();
        final keyInfo = KeyInfo(
          'c' * 32, // 16 bytes hex = 128-bit key (2x DES block)
          now,
          now.add(const Duration(hours: 1)),
          SymmetricCipherAlgorithmEnum.des,
        );

        final cipher = createCipher(keyInfo);

        expect(cipher, isA<ISymmetricCipher>());
        expect(cipher, isA<DESCipher>());
      });

      test('cipher respects expiration from KeyInfo', () {
        final now = DateTime.now();
        final expiration = now.add(const Duration(hours: 1));
        final keyInfo = KeyInfo(
          'd' * 64,
          now,
          expiration,
          SymmetricCipherAlgorithmEnum.aes,
        );

        final cipher = createCipher(keyInfo);

        expect(cipher.expirationDate, isNotNull);
        // Allow small time difference due to test execution
        final diff = cipher.expirationDate!.difference(expiration).inSeconds;
        expect(diff.abs(), lessThan(2));
      });

      test('AES cipher can encrypt and decrypt', () {
        final now = DateTime.now();
        final keyInfo = KeyInfo(
          'e' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricCipherAlgorithmEnum.aes,
        );

        final cipher = createCipher(keyInfo);
        final plaintext = [72, 101, 108, 108, 111]; // "Hello"
        final encrypted = cipher.encrypt(plaintext);

        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(plaintext)));

        final decrypted = cipher.decrypt(encrypted);
        expect(decrypted, equals(plaintext));
      });

      test('different key produces different ciphertext', () {
        final now = DateTime.now();
        final keyInfo1 = KeyInfo(
          'a' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricCipherAlgorithmEnum.aes,
        );
        final keyInfo2 = KeyInfo(
          'b' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricCipherAlgorithmEnum.aes,
        );

        final cipher1 = createCipher(keyInfo1);
        final cipher2 = createCipher(keyInfo2);

        final plaintext = [1, 2, 3, 4, 5];
        final encrypted1 = cipher1.encrypt(plaintext);
        final encrypted2 = cipher2.encrypt(plaintext);

        expect(encrypted1, isNot(equals(encrypted2)));
      });
    });

    group('createSigner', () {
      test('creates HMAC signer from KeyInfo', () {
        final now = DateTime.now();
        final keyInfo = KeyInfo(
          'a' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricAlgorithm.hmac,
        );

        final signer = createSigner(keyInfo);

        expect(signer, isA<ISign>());
        expect(signer, isA<HMACSign>());
      });

      test('signer respects expiration from KeyInfo', () {
        final now = DateTime.now();
        final expiration = now.add(const Duration(hours: 2));
        final keyInfo = KeyInfo(
          'b' * 64,
          now,
          expiration,
          SymmetricAlgorithm.hmac,
        );

        final signer = createSigner(keyInfo);

        expect(signer.expirationDate, isNotNull);
        // Allow small time difference due to test execution
        final diff = signer.expirationDate!.difference(expiration).inSeconds;
        expect(diff.abs(), lessThan(2));
      });

      test('throws on unsupported signer algorithm', () {
        final now = DateTime.now();
        final keyInfo = KeyInfo(
          'c' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricCipherAlgorithmEnum.aes, // Not a signer algorithm
        );

        expect(
          () => createSigner(keyInfo),
          throwsA(isA<Exception>()),
        );
      });

      test('HMAC signer can sign data', () {
        final now = DateTime.now();
        final keyInfo = KeyInfo(
          'd' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricAlgorithm.hmac,
        );

        final signer = createSigner(keyInfo);
        final data = [72, 101, 108, 108, 111]; // "Hello"

        final signature = signer.sign(data);

        expect(signature, isNotNull);
        expect(signature, isNotEmpty);
      });

      test('same key produces same HMAC signature', () {
        final now = DateTime.now();
        final keyInfo = KeyInfo(
          'e' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricAlgorithm.hmac,
        );

        final signer1 = createSigner(keyInfo);
        final signer2 = createSigner(keyInfo);

        final data = [1, 2, 3, 4, 5];
        final sig1 = signer1.sign(data);
        final sig2 = signer2.sign(data);

        expect(sig1, equals(sig2));
      });

      test('different key produces different HMAC signature', () {
        final now = DateTime.now();
        final keyInfo1 = KeyInfo(
          'a' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricAlgorithm.hmac,
        );
        final keyInfo2 = KeyInfo(
          'b' * 64,
          now,
          now.add(const Duration(hours: 1)),
          SymmetricAlgorithm.hmac,
        );

        final signer1 = createSigner(keyInfo1);
        final signer2 = createSigner(keyInfo2);

        final data = [1, 2, 3, 4, 5];
        final sig1 = signer1.sign(data);
        final sig2 = signer2.sign(data);

        expect(sig1, isNot(equals(sig2)));
      });
    });

    group('Algorithm Compatibility', () {
      test('all symmetric algorithms supported by createCipher', () {
        final algorithms = [
          SymmetricCipherAlgorithmEnum.aes,
          SymmetricCipherAlgorithmEnum.des,
        ];

        for (final alg in algorithms) {
          final now = DateTime.now();
          final keyInfo = KeyInfo(
            'a' * 64,
            now,
            now.add(const Duration(hours: 1)),
            alg,
          );

          expect(() => createCipher(keyInfo), returnsNormally);
        }
      });
    });
  });
}
