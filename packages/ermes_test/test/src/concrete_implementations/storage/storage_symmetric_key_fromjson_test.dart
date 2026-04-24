import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('StorageSymmetricKeyType.fromJson', () {
    test('should deserialize valid JSON correctly', () {
      final json = {
        'expiration': '2026-12-31T23:59:59.000Z',
        'key': 'test_key_123',
        'idPeer': '100',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.key, equals('test_key_123'));
      expect(result.idPeer, equals('100'));
      expect(result.expiration.year, equals(2026));
      expect(result.expiration.month, equals(12));
      expect(result.expiration.day, equals(31));
    });

    test('should throw FormatException when expiration is missing', () {
      final json = {
        'key': 'test_key',
        'idPeer': '100',
      };

      expect(
        () => StorageSymmetricKeyType.fromJson(json),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message',
                contains('expiration'))),
      );
    });

    test('should throw FormatException when key is missing', () {
      final json = {
        'expiration': '2026-12-31T23:59:59.000Z',
        'idPeer': '100',
      };

      expect(
        () => StorageSymmetricKeyType.fromJson(json),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('key'))),
      );
    });

    test('should throw FormatException when idPeer is missing', () {
      final json = {
        'expiration': '2026-12-31T23:59:59.000Z',
        'key': 'test_key',
      };

      expect(
        () => StorageSymmetricKeyType.fromJson(json),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('idPeer'))),
      );
    });

    test('should handle complex key strings', () {
      final json = {
        'expiration': '2026-06-15T10:30:45.123456Z',
        'key': 'key_with_!@#_special_^&*()_+-=[]{}|;:,.<>?/~`',
        'idPeer': '999',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.key, equals('key_with_!@#_special_^&*()_+-=[]{}|;:,.<>?/~`'));
    });

    test('should handle numeric idPeer as string', () {
      final json = {
        'expiration': '2026-12-31T23:59:59.000Z',
        'key': 'test_key',
        'idPeer': '123456',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.idPeer, equals('123456'));
      expect(result.id, equals(123456));
    });

    test('should parse ISO8601 datetime correctly', () {
      final json = {
        'expiration': '2025-01-01T00:00:00.000Z',
        'key': 'test_key',
        'idPeer': '100',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.expiration.year, equals(2025));
      expect(result.expiration.month, equals(1));
      expect(result.expiration.day, equals(1));
      expect(result.expiration.hour, equals(0));
      expect(result.expiration.minute, equals(0));
      expect(result.expiration.second, equals(0));
    });

    test('should preserve DateTime with milliseconds', () {
      final json = {
        'expiration': '2026-06-15T14:30:45.123Z',
        'key': 'test_key',
        'idPeer': '100',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.expiration.millisecond, equals(123));
    });

    test('should handle empty key string', () {
      final json = {
        'expiration': '2026-12-31T23:59:59.000Z',
        'key': '',
        'idPeer': '100',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.key, equals(''));
    });

    test('should handle "0" as idPeer', () {
      final json = {
        'expiration': '2026-12-31T23:59:59.000Z',
        'key': 'test_key',
        'idPeer': '0',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.idPeer, equals('0'));
      expect(result.id, equals(0));
    });

    test('should handle long idPeer strings', () {
      final json = {
        'expiration': '2026-12-31T23:59:59.000Z',
        'key': 'test_key',
        'idPeer': '999999999999999999',
      };

      final result = StorageSymmetricKeyType.fromJson(json);

      expect(result.idPeer, equals('999999999999999999'));
    });
  });

  group('StorageSymmetricKeyType.toJson', () {
    test('should serialize all fields correctly', () {
      final now = DateTime(2026, 4, 24, 10, 30, 0);
      final key = StorageSymmetricKeyType(
        expiration: now,
        key: 'test_key',
        idPeer: '100',
      );

      final json = key.toJson();

      expect(json['expiration'], equals(now.toIso8601String()));
      expect(json['key'], equals('test_key'));
      expect(json['idPeer'], equals('100'));
    });

    test('should include idPeer in JSON', () {
      final key = StorageSymmetricKeyType(
        expiration: DateTime.now(),
        key: 'test_key',
        idPeer: '100',
      );

      final json = key.toJson();

      expect(json.containsKey('idPeer'), isTrue);
      expect(json['idPeer'], equals('100'));
    });

    test('should serialize special characters in key', () {
      final key = StorageSymmetricKeyType(
        expiration: DateTime.now(),
        key: 'key_!@#_special_chars',
        idPeer: '100',
      );

      final json = key.toJson();

      expect(json['key'], equals('key_!@#_special_chars'));
    });
  });

  group('StorageSymmetricKeyType roundtrip serialization', () {
    test('should roundtrip correctly', () {
      final original = StorageSymmetricKeyType(
        expiration: DateTime(2026, 6, 15, 14, 30, 45),
        key: 'roundtrip_key',
        idPeer: '42',
      );

      final json = original.toJson();
      final deserialized = StorageSymmetricKeyType.fromJson(json);

      expect(deserialized.key, equals(original.key));
      expect(deserialized.idPeer, equals(original.idPeer));
      // DateTime.parse loses microseconds, so compare ISO8601 strings
      expect(deserialized.expiration.toIso8601String(),
          equals(original.expiration.toIso8601String()));
    });

    test('should roundtrip complex data', () {
      final original = StorageSymmetricKeyType(
        expiration: DateTime(2026, 12, 31, 23, 59, 59, 999),
        key: 'complex_!@#\$%_key_with_special_chars',
        idPeer: '999999',
      );

      final json = original.toJson();
      final deserialized = StorageSymmetricKeyType.fromJson(json);

      expect(deserialized.key, equals(original.key));
      expect(deserialized.idPeer, equals(original.idPeer));
      expect(deserialized.id, equals(999999));
    });

    test('should maintain consistency across multiple roundtrips', () {
      final original = StorageSymmetricKeyType(
        expiration: DateTime(2026, 3, 15),
        key: 'test_key',
        idPeer: '123',
      );

      var current = original;
      for (var i = 0; i < 5; i++) {
        final json = current.toJson();
        current = StorageSymmetricKeyType.fromJson(json);
      }

      expect(current.key, equals(original.key));
      expect(current.idPeer, equals(original.idPeer));
      expect(current.expiration.toIso8601String(),
          equals(original.expiration.toIso8601String()));
    });
  });

  group('StorageSymmetricKeyType.json getter', () {
    test('should return same as toJson()', () {
      final key = StorageSymmetricKeyType(
        expiration: DateTime(2026, 12, 31),
        key: 'test_key',
        idPeer: '100',
      );

      expect(key.json, equals(key.toJson()));
    });

    test('should include all fields in json getter', () {
      final key = StorageSymmetricKeyType(
        expiration: DateTime(2026, 12, 31),
        key: 'test_key',
        idPeer: '100',
      );

      final json = key.json;

      expect(json.containsKey('expiration'), isTrue);
      expect(json.containsKey('key'), isTrue);
      expect(json.containsKey('idPeer'), isTrue);
    });
  });
}
