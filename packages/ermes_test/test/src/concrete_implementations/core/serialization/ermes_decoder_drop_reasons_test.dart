import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Builds a serialized [MessageRoot] carrying [payload].
Uint8List _frame(Uint8List payload, {String? hash, bool encrypted = false}) {
  final root = MessageRoot(
    messageSerialized: payload,
    integrityCheckValue: hash ?? calculateHashSync(payload),
    digest: encrypted ? sha256.convert(payload) : null,
  );
  return objectToUint8Array(root);
}

/// Tests that each envelope-decoder drop reason has its own counter on
/// the opt-in [ErmesReceiveStats].
void testDecoderDropReasons() {
  group('decodeMessageEnvelope drop reasons', () {
    late ErmesReceiveStats stats;
    setUp(() => ErmesReceiveStats.active = stats = ErmesReceiveStats());
    tearDown(() => ErmesReceiveStats.active = null);

    final payload = Uint8List.fromList([1, 2, 3]);

    test('counts empty, hash, duplicate and no-cipher separately', () {
      final seen = <String>{};
      expect(decodeMessageEnvelope(Uint8List(0), 'p', seen), isNull);
      expect(
        decodeMessageEnvelope(_frame(payload, hash: 'x'), 'p', seen),
        isNull,
      );
      expect(decodeMessageEnvelope(_frame(payload), 'p', seen), isNotNull);
      expect(decodeMessageEnvelope(_frame(payload), 'p', seen), isNull);
      final peer = 'no-cipher-${DateTime.now().microsecondsSinceEpoch}';
      expect(
        decodeMessageEnvelope(_frame(payload, encrypted: true), peer, seen),
        isNull,
      );
      expect([
        stats.dropEmpty,
        stats.dropHash,
        stats.dropDuplicate,
        stats.dropNoCipher,
        stats.dropDecrypt,
      ], equals([1, 1, 1, 1, 0]));
      expect(stats.toString(), contains('noCipher=1'));
    });

    test('counts decrypt failures and keeps the error text', () {
      final peer = 'bad-key-${DateTime.now().microsecondsSinceEpoch}';
      ErmesPeerCipherHandler().set(peer, ErmesPeerCipher());
      final frame = _frame(payload, encrypted: true);
      expect(decodeMessageEnvelope(frame, peer, <String>{}), isNull);
      expect(stats.dropDecrypt, 1);
      expect(stats.lastDecryptError, contains('Decryption cipher not found'));
    });

    test('is a no-op when diagnostics are off', () {
      ErmesReceiveStats.active = null;
      expect(decodeMessageEnvelope(Uint8List(0), 'p', <String>{}), isNull);
      expect(stats.dropEmpty, 0);
    });
  });
}

void main() => testDecoderDropReasons();
