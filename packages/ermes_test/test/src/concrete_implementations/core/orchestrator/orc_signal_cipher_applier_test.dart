import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Connection context used by these tests.
const _v4 = ErmesConnectionContext.ipv4;

/// Cipher of [peerId] over the IPv4 Connection.
ErmesPeerCipher? _v4Cipher(String peerId) =>
    ErmesPeerCipherHandler().get(peerCipherKey(peerId, _v4));

/// Tests for [OrcSignalCipherApplier]: a re-dial toward a fresher peer
/// signal must switch encryption to the fresh shared secret.
void testOrcSignalCipherApplier() {
  group('OrcSignalCipherApplier', () {
    test(
      're-dial with a fresh peer key encrypts with the fresh secret',
      () async {
        final local = await ECDHKeyExchangeService.generateNewService();
        final stalePeer = await ECDHKeyExchangeService.generateNewService();
        final freshPeer = await ECDHKeyExchangeService.generateNewService();
        final peerId =
            'applier-redial-${DateTime.now().microsecondsSinceEpoch}';
        OrcSignalCipherApplier(local)
          ..apply(peerId, stalePeer.publicKey, _v4)
          ..apply(peerId, freshPeer.publicKey, _v4);

        final sent = _v4Cipher(peerId)!.encrypt(Uint8List.fromList([1, 2, 3]));

        // The real peer only knows the fresh secret: it must decrypt.
        final remote = ErmesPeerCipher()
          ..addDecryptCipher(
            deriveDirectionalCiphers(freshPeer, local.publicKey, _v4).decrypt,
          );
        expect(remote.decrypt(sent), equals([1, 2, 3]));
      },
    );

    test('keeps decrypting frames under the superseded key', () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final stalePeer = await ECDHKeyExchangeService.generateNewService();
      final freshPeer = await ECDHKeyExchangeService.generateNewService();
      final peerId = 'applier-keep-${DateTime.now().microsecondsSinceEpoch}';
      OrcSignalCipherApplier(local)
        ..apply(peerId, stalePeer.publicKey, _v4)
        ..apply(peerId, freshPeer.publicKey, _v4);

      final staleCipher =
          deriveDirectionalCiphers(stalePeer, local.publicKey, _v4).encrypt;
      final frame = DataEncrypted(
        staleCipher.keyId,
        Uint8List.fromList(staleCipher.encrypt(Uint8List.fromList([9]))),
      );
      expect(_v4Cipher(peerId)!.decrypt(frame), equals([9]));
    });

    test('empty public key registers nothing', () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final peerId = 'applier-empty-${DateTime.now().microsecondsSinceEpoch}';
      OrcSignalCipherApplier(local).apply(peerId, '', _v4);
      expect(_v4Cipher(peerId), isNull);
    });

    test('IPv4 and IPv6 Connections to one peer get distinct keys', () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final remote = await ECDHKeyExchangeService.generateNewService();
      final peerId = 'applier-family-${DateTime.now().microsecondsSinceEpoch}';
      OrcSignalCipherApplier(local)
        ..apply(peerId, remote.publicKey, _v4)
        ..apply(peerId, remote.publicKey, ErmesConnectionContext.ipv6);
      final v6 = ErmesPeerCipherHandler()
          .get(peerCipherKey(peerId, ErmesConnectionContext.ipv6))!;
      final v4 = _v4Cipher(peerId)!;
      expect(identical(v4, v6), isFalse);
      expect(v4.currentEncryptKeyId, isNot(equals(v6.currentEncryptKeyId)));
    });

    test('encrypt key id differs from the decrypt key id', () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final remote = await ECDHKeyExchangeService.generateNewService();
      final peerId = 'applier-dir-${DateTime.now().microsecondsSinceEpoch}';
      OrcSignalCipherApplier(local).apply(peerId, remote.publicKey, _v4);
      final pair = deriveDirectionalCiphers(local, remote.publicKey, _v4);
      final cipher = _v4Cipher(peerId)!;
      expect(cipher.currentEncryptKeyId, equals(pair.encrypt.keyId));
      expect(cipher.currentEncryptKeyId, isNot(equals(pair.decrypt.keyId)));
    });
  });
}

void main() => testOrcSignalCipherApplier();
