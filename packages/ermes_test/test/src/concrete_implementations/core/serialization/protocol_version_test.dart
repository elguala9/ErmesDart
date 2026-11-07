import 'dart:convert';
import 'dart:typed_data';

import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

final Uint8List _bytes = Uint8List.fromList([1, 2, 3]);

Map<String, dynamic> _serialized(Object? v) => {
  if (v != null) 'v': v,
  'messageSerialized': base64Encode(_bytes),
  'integrityCheckValue': 'h',
};

Map<String, dynamic> _plain(Object? v) => {
  if (v != null) 'v': v,
  'message': <String, dynamic>{'a': 1},
  'integrityCheckValue': 'h',
};

/// Tests [ProtocolVersion] parsing and the envelope `v` handling of
/// [MessageRoot] (RFC ermes-protocol, section 7.1).
void testProtocolVersion() {
  group('ProtocolVersion.parse', () {
    test('parses "X.Y" into major and minor', () {
      final v = ProtocolVersion.parse('3.7');
      expect([v.major, v.minor], [3, 7]);
      expect(v.toString(), '3.7');
      expect(v.isSupported, isTrue);
    });

    test('absent value is the legacy 1.0 form', () {
      expect(ProtocolVersion.parse(null), ProtocolVersion.legacy);
      expect(ProtocolVersion.legacy.toString(), '1.0');
    });

    test('current version is "3.0"', () {
      expect(ProtocolVersion.current.toString(), '3.0');
    });

    test('rejects non-string and malformed values', () {
      for (final raw in <Object>[2, 3.0, 'abc', '3', '3.', '.1', '-3.0']) {
        expect(
          () => ProtocolVersion.parse(raw),
          throwsA(isA<ErmesSerializationException>()),
          reason: '$raw',
        );
      }
    });

    test('unsupported major fails requireSupported', () {
      final v = ProtocolVersion.parse('4.0');
      expect(v.isSupported, isFalse);
      expect(v.requireSupported, throwsA(isA<ErmesSerializationException>()));
    });
  });

  group('MessageRoot envelope version', () {
    test('toJson writes v as the string "3.0" in both forms', () {
      final enc = MessageRoot(
        messageSerialized: _bytes,
        integrityCheckValue: 'h',
      );
      final plain = MessageRoot(
        messageSerialized: Uint8List(0),
        messageJson: const {'a': 1},
        integrityCheckValue: 'h',
      );
      expect(enc.toJson()['v'], '3.0');
      expect(plain.toJson()['v'], '3.0');
    });

    test('accepts "3.0" and a higher minor "3.7"', () {
      for (final v in ['3.0', '3.7']) {
        expect(MessageRoot.fromJson(_serialized(v)).messageSerialized, _bytes);
        expect(MessageRoot.fromJson(_plain(v)).messageJson, {'a': 1});
      }
    });

    test('accepts absent v as legacy, plaintext and serialized', () {
      expect(MessageRoot.fromJson(_serialized(null)).messageSerialized, _bytes);
      expect(MessageRoot.fromJson(_plain(null)).messageJson, {'a': 1});
    });

    test('round-trips through toJson/fromJson', () {
      final root = MessageRoot(
        messageSerialized: _bytes,
        integrityCheckValue: 'h',
      );
      final back = MessageRoot.fromJson(
        jsonDecode(jsonEncode(root.toJson())) as Map<String, dynamic>,
      );
      expect(back.messageSerialized, _bytes);
    });

    test('rejects int 2, "abc", "3" and "4.0"', () {
      for (final v in <Object>[2, 'abc', '3', '4.0']) {
        expect(
          () => MessageRoot.fromJson(_serialized(v)),
          throwsA(isA<ErmesSerializationException>()),
          reason: '$v',
        );
      }
    });
  });
}

void main() => testProtocolVersion();
