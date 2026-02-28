
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesSignalingService interface
///
/// Usage:
/// ```dart
/// void main() {
///   testIErmesSignalingService(
///     'MyService',
///     () => MySignalingService(),
///   );
/// }
/// ```

void testIErmesSignalingService(
  String implementationName,
  IErmesSignalingService Function() createInstance,
) {
  group('IErmesSignalingService - $implementationName', () {
    late IErmesSignalingService service;

    setUp(() {
      service = createInstance();
    });

    tearDown(() async {
      try {
        await service.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Basic Operations', () {
      test('isConnected returns boolean', () async {
        final result = await service.isConnected();
        expect(result, isA<bool>());
      });

      test('getIdAccount returns string', () async {
        final result = await service.getIdAccount();
        expect(result, isA<String>());
      });

      test('destroy completes', () async {
        expect(() => service.destroy(), returnsNormally);
      });
    });

    group('Signal Handling', () {
      test('onSignal registers callback', () async {
        expect(() => service.onSignal((socket) async {}), returnsNormally);
      });

      test('sendSignal completes', () async {
        expect(() => service.sendSignal('peer-id'), returnsNormally);
      });

      test('removeAllListeners works', () {
        expect(() => service.removeAllListeners(), returnsNormally);
      });
    });

    group('Service Workflow', () {
      test('complete service lifecycle', () async {
        // Check connection
        final connected = await service.isConnected();
        expect(connected, isA<bool>());

        // Get account
        final account = await service.getIdAccount();
        expect(account, isA<String>());

        // Setup callback
        service.onSignal((socket) async {
          expect(socket, isNotNull);
        });

        // Send signal
        await service.sendSignal('test-peer');

        // Cleanup
        service.removeAllListeners();
        await service.destroy();
      });

      test('multiple signal operations', () async {
        await service.sendSignal('peer-1');
        await service.sendSignal('peer-2');
        await service.sendSignal('peer-3');

        // Should complete without errors
      });
    });

    group('Error Resilience', () {
      test('handles empty peer IDs', () async {
        expect(() => service.sendSignal(''), returnsNormally);
      });

      test('multiple destroy calls safe', () async {
        await service.destroy();
        expect(() => service.destroy(), returnsNormally);
      });
    });
  });
}
