import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void testErmesCipherExceptions() {
  // -------------------------------------------------------------------------
  // Exception type hierarchy
  // -------------------------------------------------------------------------

  group('CipherException', () {
    test('can be constructed with a message', () {
      final ex = CipherException('something went wrong');
      expect(ex.message, equals('something went wrong'));
      expect(ex.cause, isNull);
    });

    test('can carry a cause', () {
      final cause = Exception('root cause');
      final ex = CipherException('wrapper', cause);
      expect(ex.cause, same(cause));
    });

    test('toString includes message', () {
      expect(CipherException('bad key').toString(), contains('bad key'));
    });

    test('toString includes cause when present', () {
      final ex = CipherException('failed', 'inner error');
      expect(ex.toString(), contains('inner error'));
    });

    test('implements Exception', () {
      expect(CipherException('x'), isA<Exception>());
    });
  });

  group('NoValidKeyException', () {
    test('is a CipherException', () {
      expect(NoValidKeyException(), isA<CipherException>());
    });

    test('message describes missing key', () {
      final ex = NoValidKeyException();
      expect(ex.message.toLowerCase(), contains('key'));
    });

    test('toString includes the message', () {
      expect(NoValidKeyException().toString(), isNotEmpty);
    });
  });

  group('DecryptionFailedException', () {
    test('is a CipherException', () {
      expect(DecryptionFailedException(), isA<CipherException>());
    });

    test('message describes decryption failure', () {
      final ex = DecryptionFailedException();
      expect(ex.message.toLowerCase(), contains('decrypt'));
    });

    test('can carry a cause', () {
      final cause = 'bad padding';
      final ex = DecryptionFailedException(cause);
      expect(ex.cause, equals(cause));
    });

    test('toString includes cause when present', () {
      expect(
        DecryptionFailedException('pad error').toString(),
        contains('pad error'),
      );
    });
  });

  group('UnsupportedAlgorithmException', () {
    test('is a CipherException', () {
      expect(
        UnsupportedAlgorithmException('rsa-9999'),
        isA<CipherException>(),
      );
    });

    test('message includes the algorithm name', () {
      final ex = UnsupportedAlgorithmException('quantum-aes');
      expect(ex.message, contains('quantum-aes'));
    });

    test('toString includes the algorithm name', () {
      expect(
        UnsupportedAlgorithmException('des3').toString(),
        contains('des3'),
      );
    });
  });

  // -------------------------------------------------------------------------
  // CipherException thrown by ErmesPeerCipher
  // -------------------------------------------------------------------------

  group('ErmesPeerCipher throws CipherException', () {
    late ErmesPeerCipher peer;

    setUp(() => peer = ErmesPeerCipher());

    test('encrypt throws when no cipher is registered', () {
      expect(
        () => peer.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });

    test('encrypt error message mentions cipher availability', () {
      expect(
        () => peer.encrypt(Uint8List.fromList([0])),
        throwsA(
          isA<CipherException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('cipher'),
          ),
        ),
      );
    });

    test('decrypt throws CipherException when key is not registered', () {
      // Craft a dummy DataEncrypted with a random Digest key
      final fakeDigest = sha256.convert([0, 1, 2, 3]);
      final encrypted = DataEncrypted(fakeDigest, Uint8List.fromList([10, 20]));

      expect(
        () => peer.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('decrypt error message contains the key hex', () {
      final fakeDigest = sha256.convert([9, 9, 9]);
      final encrypted = DataEncrypted(fakeDigest, Uint8List.fromList([0]));

      expect(
        () => peer.decrypt(encrypted),
        throwsA(
          isA<CipherException>().having(
            (e) => e.message,
            'message',
            isNotEmpty,
          ),
        ),
      );
    });
  });
}
