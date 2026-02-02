// ignore_for_file: cascade_invocations

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

// Assumiamo che SignalErmes sia esportato da iermes o importiamo direttamente
// Se non è esportato, dovrai aggiungere l'import specifico

/// Test suite for IErmesSignalingServer interface
///
/// Usage:
/// ```dart
/// void main() {
///   testIErmesSignalingServer(
///     'MyImplementation',
///     () => MySignalingServer(),
///   );
/// }
/// ```
@includeInBarrelFile
void testIErmesSignalingServer(
  String implementationName,
  IErmesSignalingServer Function() createInstance,
) {
  group('IErmesSignalingServer - $implementationName', () {
    late IErmesSignalingServer server;

    setUp(() {
      server = createInstance();
    });

    tearDown(() async {
      try {
        await server.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Connection Management', () {
      test('isConnected returns boolean', () async {
        final result = await server.isConnected();
        expect(result, isA<bool>());
      });

      test('getIdAccount returns string', () async {
        final result = await server.getIdAccount();
        expect(result, isA<String>());
      });

      test('destroy completes without error', () async {
        expect(() => server.destroy(), returnsNormally);
      });
    });

    group('Signal Operations', () {
      test('setSignal with signal only completes', () async {
        // Creando un SignalErmes di test
        final testSignal = _createTestSignal();
        expect(() => server.setSignal(testSignal), returnsNormally);
      });

      test('setSignal with target completes', () async {
        final testSignal = _createTestSignal();
        expect(
          () => server.setSignal(testSignal, 'target-peer'),
          returnsNormally,
        );
      });

      test('getSignal returns ISignalErmes', () async {
        final result = await server.getSignal('peer-id');
        expect(result, isA<ISignalErmes>());
      });

      test('getSignal with different peer IDs', () async {
        final result1 = await server.getSignal('peer-1');
        final result2 = await server.getSignal('peer-2');

        expect(result1, isA<ISignalErmes>());
        expect(result2, isA<ISignalErmes>());
      });
    });

    group('Event Handling', () {
      test('onSignal registers callback without error', () {
        expect(
          () => server.onSignal((signal) {
            expect(signal, isA<ISignalErmes>());
          }),
          returnsNormally,
        );
      });

      test('onSignal with from parameter', () {
        expect(
          () => server.onSignal((signal) {
            expect(signal, isA<ISignalErmes>());
          }, 'specific-peer'),
          returnsNormally,
        );
      });

      test('onError registers callback', () {
        expect(() => server.onError((error) {}), returnsNormally);
      });

      test('onClose registers callback', () {
        expect(() => server.onClose(() {}), returnsNormally);
      });

      test('removeAllListeners completes', () async {
        server.onSignal((signal) {});
        server.onError((error) {});
        server.onClose(() {});

        expect(() => server.removeAllListeners(), returnsNormally);
      });
    });

    group('Integration Scenarios', () {
      test('complete signaling workflow', () async {
        // Setup
        final isConnected = await server.isConnected();
        expect(isConnected, isA<bool>());

        final accountId = await server.getIdAccount();
        expect(accountId, isA<String>());

        // Signal operations
        final testSignal = _createTestSignal();
        await server.setSignal(testSignal, 'remote-peer');
        final signal = await server.getSignal('remote-peer');
        expect(signal, isA<ISignalErmes>());

        // Event handling
        server.onSignal((receivedSignal) {
          expect(receivedSignal, isA<ISignalErmes>());
        });

        // Cleanup
        await server.removeAllListeners();
        await server.destroy();
      });

      test('multiple signal exchange', () async {
        final testSignal1 = _createTestSignal();
        final testSignal2 = _createTestSignal();
        final testSignal3 = _createTestSignal();

        await server.setSignal(testSignal1, 'peer-1');
        await server.setSignal(testSignal2, 'peer-2');
        await server.setSignal(testSignal3, 'peer-3');

        final sig1 = await server.getSignal('peer-1');
        final sig2 = await server.getSignal('peer-2');
        final sig3 = await server.getSignal('peer-3');

        expect(sig1, isA<ISignalErmes>());
        expect(sig2, isA<ISignalErmes>());
        expect(sig3, isA<ISignalErmes>());
      });

      test('error handling resilience', () async {
        // Should not throw on null/empty parameters
        expect(() => server.getSignal(''), returnsNormally);
        final emptySignal = _createTestSignal();
        expect(() => server.setSignal(emptySignal), returnsNormally);
      });
    });
  });
}

/// Helper function to create a test SignalErmes
/// This creates a mock implementation of ISignalErmes for testing
ISignalErmes _createTestSignal() => _TestSignalErmes(
  publicKey: 'test-public-key',
  ipv6: '::1',
  ipv6Port: '8080',
  ipv4: '127.0.0.1',
  ipv4Port: '8080',
  epochTimestampStartConversation:
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
  secondsIntervalWindow: 3600,
  epochTimestampExpireConversation:
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
);

/// Test implementation of ISignalErmes for testing purposes
class _TestSignalErmes implements ISignalErmes {
  _TestSignalErmes({
    required this.publicKey,
    required this.ipv6,
    required this.ipv6Port,
    required this.ipv4,
    required this.ipv4Port,
    required this.epochTimestampStartConversation,
    required this.secondsIntervalWindow,
    required this.epochTimestampExpireConversation,
    this.secondsIntervalOpening = 60,
  });

  @override
  final String publicKey;

  @override
  final String ipv6;

  @override
  final String ipv6Port;

  @override
  final String ipv4;

  @override
  final String ipv4Port;

  @override
  final int epochTimestampStartConversation;

  @override
  final int secondsIntervalWindow;

  @override
  final int epochTimestampExpireConversation;

  @override
  final int secondsIntervalOpening;

  @override
  String toString() =>
      '$publicKey|$ipv6|$ipv6Port|$ipv4|$ipv4Port|'
      '$epochTimestampStartConversation|$secondsIntervalWindow|'
      '$epochTimestampExpireConversation';

  @override
  void fromString(String signalString) {
    throw UnimplementedError('Test stub does not support fromString');
  }

  @override
  bool isExpired() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >
      epochTimestampExpireConversation;

  @override
  String get signal => toString();

  @override
  set signal(String value) {
    fromString(value);
  }
}
