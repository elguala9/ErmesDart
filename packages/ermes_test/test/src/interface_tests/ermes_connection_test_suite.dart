// ignore_for_file: cascade_invocations

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesConnection interface
///
/// Usage:
/// ```dart
/// void main() {
///   testIErmesConnection('ErmesConnection', () {
///     final signalingHandler = createSignalingHandler();
///     final repository = createRepository();
///     final connectionId = IdPeer(12345);
///     return ErmesConnection(signalingHandler, repository, connectionId);
///   });
/// }
/// ```
@includeInBarrelFile
void testIErmesConnection(
  String implementationName,
  IErmesConnection Function() createInstance,
) {
  group('IErmesConnection - $implementationName', () {
    late IErmesConnection connection;

    setUp(() {
      connection = createInstance();
    });

    tearDown(() async {
      try {
        await connection.close();
      } on Exception {
        // Ignore cleanup errors
      }
    });

    group('Connection Initialization', () {
      test('should create instance successfully', () {
        expect(connection, isNotNull);
      });

      test('should not be closed initially', () async {
        final isClosed = await connection.isClosed();
        expect(isClosed, isFalse);
      });

      test('getIErmesRepository returns valid repository', () {
        final repo = connection.getIErmesRepository();
        expect(repo, isA<IErmesRepository>());
      });

      test('getIdConnection returns valid IdPeer', () {
        final id = connection.getIdConnection();
        expect(id, isA<IdPeer>());
      });
    });

    group('Connection Lifecycle - Close', () {
      test('close completes without error', () async {
        expect(() => connection.close(), completes);
      });

      test('close marks connection as closed', () async {
        await connection.close();
        final isClosed = await connection.isClosed();
        expect(isClosed, isTrue);
      });

      test('close is idempotent', () async {
        await connection.close();
        expect(() => connection.close(), completes);
        final isClosed = await connection.isClosed();
        expect(isClosed, isTrue);
      });

      test('isClosed returns Future<bool>', () async {
        final result = connection.isClosed();
        expect(result, isA<Future<bool>>());
      });

      test('isClosed reflects actual state', () async {
        expect(await connection.isClosed(), isFalse);
        await connection.close();
        expect(await connection.isClosed(), isTrue);
      });
    });

    group('Connection Health - Ping', () {
      test('ping returns Future<bool>', () {
        final result = connection.ping();
        expect(result, isA<Future<bool>>());
      });

      test('ping completes successfully', () async {
        expect(() async => await connection.ping(), completes);
      });

      test('ping returns false when closed', () async {
        await connection.close();
        final result = await connection.ping();
        expect(result, isFalse);
      });
    });

    group('Connection Callbacks', () {
      test('setCloseCallback accepts callback', () {
        void callback() {}
        expect(() => connection.setCloseCallback(callback), returnsNormally);
      });

      test('setCloseCallback can be called multiple times', () {
        expect(
          () {
            connection.setCloseCallback(() {});
            connection.setCloseCallback(() {});
          },
          returnsNormally,
        );
      });
    });

    group('Reconnection Logic', () {
      test('reconnect returns Future<IErmesRepository>', () {
        final result = connection.reconnect();
        expect(result, isA<Future<IErmesRepository>>());
      });

      test('reconnect completes successfully', () async {
        expect(() async => await connection.reconnect(), completes);
      });

      test('reconnect returns valid repository', () async {
        final repo = await connection.reconnect();
        expect(repo, isA<IErmesRepository>());
      });

      test('reconnect returns same repository instance', () async {
        final original = connection.getIErmesRepository();
        final reconnected = await connection.reconnect();
        expect(reconnected, equals(original));
      });
    });

    group('State Persistence - Unimplemented', () {
      test('saveState throws UnimplementedError', () async {
        expect(
          () => connection.saveState(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('loadState throws UnimplementedError', () async {
        expect(
          () => connection.loadState(),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('Connection Destruction', () {
      test('destroyConnection completes successfully', () async {
        expect(
          () => connection.destroyConnection(),
          completes,
        );
      });

      test('destroyConnection with close=true closes connection', () async {
        await connection.destroyConnection(close: true);
        final isClosed = await connection.isClosed();
        expect(isClosed, isTrue);
      });

      test('destroyConnection is idempotent', () async {
        await connection.destroyConnection();
        expect(
          () => connection.destroyConnection(),
          completes,
        );
      });
    });

    group('Edge Cases and Error Handling', () {
      test('operations after close are handled gracefully', () async {
        await connection.close();
        expect(() => connection.ping(), completes);
      });

      test('connection state remains consistent', () async {
        expect(await connection.isClosed(), isFalse);
        await connection.close();
        expect(await connection.isClosed(), isTrue);
        await connection.close(); // Second close
        expect(await connection.isClosed(), isTrue);
      });

      test('repository accessible after creation', () {
        final repo1 = connection.getIErmesRepository();
        final repo2 = connection.getIErmesRepository();
        expect(repo1, equals(repo2));
      });
    });
  });
}
