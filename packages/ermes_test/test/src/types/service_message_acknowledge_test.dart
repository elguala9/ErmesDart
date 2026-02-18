import 'package:test/test.dart';
import 'package:iermes/iermes.dart';

void main() {
  group('ServiceMessage - Acknowledge Fields', () {
    test('Create ServiceMessageAcknowledge with acknowledge fields', () {
      final msg = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      expect(msg.id, equals(1));
      expect(msg.ackCurrentId, equals(10));
      expect(msg.ackLastReceivedId, equals(5));
    });

    test('JSON serialization - toJson includes acknowledge fields', () {
      final msg = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final json = msg.toJson();

      expect(json['id'], equals(1));
      expect(json['reason'], equals('a'));
      expect(json['ackCurrentId'], equals(10));
      expect(json['ackLastReceivedId'], equals(5));
    });

    test('JSON deserialization - fromJson parses acknowledge fields', () {
      final json = {
        'id': 1,
        'reason': 'a',
        'ackCurrentId': 10,
        'ackLastReceivedId': 5,
      };

      final msg = ServiceMessage.fromJson(json);

      expect(msg, isA<ServiceMessageAcknowledge>());
      expect(msg.id, equals(1));
      expect((msg as ServiceMessageAcknowledge).ackCurrentId, equals(10));
      expect(msg.ackLastReceivedId, equals(5));
    });

    test('JSON round-trip preserves acknowledge fields', () {
      final original = ServiceMessageAcknowledge(
        id: 42,
        ackCurrentId: 100,
        ackLastReceivedId: 50,
      );

      final json = original.toJson();
      final reconstructed = ServiceMessage.fromJson(json);

      expect(reconstructed, equals(original));
      expect((reconstructed as ServiceMessageAcknowledge).ackCurrentId,
          equals(original.ackCurrentId));
      expect(
        reconstructed.ackLastReceivedId,
        equals(original.ackLastReceivedId),
      );
    });

    test('JSON with null acknowledge fields', () {
      final msg = ServiceMessageConnectionClose(id: 1);

      final json = msg.toJson();

      expect(json.containsKey('ackCurrentId'), false);
      expect(json.containsKey('ackLastReceivedId'), false);

      final reconstructed = ServiceMessage.fromJson(json);
      expect(reconstructed, isA<ServiceMessageConnectionClose>());
    });

    test('copyWith preserves acknowledge fields', () {
      final original = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final copied = original.copyWith();

      expect(copied.ackCurrentId, equals(10));
      expect(copied.ackLastReceivedId, equals(5));
    });

    test('copyWith updates acknowledge fields', () {
      final original = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final updated = original.copyWith(ackCurrentId: 20);

      expect(updated.ackCurrentId, equals(20));
      expect(updated.ackLastReceivedId, equals(5));
    });

    test('Equality operator includes acknowledge fields', () {
      final msg1 = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final msg2 = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final msg3 = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 15, // Different ackCurrentId
        ackLastReceivedId: 5,
      );

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('hashCode includes acknowledge fields', () {
      final msg1 = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final msg2 = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final msg3 = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 15,
        ackLastReceivedId: 5,
      );

      expect(msg1.hashCode, equals(msg2.hashCode));
      expect(msg1.hashCode, isNot(equals(msg3.hashCode)));
    });

    test('toString includes acknowledge fields', () {
      final msg = ServiceMessageAcknowledge(
        id: 1,
        ackCurrentId: 10,
        ackLastReceivedId: 5,
      );

      final str = msg.toString();

      expect(str, contains('ackCurrentId: 10'));
      expect(str, contains('ackLastReceivedId: 5'));
    });

    test('Array request with arrayId', () {
      final msg = ServiceMessageArrayRequest(
        id: 1,
        arrayId: [1, 2, 3],
      );

      final json = msg.toJson();
      final reconstructed = ServiceMessage.fromJson(json);

      expect(reconstructed, isA<ServiceMessageArrayRequest>());
      expect((reconstructed as ServiceMessageArrayRequest).arrayId,
          equals([1, 2, 3]));
    });

    test('Connection close message', () {
      final msg = ServiceMessageConnectionClose(id: 5);

      final json = msg.toJson();
      expect(json['reason'], equals('x'));

      final reconstructed = ServiceMessage.fromJson(json);
      expect(reconstructed, isA<ServiceMessageConnectionClose>());
      expect(reconstructed.id, equals(5));
    });

    test('Control message', () {
      final msg = ServiceMessageControl(id: 3);

      final json = msg.toJson();
      expect(json['reason'], equals('c'));

      final reconstructed = ServiceMessage.fromJson(json);
      expect(reconstructed, isA<ServiceMessageControl>());
      expect(reconstructed.id, equals(3));
    });
  });
}
