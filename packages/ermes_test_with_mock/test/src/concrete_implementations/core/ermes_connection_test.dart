import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

// ---------------------------------------------------------------------------
// Test helper: minimal IErmesSignalingHandler that records calls
// ---------------------------------------------------------------------------

class _TrackingSignalingHandler
    implements IErmesSignalingHandler<IShspSocket> {
  final List<String> clearedConnections = [];
  final List<String> softClearedConnections = [];

  @override
  Future<void> clearConnection(IdAccountType remotePeerId) async {
    clearedConnections.add(remotePeerId);
  }

  @override
  Future<void> softClearConnection(IdAccountType remotePeerId) async {
    softClearedConnections.add(remotePeerId);
  }

  @override
  Future<List<IdAccountType>> getAllPeerIds() async => [];

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
  ]) async =>
      throw UnimplementedError();

  @override
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<SocketDto<IShspSocket>> getSocket(IdAccountType of) async =>
      throw UnimplementedError();

  @override
  Future<bool> isSocketReady(IdAccountType of) async => false;

  @override
  Future<SocketDto<IShspSocket>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> destroy() async {}
}

// ---------------------------------------------------------------------------
// Helper: handler that throws in clearConnection so the reconnect counter
// is incremented but never reset (connect() only resets on success)
// ---------------------------------------------------------------------------

class _FailingClearHandler extends _TrackingSignalingHandler {
  @override
  Future<void> clearConnection(IdAccountType remotePeerId) async {
    clearedConnections.add(remotePeerId);
    throw Exception('Simulated clearConnection failure');
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void testErmesConnectionConcrete() {
  group('ErmesConnection', () {
    late _TrackingSignalingHandler handler;
    late ErmesRepository repo;
    late RawDatagramSocket rawSocket;
    late ErmesConnection connection;

    const connectionId = 'peer-test-001';

    setUp(() async {
      handler = _TrackingSignalingHandler();
      final result = await createTestRepository(open: true);
      repo = result.repository;
      rawSocket = result.rawSocket;
      connection = ErmesConnection(handler, repo, connectionId);
    });

    tearDown(() {
      rawSocket.close();
    });

    group('getters', () {
      test('getIdConnection returns the connection id', () {
        expect(connection.getIdConnection(), equals(connectionId));
      });

      test('getIErmesRepository returns the provided repository', () {
        expect(connection.getIErmesRepository(), same(repo));
      });
    });

    group('connect', () {
      test('calls clearConnection on the signaling handler', () async {
        await connection.connect();
        expect(handler.clearedConnections, contains(connectionId));
      });

      test('returns the repository on success', () async {
        final result = await connection.connect();
        expect(result, same(repo));
      });

      test('throws after 3 consecutive failed attempts (max exceeded)',
          () async {
        final failingHandler = _FailingClearHandler();
        final result = await createTestRepository(open: true);
        final failRepo = result.repository;
        final failRawSocket = result.rawSocket;

        final failConn =
            ErmesConnection(failingHandler, failRepo, 'fail-peer');

        for (var i = 0; i < 3; i++) {
          await expectLater(
            failConn.connect(),
            throwsA(isA<Exception>()),
          );
        }

        expect(
          failConn.connect,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Maximum reconnection attempts'),
            ),
          ),
        );

        failRawSocket.close();
      });
    });

    group('destroyConnection', () {
      test('calls softClearConnection on the signaling handler', () async {
        await connection.destroyConnection();
        expect(handler.softClearedConnections, contains(connectionId));
      });
    });
  });

  // -------------------------------------------------------------------------

  group('ErmesConnectionsHandler', () {
    late ErmesConnectionsHandler chandler;

    setUp(() {
      chandler = ErmesConnectionsHandler();
    });

    test('starts with 0 connections', () {
      expect(chandler.numberOfConnections, equals(0));
    });

    group('addConnection', () {
      test('stores a connection', () async {
        final c = await _createConn('peer-alice');
        chandler.addConnection(c.connection);
        expect(chandler.numberOfConnections, equals(1));
        c.cleanUp();
      });

      test('stores multiple connections independently', () async {
        final a = await _createConn('peer-alice');
        final b = await _createConn('peer-bob');
        chandler
          ..addConnection(a.connection)
          ..addConnection(b.connection);
        expect(chandler.numberOfConnections, equals(2));
        a.cleanUp();
        b.cleanUp();
      });
    });

    group('getConnection', () {
      test('returns the stored connection by peer id', () async {
        final c = await _createConn('peer-alice');
        chandler.addConnection(c.connection);
        expect(chandler.getConnection('peer-alice'), same(c.connection));
        c.cleanUp();
      });

      test('throws for unknown peer id', () {
        expect(
          () => chandler.getConnection('unknown-peer'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Connection not found'),
            ),
          ),
        );
      });
    });

    group('deleteConnection', () {
      test('removes the connection', () async {
        final c = await _createConn('peer-alice');
        chandler
          ..addConnection(c.connection)
          ..deleteConnection(c.connection);
        expect(chandler.numberOfConnections, equals(0));
        c.cleanUp();
      });

      test('does not affect other connections', () async {
        final a = await _createConn('peer-alice');
        final b = await _createConn('peer-bob');
        chandler
          ..addConnection(a.connection)
          ..addConnection(b.connection)
          ..deleteConnection(a.connection);
        expect(chandler.numberOfConnections, equals(1));
        expect(chandler.getConnection('peer-bob'), same(b.connection));
        a.cleanUp();
        b.cleanUp();
      });
    });

    group('hasConnection', () {
      test('returns true for a stored peer', () async {
        final c = await _createConn('peer-alice');
        chandler.addConnection(c.connection);
        expect(chandler.hasConnection('peer-alice'), isTrue);
        c.cleanUp();
      });

      test('returns false for an unknown peer', () {
        expect(chandler.hasConnection('nobody'), isFalse);
      });
    });

    group('getAllConnectionIds', () {
      test('returns empty list when no connections', () {
        expect(chandler.getAllConnectionIds(), isEmpty);
      });

      test('returns all peer ids', () async {
        final a = await _createConn('peer-alice');
        final b = await _createConn('peer-bob');
        chandler
          ..addConnection(a.connection)
          ..addConnection(b.connection);
        final ids = chandler.getAllConnectionIds();
        expect(ids.toSet(), equals({'peer-alice', 'peer-bob'}));
        a.cleanUp();
        b.cleanUp();
      });
    });

    group('clearAllConnections', () {
      test('removes all connections', () async {
        final a = await _createConn('peer-alice');
        final b = await _createConn('peer-bob');
        chandler
          ..addConnection(a.connection)
          ..addConnection(b.connection)
          ..clearAllConnections();
        expect(chandler.numberOfConnections, equals(0));
        a.cleanUp();
        b.cleanUp();
      });
    });

    group('saveState / loadState', () {
      test('saveState does not throw', () async {
        final c = await _createConn('peer-alice');
        chandler.addConnection(c.connection);
        await expectLater(chandler.saveState(), completes);
        c.cleanUp();
      });

      test('loadState does not throw', () async {
        await expectLater(chandler.loadState(), completes);
      });
    });
  });
}

Future<({ErmesConnection connection, void Function() cleanUp})>
    _createConn(String peerId) async {
  final result = await createTestRepository(peerId: peerId, open: true);
  final handler = _TrackingSignalingHandler();
  final conn = ErmesConnection(handler, result.repository, peerId);
  return (
    connection: conn,
    cleanUp: result.rawSocket.close,
  );
}

void main() => testErmesConnectionConcrete();
