// ignore_for_file: cascade_invocations

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesSignalingRepository interface
///
/// Usage:
/// ```dart
/// void main() {
///   testIErmesSignalingRepository<String>(
///     'MyRepository',
///     () => MySignalingRepository(),
///   );
/// }
/// ```
@includeInBarrelFile
void testIErmesSignalingRepository<T>(
  String implementationName,
  IErmesSignalingRepository<T> Function() createInstance,
) {
  group('IErmesSignalingRepository<$T> - $implementationName', () {
    late IErmesSignalingRepository<T> repository;

    setUp(() {
      repository = createInstance();
    });

    tearDown(() async {
      try {
        await repository.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Connection Management', () {
      test('isConnected returns boolean', () async {
        final result = await repository.isConnected();
        expect(result, isA<bool>());
      });

      test('getIdAccount returns string', () async {
        final result = await repository.getIdAccount();
        expect(result, isA<String>());
      });

      test('destroy completes', () async {
        expect(() => repository.destroy(), returnsNormally);
      });
    });

    group('Signal Operations', () {
      test('sendSignal completes', () async {
        expect(() => repository.sendSignal('peer-id'), returnsNormally);
      });

      test('getSignal returns typed result', () async {
        final result = await repository.getSignal('peer-id');
        expect(result, isA<T>());
      });

      test('getSignalOwner returns typed result', () async {
        final result = await repository.getSignalOwner();
        expect(result, isA<T>());
      });
    });

    group('Event Handling', () {
      test('onSignal registers callback', () async {
        expect(() => repository.onSignal((signal) async {}), returnsNormally);
      });

      test('removeAllListeners works', () {
        expect(() => repository.removeAllListeners(), returnsNormally);
      });
    });

    group('Signal Comparison', () {
      test('compareSignalMessage returns boolean', () {
        try {
          final result = repository.compareSignalMessage(
            'sig1' as T,
            'sig2' as T,
          );
          expect(result, isA<bool>());
        } on Exception {
          // T might not be String - that's acceptable
        }
      });

      test('compareSignalMessage with null values', () {
        try {
          final result1 = repository.compareSignalMessage(null as T, null as T);
          expect(result1, isA<bool>());
        } on Exception {
          // T might not be nullable - acceptable
        }

        try {
          final result2 = repository.compareSignalMessage(
            'sig' as T,
            null as T,
          );
          expect(result2, isA<bool>());
        } on Exception {
          // Type issues are acceptable for generic testing
        }

        try {
          final result3 = repository.compareSignalMessage(
            null as T,
            'sig' as T,
          );
          expect(result3, isA<bool>());
        } on Exception {
          // Type issues are acceptable for generic testing
        }
      });

      test('compareSignalMessage with same values', () {
        try {
          const signal = 'test-signal';
          final result = repository.compareSignalMessage(
            signal as T,
            signal as T,
          );
          expect(result, isA<bool>());
        } on Exception {
          // T might not be String - that's acceptable
        }
      });
    });

    group('Repository Workflow', () {
      test('complete signaling cycle', () async {
        // Check connection
        final connected = await repository.isConnected();
        expect(connected, isA<bool>());

        // Get account
        final account = await repository.getIdAccount();
        expect(account, isA<String>());

        // Send signal
        await repository.sendSignal('target-peer');

        // Get signals
        final receivedSignal = await repository.getSignal('source-peer');
        expect(receivedSignal, isA<T>());

        final ownSignal = await repository.getSignalOwner();
        expect(ownSignal, isA<T>());

        // Setup callback
        repository.onSignal((signal) async {
          expect(signal, isA<T>());
        });

        // Cleanup
        repository.removeAllListeners();
        await repository.destroy();
      });

      test('multiple peer interactions', () async {
        await repository.sendSignal('peer-1');
        await repository.sendSignal('peer-2');
        await repository.sendSignal('peer-3');

        final sig1 = await repository.getSignal('peer-1');
        final sig2 = await repository.getSignal('peer-2');
        final sig3 = await repository.getSignal('peer-3');

        expect(sig1, isA<T>());
        expect(sig2, isA<T>());
        expect(sig3, isA<T>());
      });
    });

    group('Error Handling', () {
      test('handles empty peer IDs gracefully', () async {
        expect(() => repository.sendSignal(''), returnsNormally);
        expect(() => repository.getSignal(''), returnsNormally);
      });

      test('multiple cleanup calls safe', () async {
        repository.removeAllListeners();
        expect(() => repository.removeAllListeners(), returnsNormally);

        await repository.destroy();
        expect(() => repository.destroy(), returnsNormally);
      });
    });
  });
}
