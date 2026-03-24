import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

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
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) async =>
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
// Test helper: minimal IErmesRepository
// ---------------------------------------------------------------------------

class _StubRepository implements IErmesRepository {
  @override
  void send(SerializableDataType data) {}

  @override
  void addOnMessageDataListener(CallbackOnDataRepository callback) {}

  @override
  void removeOnMessageDataListener(CallbackOnDataRepository callback) {}

  @override
  void clearOnMessageDataListeners() {}

  @override
  void destroy({bool force = false}) {}

  @override
  String get remotePeerId => 'stub-remote-peer';

  @override
  bool isClosed() => false;

  @override
  bool isClosing() => false;

  @override
  bool isOpen() => true;
}

// ---------------------------------------------------------------------------
// Test helper: minimal IErmesConnection for ConnectionsHandler tests
// ---------------------------------------------------------------------------

class _StubConnection implements IErmesConnection {
  _StubConnection(this._id, this._repo);

  final IdPeer _id;
  final IErmesRepository _repo;

  @override
  IdPeer getIdConnection() => _id;

  @override
  IErmesRepository getIErmesRepository() => _repo;

  @override
  Future<IErmesRepository> connect() async => _repo;

  @override
  Future<void> destroyConnection({bool close = true}) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void testErmesConnectionConcrete() {
  group('ErmesConnection', () {
    late _TrackingSignalingHandler handler;
    late _StubRepository repo;
    late ErmesConnection connection;

    const connectionId = 'peer-test-001';

    setUp(() {
      handler = _TrackingSignalingHandler();
      repo = _StubRepository();
      connection = ErmesConnection(handler, repo, connectionId);
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
        // connect() resets counter on success, so use a handler that throws
        // clearConnection → the counter increments but is never reset
        final failingHandler = _FailingClearHandler();
        final failConn =
            ErmesConnection(failingHandler, repo, 'fail-peer');

        // 3 failures: counter goes 1 → 2 → 3, not reset because of throw
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
    late ErmesConnectionsHandler handler;
    late _StubConnection connA;
    late _StubConnection connB;

    setUp(() {
      handler = ErmesConnectionsHandler();
      connA = _StubConnection('peer-alice', _StubRepository());
      connB = _StubConnection('peer-bob', _StubRepository());
    });

    test('starts with 0 connections', () {
      expect(handler.numberOfConnections, equals(0));
    });

    group('addConnection', () {
      test('stores a connection', () {
        handler.addConnection(connA);
        expect(handler.numberOfConnections, equals(1));
      });

      test('stores multiple connections independently', () {
        handler.addConnection(connA);
        handler.addConnection(connB);
        expect(handler.numberOfConnections, equals(2));
      });
    });

    group('getConnection', () {
      test('returns the stored connection by peer id', () {
        handler.addConnection(connA);
        expect(handler.getConnection('peer-alice'), same(connA));
      });

      test('throws for unknown peer id', () {
        expect(
          () => handler.getConnection('unknown-peer'),
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
      test('removes the connection', () {
        handler.addConnection(connA);
        handler.deleteConnection(connA);
        expect(handler.numberOfConnections, equals(0));
      });

      test('does not affect other connections', () {
        handler.addConnection(connA);
        handler.addConnection(connB);
        handler.deleteConnection(connA);
        expect(handler.numberOfConnections, equals(1));
        expect(handler.getConnection('peer-bob'), same(connB));
      });
    });

    group('hasConnection', () {
      test('returns true for a stored peer', () {
        handler.addConnection(connA);
        expect(handler.hasConnection('peer-alice'), isTrue);
      });

      test('returns false for an unknown peer', () {
        expect(handler.hasConnection('nobody'), isFalse);
      });
    });

    group('getAllConnectionIds', () {
      test('returns empty list when no connections', () {
        expect(handler.getAllConnectionIds(), isEmpty);
      });

      test('returns all peer ids', () {
        handler.addConnection(connA);
        handler.addConnection(connB);
        final ids = handler.getAllConnectionIds();
        expect(ids.toSet(), equals({'peer-alice', 'peer-bob'}));
      });
    });

    group('clearAllConnections', () {
      test('removes all connections', () {
        handler.addConnection(connA);
        handler.addConnection(connB);
        handler.clearAllConnections();
        expect(handler.numberOfConnections, equals(0));
      });
    });

    group('saveState / loadState', () {
      test('saveState does not throw', () async {
        handler.addConnection(connA);
        await expectLater(handler.saveState(), completes);
      });

      test('loadState does not throw', () async {
        await expectLater(handler.loadState(), completes);
      });
    });
  });
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

void main() => testErmesConnectionConcrete();
