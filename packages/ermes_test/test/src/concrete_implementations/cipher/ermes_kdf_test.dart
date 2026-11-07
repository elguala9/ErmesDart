import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart' show SymmetricAlgorithm;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesKdf();
}

/// Decodes a lowercase hex string into bytes.
Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

/// Tests the HKDF-SHA256 session-key derivation (RFC section 8.1).
void testErmesKdf() {
  group('ErmesKdf', () {
    test('matches RFC 5869 test case 1', () {
      final okm = ermesHkdfSha256(
        ErmesKdfInput(
          ikm: Uint8List.fromList(List.filled(22, 0x0b)),
          salt: _hex('000102030405060708090a0b0c'),
          info: _hex('f0f1f2f3f4f5f6f7f8f9'),
          length: 42,
        ),
      );
      expect(
        okm,
        equals(
          _hex(
            '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4'
            'c5bf34007208d5b887185865',
          ),
        ),
      );
    });

    test('info carries protocol label and address family', () {
      expect(
        ermesSessionInfo(ErmesConnectionContext.ipv4),
        equals('ermes-v3|ipv4'),
      );
      expect(
        ermesSessionInfo(ErmesConnectionContext.ipv6),
        equals('ermes-v3|ipv6'),
      );
    });

    test('salt does not depend on public key order', () {
      expect(
        ermesSessionSalt('aa', 'bb'),
        equals(ermesSessionSalt('bb', 'aa')),
      );
      expect(
        ermesSessionSalt('aa', 'bb'),
        isNot(equals(ermesSessionSalt('aa', 'cc'))),
      );
    });

    test('empty input keying material throws CipherException', () {
      expect(
        () => ermesHkdfSha256(
          ErmesKdfInput(
            ikm: Uint8List(0),
            salt: Uint8List(0),
            info: Uint8List(0),
          ),
        ),
        throwsA(isA<CipherException>()),
      );
    });

    test('out-of-range output length throws CipherException', () {
      expect(
        () => ermesHkdfSha256(
          ErmesKdfInput(
            ikm: Uint8List(1),
            salt: Uint8List(0),
            info: Uint8List(0),
            length: 0,
          ),
        ),
        throwsA(isA<CipherException>()),
      );
    });

    group('deriveSharedSecretCipher with connection context', () {
      late ECDHKeyExchangeService a;
      late ECDHKeyExchangeService b;
      final payload = Uint8List.fromList([1, 2, 3, 4]);

      setUp(() async {
        a = await ECDHKeyExchangeService.generateNewService();
        b = await ECDHKeyExchangeService.generateNewService();
      });

      test('same context on both sides yields the same key', () {
        const ctx = ErmesConnectionContext.ipv6;
        final ca = deriveSharedSecretCipher(a, b.publicKey, ctx);
        final cb = deriveSharedSecretCipher(b, a.publicKey, ctx);
        expect(ca.keyId, equals(cb.keyId));
        expect(cb.decrypt(ca.encrypt(payload)), equals(payload));
      });

      test('different context yields a different key', () {
        final v4 = deriveSharedSecretCipher(
          a,
          b.publicKey,
          ErmesConnectionContext.ipv4,
        );
        final v6 = deriveSharedSecretCipher(
          a,
          b.publicKey,
          ErmesConnectionContext.ipv6,
        );
        expect(v4.keyId, isNot(equals(v6.keyId)));
        expect(() => v6.decrypt(v4.encrypt(payload)), throwsA(anything));
      });

      test('unsupported algorithm throws CipherException', () {
        expect(
          () => deriveSharedSecretCipher(
            a,
            b.publicKey,
            ErmesConnectionContext.ipv4,
            SymmetricAlgorithm.hmac,
          ),
          throwsA(isA<CipherException>()),
        );
      });
    });
  });
}
