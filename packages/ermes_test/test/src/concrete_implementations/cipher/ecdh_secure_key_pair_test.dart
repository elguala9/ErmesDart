import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:test/test.dart';

void main() => testEcdhSecureKeyPair();

/// Tests that ECDH key pairs come from an OS-seeded PRNG: back-to-back
/// generations must never collide (cryptdart's own seeding has only 256
/// distinct seeds, which made directional-key tests flaky).
void testEcdhSecureKeyPair() {
  group('Secure ECDH key pair', () {
    test('back-to-back key pairs are all distinct', () {
      final keys = {
        for (var i = 0; i < 300; i++) generateSecureEcdhKeyPair().publicKey,
      };
      expect(keys, hasLength(300));
    });

    test('generateNewService yields distinct public keys', () async {
      final keys = <String>{};
      for (var i = 0; i < 100; i++) {
        keys.add((await ECDHKeyExchangeService.generateNewService()).publicKey);
      }
      expect(keys, hasLength(100));
    });

    test('private key is PEM encoded', () {
      final pair = generateSecureEcdhKeyPair();
      expect(pair.privateKey, contains('PRIVATE KEY'));
      expect(pair.publicKey, contains('PUBLIC KEY'));
    });
  });
}
