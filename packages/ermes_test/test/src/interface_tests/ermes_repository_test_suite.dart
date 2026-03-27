// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:typed_data';


import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesRepository interface
///
/// This suite tests the core repository layer for data transport.
///
/// Usage:
/// ```dart
/// void main() {
///   // Pass two already-initialized repository instances (they should be
///   // prepared by the caller and considered "connected" for exchange tests).
///   testIErmesRepository(
///     'ErmesRepository',
///     repoInstanceA,
///     repoInstanceB,
///   );
/// }
/// ```

void testIErmesRepository(
  String implementationName,
  Object repository1,
  Object repository2,
) {
  group('IErmesRepository - $implementationName', () {
    // Helper to create a fresh instance for each test. The caller may pass
    // either an already-constructed IErmesRepository or a zero-arg factory
    // function that returns one.
    IErmesRepository createInstance(Object src) {
      if (src is IErmesRepository) {
        return src;
      }
      if (src is IErmesRepository Function()) {
        return src();
      }
      throw ArgumentError(
        'repository parameter must be an '
        'IErmesRepository or a factory',
      );
    }

    late IErmesRepository repository;

    setUp(() {
      repository = createInstance(repository1);
    });

    tearDown(() {
      repository.destroy();
    });

    group('Connection State', () {
      test('initial state should not be closed', () {
        expect(repository.isClosed(), isFalse);
      });

      test('initial state may or may not be connected', () {
        final isOpen = repository.isOpen();
        expect(isOpen, isA<bool>());
      });

      test('isClosed() should return a boolean', () {
        expect(repository.isClosed(), isA<bool>());
      });

      test('isOpen() should return a boolean', () {
        expect(repository.isOpen(), isA<bool>());
      });
    });

    

    group('Data Sending', () {
      test('send should accept SerializableDataType', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        expect(() => repository.send(data), returnsNormally);
      });

      test('send should throw if connection is closed', () {
        repository.destroy();
        final data = Uint8List.fromList([1, 2, 3]);
        expect(() => repository.send(data), throwsA(isA<StateError>()));
      });

      test('send should accept empty data', () {
        final emptyData = Uint8List.fromList([]);
        expect(() => repository.send(emptyData), returnsNormally);
      });

      test('send should accept large data', () {
        final largeData = Uint8List(10000);
        expect(() => repository.send(largeData), returnsNormally);
      });

      test('send should be receivable by another repository', () async {
        // Create fresh instances for the exchange test.
        final repoA = createInstance(repository1);
        final repoB = createInstance(repository2);

        final completer = Completer<Uint8List>();

        repoB.addOnMessageDataListener((data) {
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        });

        final payload = Uint8List.fromList([10, 20, 30]);
        repoA.send(payload);

        final received = await completer.future.timeout(
          const Duration(milliseconds: 1000),
        );
        expect(received, equals(payload));
      });
    });

    group('Message Callbacks', () {
      test('addOnMessageDataListener should accept a callback',
          () {
        void callback(Uint8List data) {}
        expect(
          () => repository
              .addOnMessageDataListener(callback),
          returnsNormally,
        );
      });

      test(
          'addOnMessageDataListener should accept '
          'lambda callback', () {
        expect(
          () => repository
              .addOnMessageDataListener((data) {}),
          returnsNormally,
        );
      });

      test(
          'addOnMessageDataListener callback should '
          'receive Uint8List', () async {
        repository.addOnMessageDataListener((data) {
          // Data is received
          expect(data, isA<Uint8List>());
        });

        // Verify the listener was added successfully
        expect(
          () => repository.addOnMessageDataListener((data) {
            expect(data, isA<Uint8List>());
          }),
          returnsNormally,
        );
      });

      test('removeOnMessageDataListener should remove listener', () {
        void callback(Uint8List data) {}
        repository.addOnMessageDataListener(callback);

        // Should not throw
        expect(
          () => repository.removeOnMessageDataListener(callback),
          returnsNormally,
        );
      });

      test('clearOnMessageDataListeners should clear all listeners', () {
        repository.addOnMessageDataListener((_) {});
        repository.addOnMessageDataListener((_) {});

        // Should not throw
        expect(
          () => repository.clearOnMessageDataListeners(),
          returnsNormally,
        );
      });
    });

    group('Resource Cleanup', () {
      test('destroy should mark connection as closed', () {
        expect(repository.isClosed(), isFalse);
        repository.destroy();
        expect(repository.isClosed(), isTrue);
      });

      test('destroy should accept force parameter', () {
        expect(() => repository.destroy(force: true), returnsNormally);
      });

      test('destroy should accept force: false parameter', () {
        expect(() => repository.destroy(), returnsNormally);
      });

      test('destroy should be idempotent', () {
        repository.destroy();
        expect(() => repository.destroy(), returnsNormally);
      });

      test('send should throw after destroy', () {
        repository.destroy();
        final data = Uint8List.fromList([1, 2, 3]);
        expect(() => repository.send(data), throwsA(isA<StateError>()));
      });
    });

    group('State Transitions', () {
      test('destroy should transition to closed state', () async {
        expect(repository.isClosed(), isFalse);
        repository.destroy();
        expect(repository.isClosed(), isTrue);
      });

      test('multiple destroy calls should be safe', () {
        expect(() => repository.destroy(), returnsNormally);
        expect(() => repository.destroy(), returnsNormally);
        expect(() => repository.destroy(), returnsNormally);
      });
    });
  });
}
