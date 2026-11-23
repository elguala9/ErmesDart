import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

final _bytes = Uint8List.fromList([1, 2, 3]);
const _digestHex = '0a0b0c';

Map<String, dynamic> _envelope({
  Object? v = '3.0',
  bool message = false,
  bool serialized = false,
  bool digest = false,
}) => {
  if (v != null) 'v': v,
  if (message) 'message': <String, dynamic>{'k': 1},
  if (serialized) 'messageSerialized': base64Encode(_bytes),
  if (digest) 'digest': _digestHex,
  'integrityCheckValue': 'h',
};

Matcher get _rejected => throwsA(isA<ErmesSerializationException>());

void testErmesEnvelopePresenceRule() {
  group('Envelope presence rule (RFC 7.1)', () {
    for (final v in <Object?>['3.0', null]) {
      final label = v == null ? 'legacy' : 'v$v';
      test('$label accepts plaintext message', () {
        final root = MessageRoot.fromJson(_envelope(v: v, message: true));
        expect(root.messageJson, {'k': 1});
        expect(root.digest, isNull);
      });
      test('$label accepts messageSerialized with digest', () {
        final root = MessageRoot.fromJson(
          _envelope(v: v, serialized: true, digest: true),
        );
        expect(root.messageSerialized, _bytes);
        expect(root.digest, isNotNull);
      });
      test('$label rejects message and messageSerialized together', () {
        expect(
          () => MessageRoot.fromJson(
            _envelope(v: v, message: true, serialized: true, digest: true),
          ),
          _rejected,
        );
      });
      test('$label rejects messageSerialized without digest', () {
        expect(
          () => MessageRoot.fromJson(_envelope(v: v, serialized: true)),
          _rejected,
        );
      });
      test('$label rejects digest next to plaintext message', () {
        expect(
          () => MessageRoot.fromJson(
            _envelope(v: v, message: true, digest: true),
          ),
          _rejected,
        );
      });
      test('$label rejects an envelope with no payload', () {
        expect(() => MessageRoot.fromJson(_envelope(v: v)), _rejected);
      });
    }
  });

  group('MessageRoot.toJson presence rule', () {
    test('never emits messageSerialized without digest', () {
      final root = MessageRoot(
        messageSerialized: _bytes,
        integrityCheckValue: 'h',
      );
      expect(root.toJson, _rejected);
    });
    test('emits messageSerialized together with digest', () {
      final root = MessageRoot(
        messageSerialized: _bytes,
        integrityCheckValue: 'h',
        digest: Digest([10, 11, 12]),
      );
      final json = root.toJson();
      expect(json['digest'], _digestHex);
      expect(json.containsKey('message'), isFalse);
    });
  });

  group('decodeMessageEnvelope drops presence violations', () {
    tearDown(() => ErmesReceiveStats.active = null);

    test('a malformed envelope is dropped, not thrown', () {
      final stats = ErmesReceiveStats.active = ErmesReceiveStats();
      final bad = utf8.encode(
        jsonEncode(_envelope(message: true, serialized: true, digest: true)),
      );
      final decoded = decodeMessageEnvelope(
        Uint8List.fromList(bad),
        'p',
        <String>{},
      );
      expect(decoded, isNull);
      expect(stats.dropVersion, 1);
    });
  });
}

void main() => testErmesEnvelopePresenceRule();
