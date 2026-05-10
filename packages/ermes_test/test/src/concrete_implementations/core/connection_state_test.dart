import 'package:ermes_core/ermes_core.dart';
import 'package:test/test.dart';

void testConnectionState() {
  group('ConnectionState', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final state = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: 0,
          isClosed: false,
          lastActiveTimestamp: 1000,
        );
        expect(state.connectionId, equals('conn-1'));
        expect(state.remotePeerId, equals('peer-1'));
        expect(state.reconnectAttempts, equals(0));
        expect(state.isClosed, isFalse);
        expect(state.lastActiveTimestamp, equals(1000));
      });

      test('signalingInfo is null by default', () {
        final state = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: 0,
          isClosed: false,
          lastActiveTimestamp: 1000,
        );
        expect(state.signalingInfo, isNull);
      });

      test('accepts signalingInfo', () {
        final state = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: 0,
          isClosed: false,
          lastActiveTimestamp: 1000,
          signalingInfo: {'key': 'value'},
        );
        expect(state.signalingInfo, equals({'key': 'value'}));
      });
    });

    group('toJson() / fromJson()', () {
      test('round-trip serialization preserves all fields', () {
        final original = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: 3,
          isClosed: true,
          lastActiveTimestamp: 1234567890,
          signalingInfo: {'host': '127.0.0.1', 'port': '9000'},
        );
        final json = original.toJson();
        final restored = ConnectionState.fromJson(json);
        expect(restored.connectionId, equals(original.connectionId));
        expect(restored.remotePeerId, equals(original.remotePeerId));
        expect(restored.reconnectAttempts, equals(original.reconnectAttempts));
        expect(restored.isClosed, equals(original.isClosed));
        expect(
          restored.lastActiveTimestamp,
          equals(original.lastActiveTimestamp),
        );
        expect(restored.signalingInfo, equals(original.signalingInfo));
      });

      test('round-trip without signalingInfo', () {
        final original = ConnectionState(
          connectionId: 'conn-2',
          remotePeerId: 'peer-2',
          reconnectAttempts: 0,
          isClosed: false,
          lastActiveTimestamp: 987654321,
        );
        final json = original.toJson();
        final restored = ConnectionState.fromJson(json);
        expect(restored.connectionId, equals('conn-2'));
        expect(restored.remotePeerId, equals('peer-2'));
        expect(restored.reconnectAttempts, equals(0));
        expect(restored.isClosed, isFalse);
        expect(restored.signalingInfo, isNull);
      });
    });

    group('toString()', () {
      test('includes connection information', () {
        final state = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: 2,
          isClosed: false,
          lastActiveTimestamp: 1000,
        );
        final str = state.toString();
        expect(str, contains('conn-1'));
        expect(str, contains('peer-1'));
        expect(str, contains('ConnectionState'));
      });
    });

    group('edge cases', () {
      test('reconnectAttempts can be negative', () {
        final state = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: -1,
          isClosed: false,
          lastActiveTimestamp: 1000,
        );
        expect(state.reconnectAttempts, equals(-1));
      });

      test('lastActiveTimestamp can be 0', () {
        final state = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: 0,
          isClosed: false,
          lastActiveTimestamp: 0,
        );
        expect(state.lastActiveTimestamp, equals(0));
      });

      test('isClosed can be true', () {
        final state = ConnectionState(
          connectionId: 'conn-1',
          remotePeerId: 'peer-1',
          reconnectAttempts: 5,
          isClosed: true,
          lastActiveTimestamp: 1000,
        );
        expect(state.isClosed, isTrue);
      });
    });
  });
}

void main() {
  testConnectionState();
}
