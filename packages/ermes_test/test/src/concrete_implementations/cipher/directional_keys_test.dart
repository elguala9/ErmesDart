import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Connection context used by these tests.
const _v4 = ErmesConnectionContext.ipv4;

void main() => testDirectionalKeys();

/// Tests the directional session keys (RFC section 8.2).
void testDirectionalKeys() {
  group('Directional keys', () {
    late ECDHKeyExchangeService a;
    late ECDHKeyExchangeService b;

    setUp(() async {
      a = await ECDHKeyExchangeService.generateNewService();
      b = await ECDHKeyExchangeService.generateNewService();
    });

    test('encrypt and decrypt keys of one peer differ', () {
      final pair = deriveDirectionalCiphers(a, b.publicKey, _v4);
      expect(pair.encrypt.keyId, isNot(equals(pair.decrypt.keyId)));
    });

    test('A.encrypt equals B.decrypt and vice versa', () {
      final pa = deriveDirectionalCiphers(a, b.publicKey, _v4);
      final pb = deriveDirectionalCiphers(b, a.publicKey, _v4);
      expect(pa.encrypt.keyId, equals(pb.decrypt.keyId));
      expect(pb.encrypt.keyId, equals(pa.decrypt.keyId));
    });

    test('two peers exchange frames end to end', () {
      final pa = deriveDirectionalCiphers(a, b.publicKey, _v4);
      final pb = deriveDirectionalCiphers(b, a.publicKey, _v4);
      final ca = ErmesPeerCipher()
        ..addEncryptCipher(pa.encrypt)
        ..addDecryptCipher(pa.decrypt);
      final cb = ErmesPeerCipher()
        ..addEncryptCipher(pb.encrypt)
        ..addDecryptCipher(pb.decrypt);
      final ab = Uint8List.fromList([1, 2, 3]);
      final ba = Uint8List.fromList([4, 5, 6]);
      expect(cb.decrypt(ca.encrypt(ab)), equals(ab));
      expect(ca.decrypt(cb.encrypt(ba)), equals(ba));
    });

    test('a frame cannot be reflected back to its sender', () {
      final pa = deriveDirectionalCiphers(a, b.publicKey, _v4);
      final ca = ErmesPeerCipher()
        ..addEncryptCipher(pa.encrypt)
        ..addDecryptCipher(pa.decrypt);
      final frame = ca.encrypt(Uint8List.fromList([9, 9]));
      expect(() => ca.decrypt(frame), throwsA(anything));
    });

    test('directions differ per Connection family', () {
      final v4 = deriveDirectionalCiphers(a, b.publicKey, _v4);
      final v6 = deriveDirectionalCiphers(
        a,
        b.publicKey,
        ErmesConnectionContext.ipv6,
      );
      expect(v4.encrypt.keyId, isNot(equals(v6.encrypt.keyId)));
    });

    test('self-connection uses one key for both directions', () {
      final pair = deriveDirectionalCiphers(a, a.publicKey, _v4);
      expect(pair.encrypt.keyId, equals(pair.decrypt.keyId));
      expect(ermesDirectionalInfo(_v4, 'K', 'k'), equals('ermes-v3|ipv4|self'));
    });

    test('direction label is symmetric across peers', () {
      expect(ermesDirectionalInfo(_v4, 'aa', 'bb'), endsWith('|lo>hi'));
      expect(ermesDirectionalInfo(_v4, 'bb', 'aa'), endsWith('|hi>lo'));
    });

    test('an invalid remote public key throws', () {
      expect(
        () => deriveDirectionalCiphers(a, 'not-a-key', _v4),
        throwsA(anything),
      );
    });
  });
}
