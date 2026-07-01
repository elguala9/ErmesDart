import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

void main() {
  testSharedSecretRekey();
}

/// Covers the "new signal → fresh shared-secret key" behaviour: a peer's raw
/// ECDH public key (carried in a signal) is enough to derive the shared cipher,
/// and adding a new key on a fresh signal keeps the existing cipher and its
/// prior keys intact.
void testSharedSecretRekey() {
  group('Shared-secret rekey on a new signal', () {
    late ECDHKeyExchangeService peer1;
    late ECDHKeyExchangeService peer2;

    setUp(() async {
      peer1 =
          await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
      peer2 =
          await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
    });

    group('deriveSharedSecretCipher (public key only)', () {
      test('both peers derive the same key from each other public key', () {
        final c1 = deriveSharedSecretCipher(peer1, peer2.publicKey);
        final c2 = deriveSharedSecretCipher(peer2, peer1.publicKey);

        expect(c1.keyId.bytes, equals(c2.keyId.bytes));
      });

      test('matches generateISymmetric derived from the serialized key', () {
        final viaPublicKey = deriveSharedSecretCipher(peer1, peer2.publicKey);
        final viaSerialized = peer1.generateISymmetric(peer2.serialize());

        expect(viaPublicKey.keyId.bytes, equals(viaSerialized.keyId.bytes));
      });

      test('peer2 decrypts what peer1 encrypts with the derived cipher', () {
        final c1 = deriveSharedSecretCipher(peer1, peer2.publicKey);
        final c2 = deriveSharedSecretCipher(peer2, peer1.publicKey);
        final cipher1 = createErmesPeerCipher()..addEncryptCipher(c1);
        final cipher2 = createErmesPeerCipher()..addDecryptCipher(c2);

        final message = Uint8List.fromList([72, 105, 33]);
        final encrypted = cipher1.encrypt(message);

        expect(cipher2.decrypt(encrypted), equals(message));
      });

      test('re-applying the same shared key repeatedly stays consistent', () {
        // Several dials with an unchanged peer key derive the same cipher;
        // re-adding it must not break encryption (addEncryptCipher is
        // idempotent by keyId, addDecryptCipher overwrites its map slot).
        final local = deriveSharedSecretCipher(peer1, peer2.publicKey);
        final localCipher = createErmesPeerCipher();
        for (var i = 0; i < 3; i++) {
          localCipher
            ..addEncryptCipher(local)
            ..addDecryptCipher(local);
        }

        final remote = deriveSharedSecretCipher(peer2, peer1.publicKey);
        final remoteCipher = createErmesPeerCipher()..addEncryptCipher(remote);

        final message = Uint8List.fromList([1, 1, 2, 3, 5, 8]);
        expect(localCipher.decrypt(remoteCipher.encrypt(message)),
            equals(message));

        // A single removal clears the key: no leftover state to encrypt with.
        localCipher.removeEncryptCipher(local.keyId);
        expect(localCipher.hasEncryptCipher, isFalse);
      });
    });

    group('a fresh signal adds a key and keeps the existing cipher', () {
      test('old key still decrypts and the new key also decrypts', () async {
        // First signal: shared key A, registered on the retained peer cipher.
        final localCipher = createErmesPeerCipher();
        final aLocal = deriveSharedSecretCipher(peer1, peer2.publicKey);
        localCipher
          ..addEncryptCipher(aLocal)
          ..addDecryptCipher(aLocal);

        final aRemote = deriveSharedSecretCipher(peer2, peer1.publicKey);
        final remoteA = createErmesPeerCipher()..addEncryptCipher(aRemote);

        final oldMessage = Uint8List.fromList([1, 2, 3, 4]);
        final encryptedOld = remoteA.encrypt(oldMessage);
        expect(localCipher.decrypt(encryptedOld), equals(oldMessage));

        // New signal: the peer republishes a fresh ECDH public key. We derive a
        // new shared key B and add it to the SAME cipher without dropping A.
        final peer2Fresh = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final bLocal = deriveSharedSecretCipher(peer1, peer2Fresh.publicKey);
        localCipher
          ..addEncryptCipher(bLocal)
          ..addDecryptCipher(bLocal);

        final bRemote = deriveSharedSecretCipher(peer2Fresh, peer1.publicKey);
        final remoteB = createErmesPeerCipher()..addEncryptCipher(bRemote);

        // The new key decrypts new frames...
        final newMessage = Uint8List.fromList([9, 8, 7, 6]);
        final encryptedNew = remoteB.encrypt(newMessage);
        expect(localCipher.decrypt(encryptedNew), equals(newMessage));

        // ...and the old key is still registered for in-flight frames.
        final lateOldMessage = Uint8List.fromList([5, 5, 5]);
        final encryptedLateOld = remoteA.encrypt(lateOldMessage);
        expect(localCipher.decrypt(encryptedLateOld), equals(lateOldMessage));
      });
    });

    group('signal carries the ECDH public key on the wire', () {
      test('public key round-trips through the signal serialization', () {
        final signal = SignalErmes(
          publicKey: peer1.publicKey,
          ipv4: '1.2.3.4',
          ipv4Port: '9000',
          ipv6: '',
          ipv6Port: '',
          epochTimestampStartConversation: 100,
          epochTimestampExpireConversation: 700,
        );

        final restored = SignalErmes.fromString(signal.toString());

        expect(restored.publicKey, equals(peer1.publicKey));
        expect(restored.publicKey, isNotEmpty);
      });
    });
  });
}
