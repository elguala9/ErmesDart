import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'ermes_key_message_bounds_sender_test.dart';

final _k0Hex = 'A' * 64;
final _k1Hex = 'B' * 64;
var _seq = 0;

String _uid(String p) =>
    '$p-${_seq++}-${DateTime.now().microsecondsSinceEpoch}';

/// Encrypts a data frame with id [id] under [key] and returns the wire bytes.
Uint8List _frame(ICipher key, int id) {
  final sender = _uid('snd');
  ErmesPeerCipherHandler().set(
    sender,
    ErmesPeerCipher()..addEncryptCipher(key),
  );
  final data = Uint8List.fromList([id % 256, 1, 2]);
  final root = buildMessageRoot(
    MessageType.data(createMessageDataErmes(data, id)),
    sender,
  );
  ErmesPeerCipherHandler().remove(sender);
  return objectToUint8Array(root);
}

/// Decodes [bytes] for [peer] and applies the key-bounds check.
bool _accepted(Uint8List bytes, String peer) {
  final decoded = decodeMessageEnvelope(bytes, peer, <String>{});
  if (decoded == null) {
    fail('frame was not decodable');
  }
  final inner = uint8ArrayToObject<InternalMessage>(decoded.plainBytes);
  return isWithinKeyBounds(decoded, peer, inner);
}

/// Registers [cipher] as the receiver cipher under a fresh key.
String _receiver(ErmesPeerCipher cipher) {
  final peer = _uid('rcv');
  ErmesPeerCipherHandler().set(peer, cipher);
  return peer;
}

/// RFC section 7.4: startMessage/endMessage are filled by the sender and
/// enforced by the receiver after decryption.
void testKeyMessageBounds() {
  group('Key message bounds (startMessage/endMessage)', () {
    late ErmesReceiveStats stats;
    late ICipher k0;
    late ICipher k1;
    setUp(() {
      ErmesReceiveStats.active = stats = ErmesReceiveStats();
      k0 = generateSymmetric(_k0Hex, SymmetricAlgorithm.aes);
      k1 = generateSymmetric(_k1Hex, SymmetricAlgorithm.aes);
    });
    tearDown(() => ErmesReceiveStats.active = null);

    test('unbounded key (initial ECDH) accepts any id', () {
      final peer = _receiver(ErmesPeerCipher()..addDecryptCipher(k0));
      expect(_accepted(_frame(k0, 0), peer), isTrue);
      expect(_accepted(_frame(k0, 1 << 40), peer), isTrue);
      expect(stats.dropKeyBounds, 0);
    });

    test('rejects ids below startMessage and above endMessage', () {
      final peer = _receiver(
        ErmesPeerCipher()
          ..addDecryptCipher(k1, startMessage: 10, endMessage: 20),
      );
      expect(_accepted(_frame(k1, 9), peer), isFalse);
      expect(_accepted(_frame(k1, 21), peer), isFalse);
      expect(_accepted(_frame(k1, 10), peer), isTrue);
      expect(_accepted(_frame(k1, 20), peer), isTrue);
      expect(stats.dropKeyBounds, 2);
      expect(stats.toString(), contains('keyBounds=2'));
    });

    test('absent endMessage is open-ended', () {
      final cipher = ErmesPeerCipher()..addDecryptCipher(k1, startMessage: 5);
      expect(cipher.isIdInKeyBounds(k1.keyId, 4), isFalse);
      expect(cipher.isIdInKeyBounds(k1.keyId, 5), isTrue);
      expect(cipher.isIdInKeyBounds(k1.keyId, 1 << 50), isTrue);
    });

    test('isIdInKeyBounds throws for an unknown key', () {
      expect(
        () => ErmesPeerCipher().isIdInKeyBounds(k0.keyId, 1),
        throwsA(isA<CipherException>()),
      );
    });

    test('handleNewKeyMessage registers the advertised bounds', () {
      final peer = _uid('rcv');
      handleNewKeyMessage(
        ServiceMessageNewKey(
          id: 7,
          algorithm: SymmetricAlgorithm.aes,
          key: _k1Hex,
          startMessage: 8,
        ),
        peer,
      );
      expect(_accepted(_frame(k1, 3), peer), isFalse);
      expect(_accepted(_frame(k1, 8), peer), isTrue);
    });

    test('retransmitted frame under the previous key still decrypts', () {
      final stored = _frame(k0, 4);
      final peer = _receiver(
        ErmesPeerCipher()
          ..addDecryptCipher(k0)
          ..addDecryptCipher(k1, startMessage: 10),
      );
      expect(_accepted(stored, peer), isTrue);
      expect(stats.dropKeyBounds, 0);
    });

    test('a frame under an unknown key is a decrypt drop, not bounds', () {
      final peer = _receiver(ErmesPeerCipher()..addDecryptCipher(k0));
      expect(decodeMessageEnvelope(_frame(k1, 1), peer, <String>{}), isNull);
      expect([stats.dropDecrypt, stats.dropKeyBounds], [1, 0]);
    });
  });

  testKeyMessageBoundsSender();
}

void main() {
  testKeyMessageBounds();
}
