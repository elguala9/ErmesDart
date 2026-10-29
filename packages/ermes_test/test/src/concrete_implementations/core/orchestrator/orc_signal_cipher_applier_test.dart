import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

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
          ..apply(peerId, stalePeer.publicKey)
          ..apply(peerId, freshPeer.publicKey);

        final sent = ErmesPeerCipherHandler()
            .get(peerId)!
            .encrypt(Uint8List.fromList([1, 2, 3]));

        // The real peer only knows the fresh secret: it must decrypt.
        final remote = ErmesPeerCipher()
          ..addDecryptCipher(
            deriveSharedSecretCipher(freshPeer, local.publicKey),
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
        ..apply(peerId, stalePeer.publicKey)
        ..apply(peerId, freshPeer.publicKey);

      final staleCipher = deriveSharedSecretCipher(stalePeer, local.publicKey);
      final frame = DataEncrypted(
        staleCipher.keyId,
        Uint8List.fromList(staleCipher.encrypt(Uint8List.fromList([9]))),
      );
      expect(ErmesPeerCipherHandler().get(peerId)!.decrypt(frame), equals([9]));
    });

    test('empty public key registers nothing', () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final peerId = 'applier-empty-${DateTime.now().microsecondsSinceEpoch}';
      OrcSignalCipherApplier(local).apply(peerId, '');
      expect(ErmesPeerCipherHandler().get(peerId), isNull);
    });
  });
}

void main() => testOrcSignalCipherApplier();
