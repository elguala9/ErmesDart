import 'package:test/test.dart';
import 'package:iermes/iermes.dart';

void main() {
  group('ServiceMessage - NewKey', () {
    test('Create ServiceMessageNewKey with all fields', () {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 30));

      final msg = ServiceMessageNewKey(
        id: 1,
        algorithm: 'AES-256',
        key: 'a' * 64,
        start: now,
        expiration: future,
        startMessage: 100,
        endMessage: 200,
      );

      expect(msg.id, equals(1));
      expect(msg.algorithm, equals('AES-256'));
      expect(msg.key, equals('a' * 64));
      expect(msg.start, equals(now));
      expect(msg.expiration, equals(future));
      expect(msg.startMessage, equals(100));
      expect(msg.endMessage, equals(200));
    });

    test('Create ServiceMessageNewKey with minimal fields', () {
      final msg = ServiceMessageNewKey(
        id: 2,
        algorithm: 'AES-128',
        key: 'b' * 32,
      );

      expect(msg.id, equals(2));
      expect(msg.algorithm, equals('AES-128'));
      expect(msg.key, equals('b' * 32));
      expect(msg.start, isNull);
      expect(msg.expiration, isNull);
      expect(msg.startMessage, isNull);
      expect(msg.endMessage, isNull);
    });

    test('JSON serialization - toJson includes all fields', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final future = DateTime(2024, 1, 31, 12, 0, 0);

      final msg = ServiceMessageNewKey(
        id: 3,
        algorithm: 'AES-256',
        key: 'c' * 64,
        start: now,
        expiration: future,
        startMessage: 50,
        endMessage: 150,
      );

      final json = msg.toJson();

      expect(json['id'], equals(3));
      expect(json['reason'], equals('newkey'));
      expect(json['algorithm'], equals('AES-256'));
      expect(json['key'], equals('c' * 64));
      expect(json['start'], equals(now.toIso8601String()));
      expect(json['expiration'], equals(future.toIso8601String()));
      expect(json['startMessage'], equals(50));
      expect(json['endMessage'], equals(150));
    });

    test('JSON serialization - toJson omits null fields', () {
      final msg = ServiceMessageNewKey(
        id: 4,
        algorithm: 'AES-128',
        key: 'd' * 32,
      );

      final json = msg.toJson();

      expect(json['id'], equals(4));
      expect(json['reason'], equals('newkey'));
      expect(json['algorithm'], equals('AES-128'));
      expect(json['key'], equals('d' * 32));
      expect(json.containsKey('start'), false);
      expect(json.containsKey('expiration'), false);
      expect(json.containsKey('startMessage'), false);
      expect(json.containsKey('endMessage'), false);
    });

    test('JSON deserialization - fromJson parses all fields', () {
      final json = {
        'id': 5,
        'reason': 'newkey',
        'algorithm': 'AES-256',
        'key': 'e' * 64,
        'start': '2024-01-01T12:00:00.000Z',
        'expiration': '2024-01-31T12:00:00.000Z',
        'startMessage': 25,
        'endMessage': 75,
      };

      final msg = ServiceMessage.fromJson(json);

      expect(msg, isA<ServiceMessageNewKey>());
      expect(msg.id, equals(5));
      expect((msg as ServiceMessageNewKey).algorithm, equals('AES-256'));
      expect(msg.key, equals('e' * 64));
      expect(msg.start, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
      expect(
        msg.expiration,
        equals(DateTime.parse('2024-01-31T12:00:00.000Z')),
      );
      expect(msg.startMessage, equals(25));
      expect(msg.endMessage, equals(75));
    });

    test('JSON round-trip preserves all fields', () {
      final original = ServiceMessageNewKey(
        id: 6,
        algorithm: 'AES-256',
        key: 'f' * 64,
        start: DateTime(2024, 6, 1),
        expiration: DateTime(2024, 6, 30),
        startMessage: 1000,
        endMessage: 2000,
      );

      final json = original.toJson();
      final reconstructed = ServiceMessage.fromJson(json);

      expect(reconstructed, equals(original));
      expect((reconstructed as ServiceMessageNewKey).algorithm,
          equals(original.algorithm));
      expect(reconstructed.key, equals(original.key));
      expect(reconstructed.start, equals(original.start));
      expect(reconstructed.expiration, equals(original.expiration));
      expect(reconstructed.startMessage, equals(original.startMessage));
      expect(reconstructed.endMessage, equals(original.endMessage));
    });

    test('copyWith preserves all fields', () {
      final original = ServiceMessageNewKey(
        id: 7,
        algorithm: 'AES-256',
        key: 'g' * 64,
        start: DateTime(2024, 1, 1),
        expiration: DateTime(2024, 12, 31),
        startMessage: 100,
        endMessage: 200,
      );

      final copied = original.copyWith();

      expect(copied.id, equals(original.id));
      expect(copied.algorithm, equals(original.algorithm));
      expect(copied.key, equals(original.key));
      expect(copied.start, equals(original.start));
      expect(copied.expiration, equals(original.expiration));
      expect(copied.startMessage, equals(original.startMessage));
      expect(copied.endMessage, equals(original.endMessage));
    });

    test('copyWith updates specific fields', () {
      final original = ServiceMessageNewKey(
        id: 8,
        algorithm: 'AES-256',
        key: 'h' * 64,
        startMessage: 100,
        endMessage: 200,
      );

      final updated = original.copyWith(
        algorithm: 'AES-128',
        startMessage: 150,
      );

      expect(updated.id, equals(8));
      expect(updated.algorithm, equals('AES-128'));
      expect(updated.key, equals('h' * 64));
      expect(updated.startMessage, equals(150));
      expect(updated.endMessage, equals(200));
    });

    test('Equality operator includes all fields', () {
      final msg1 = ServiceMessageNewKey(
        id: 9,
        algorithm: 'AES-256',
        key: 'i' * 64,
        startMessage: 50,
      );

      final msg2 = ServiceMessageNewKey(
        id: 9,
        algorithm: 'AES-256',
        key: 'i' * 64,
        startMessage: 50,
      );

      final msg3 = ServiceMessageNewKey(
        id: 9,
        algorithm: 'AES-128', // Different algorithm
        key: 'i' * 64,
        startMessage: 50,
      );

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('hashCode includes all fields', () {
      final msg1 = ServiceMessageNewKey(
        id: 10,
        algorithm: 'AES-256',
        key: 'j' * 64,
        endMessage: 300,
      );

      final msg2 = ServiceMessageNewKey(
        id: 10,
        algorithm: 'AES-256',
        key: 'j' * 64,
        endMessage: 300,
      );

      final msg3 = ServiceMessageNewKey(
        id: 10,
        algorithm: 'AES-256',
        key: 'j' * 64,
        endMessage: 400, // Different endMessage
      );

      expect(msg1.hashCode, equals(msg2.hashCode));
      expect(msg1.hashCode, isNot(equals(msg3.hashCode)));
    });

    test('toString shows key preview', () {
      final msg = ServiceMessageNewKey(
        id: 11,
        algorithm: 'AES-256',
        key: 'k' * 64,
      );

      final str = msg.toString();

      expect(str, contains('ServiceMessageNewKey'));
      expect(str, contains('algorithm: AES-256'));
      expect(str, contains('key:')); // Should show key preview
      expect(str.contains('k' * 64), false); // Full key not shown
    });

    test('Message range validation via fields', () {
      final msg = ServiceMessageNewKey(
        id: 12,
        algorithm: 'AES-256',
        key: 'm' * 64,
        startMessage: 1000,
        endMessage: 5000,
      );

      expect(msg.startMessage! < msg.endMessage!, isTrue);
    });

    test('Time range validation via fields', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);

      final msg = ServiceMessageNewKey(
        id: 13,
        algorithm: 'AES-256',
        key: 'n' * 64,
        start: start,
        expiration: end,
      );

      expect(msg.start!.isBefore(msg.expiration!), isTrue);
    });
  });

  group('ServiceMessage - NewKey Integration', () {
    test('NewKey message can be wrapped in MessageType', () {
      final msg = ServiceMessageNewKey(
        id: 100,
        algorithm: 'AES-256',
        key: 'x' * 64,
      );

      final wrapped = MessageType.service(msg);

      expect(wrapped, isNotNull);
      expect(wrapped.asService(), equals(msg));
      expect(wrapped.getId(), equals(100));
    });

    test('NewKey message roundtrip through MessageType', () {
      final original = ServiceMessageNewKey(
        id: 101,
        algorithm: 'AES-128',
        key: 'y' * 32,
        start: DateTime(2024, 6, 1),
        startMessage: 500,
      );

      final wrapped = MessageType.service(original);
      final extracted = wrapped.asService();

      expect(extracted, equals(original));
      expect((extracted as ServiceMessageNewKey).algorithm,
          equals('AES-128'));
    });

    test('Multiple NewKey messages with different configs', () {
      final messages = [
        ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'key1' * 16,
          startMessage: 0,
          endMessage: 1000,
        ),
        ServiceMessageNewKey(
          id: 2,
          algorithm: 'AES-128',
          key: 'key2' * 16,
          startMessage: 1001,
          endMessage: 2000,
        ),
        ServiceMessageNewKey(
          id: 3,
          algorithm: 'ChaCha20',
          key: 'key3' * 16,
          startMessage: 2001,
        ),
      ];

      final jsons = messages.map((m) => m.toJson()).toList();
      final restored = jsons
          .map((json) => ServiceMessage.fromJson(json))
          .toList()
          .cast<ServiceMessageNewKey>();

      expect(restored.length, equals(3));
      expect(restored[0].algorithm, equals('AES-256'));
      expect(restored[1].algorithm, equals('AES-128'));
      expect(restored[2].algorithm, equals('ChaCha20'));
      expect(restored[0].endMessage, equals(1000));
      expect(restored[2].startMessage, equals(2001));
    });

    test('NewKey message with all DateTime fields', () {
      final start = DateTime(2024, 1, 1, 0, 0, 0);
      final end = DateTime(2024, 12, 31, 23, 59, 59);

      final msg = ServiceMessageNewKey(
        id: 50,
        algorithm: 'AES-256',
        key: 'z' * 64,
        start: start,
        expiration: end,
      );

      final json = msg.toJson();
      final restored = ServiceMessage.fromJson(json) as ServiceMessageNewKey;

      // DateTime parsing preserves seconds precision
      expect(restored.start, equals(start));
      expect(restored.expiration, equals(end));
    });

    test('NewKey message preserves all fields through serialization cycle',
        () {
      final original = ServiceMessageNewKey(
        id: 77,
        algorithm: 'AES-256-GCM',
        key: 'a' * 128,
        start: DateTime(2024, 3, 15, 10, 30, 45),
        expiration: DateTime(2024, 9, 15, 10, 30, 45),
        startMessage: 5000,
        endMessage: 10000,
      );

      // Simulate transmission: serialize and deserialize
      final json = original.toJson();
      final transmitted = ServiceMessage.fromJson(json);

      expect(transmitted, isA<ServiceMessageNewKey>());
      final newKey = transmitted as ServiceMessageNewKey;

      expect(newKey.id, equals(77));
      expect(newKey.algorithm, equals('AES-256-GCM'));
      expect(newKey.key, equals('a' * 128));
      expect(newKey.start, equals(original.start));
      expect(newKey.expiration, equals(original.expiration));
      expect(newKey.startMessage, equals(5000));
      expect(newKey.endMessage, equals(10000));
    });
  });
}
