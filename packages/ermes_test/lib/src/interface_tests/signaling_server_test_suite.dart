import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

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
      } catch (_) {
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
        expect(() => server.setSignal('test-signal'), returnsNormally);
      });

      test('setSignal with target completes', () async {
        expect(
          () => server.setSignal('test-signal', 'target-peer'),
          returnsNormally,
        );
      });

      test('getSignal returns string', () async {
        final result = await server.getSignal('peer-id');
        expect(result, isA<String>());
      });

      test('getSignal with different peer IDs', () async {
        final result1 = await server.getSignal('peer-1');
        final result2 = await server.getSignal('peer-2');

        expect(result1, isA<String>());
        expect(result2, isA<String>());
      });
    });

    group('Event Handling', () {
      test('onSignal registers callback without error', () {
        expect(
          () => server.onSignal((signal) {}),
          returnsNormally,
        );
      });

      test('onSignal with from parameter', () {
        expect(
          () => server.onSignal((signal) {}, 'specific-peer'),
          returnsNormally,
        );
      });

      test('onError registers callback', () {
        expect(
          () => server.onError((error) {}),
          returnsNormally,
        );
      });

      test('onClose registers callback', () {
        expect(
          () => server.onClose(() {}),
          returnsNormally,
        );
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
        await server.setSignal('offer', 'remote-peer');
        final signal = await server.getSignal('remote-peer');
        expect(signal, isA<String>());

        // Event handling
        var callbackCalled = false;
        server.onSignal((receivedSignal) {
          callbackCalled = true;
          expect(receivedSignal, isA<String>());
        });

        // Cleanup
        await server.removeAllListeners();
        await server.destroy();
      });

      test('multiple signal exchange', () async {
        await server.setSignal('signal-1', 'peer-1');
        await server.setSignal('signal-2', 'peer-2');
        await server.setSignal('signal-3', 'peer-3');

        final sig1 = await server.getSignal('peer-1');
        final sig2 = await server.getSignal('peer-2');
        final sig3 = await server.getSignal('peer-3');

        expect(sig1, isA<String>());
        expect(sig2, isA<String>());
        expect(sig3, isA<String>());
      });

      test('error handling resilience', () async {
        // Should not throw on null/empty parameters
        expect(() => server.getSignal(''), returnsNormally);
        expect(() => server.setSignal(''), returnsNormally);
      });
    });
  });
}
