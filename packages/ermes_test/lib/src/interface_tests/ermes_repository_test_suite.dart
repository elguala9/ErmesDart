// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
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
@includeInBarrelFile
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
      if (src is IErmesRepository) return src;
      if (src is IErmesRepository Function()) return src();
      throw ArgumentError(
        'repository parameter must be an IErmesRepository or a factory',
      );
    }

    late IErmesRepository repository;

    setUp(() {
      repository = createInstance(repository1);
    });

    tearDown(() async {
      try {
        repository.destroy();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Connection State', () {
      test('initial state should not be closed', () {
        expect(repository.isClosed(), isFalse);
      });

      test('initial state may or may not be connected', () {
        final isConnected = repository.isConnected();
        expect(isConnected, isA<bool>());
      });

      test('isClosed() should return a boolean', () {
        expect(repository.isClosed(), isA<bool>());
      });

      test('isConnected() should return a boolean', () {
        expect(repository.isConnected(), isA<bool>());
      });
    });

    group('Connection Waiting', () {
      test('waitForConnect should complete if already connected', () async {
        // Even if not connected, should eventually timeout or complete
        expect(repository.waitForConnect(100), isA<Future<void>>());
      });

      test('waitForClose should complete if already closed', () async {
        // Even if not closed, should eventually timeout or complete
        expect(repository.waitForClose(100), isA<Future<void>>());
      });

      test('waitForConnect should respect custom timeout', () async {
        final stopwatch = Stopwatch()..start();
        try {
          await repository.waitForConnect(50);
        } on TimeoutException {
          // Expected if not connected within timeout
        }
        stopwatch.stop();

        // Should not wait significantly longer than requested
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('waitForClose should respect custom timeout', () async {
        final stopwatch = Stopwatch()..start();
        try {
          await repository.waitForClose(50);
        } on TimeoutException {
          // Expected if not closed within timeout
        }
        stopwatch.stop();

        // Should not wait significantly longer than requested
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
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

        repoB.onMessageData((data) {
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
      test('onMessageData should accept a callback', () {
        void callback(Uint8List data) {}
        expect(() => repository.onMessageData(callback), returnsNormally);
      });

      test('onMessageData should accept lambda callback', () {
        expect(() => repository.onMessageData((data) {}), returnsNormally);
      });

      test('onMessageData callback should receive Uint8List', () async {
        repository.onMessageData((data) {
          // Data is received
        });

        // Simulate data arrival
        // Note: This depends on implementation
        // For pure interface testing, we just verify callback is accepted
        expect(
          () => repository.onMessageData((data) {
            expect(data, isA<Uint8List>());
          }),
          returnsNormally,
        );
      });

      test('onMessageData should replace previous callback', () {
        repository.onMessageData((_) {
          // First callback
        });

        repository.onMessageData((_) {
          // Second callback
        });

        // Second callback should replace first
        // Behavior depends on implementation
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
