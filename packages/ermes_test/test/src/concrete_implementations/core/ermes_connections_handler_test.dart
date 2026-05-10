import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

class _TestConnection implements IErmesConnection {
  _TestConnection(this._id);
  final IdPeer _id;

  @override
  IdPeer getIdConnection() => _id;

  @override
  Future<IErmesRepository> connect() async {
    throw UnimplementedError();
  }

  @override
  Future<void> destroyConnection({bool close = true}) async {}

  @override
  IErmesRepository getIErmesRepository() => throw UnimplementedError();

  @override
  void resetReconnectAttempts() {}
}

void testErmesConnectionsHandler() {
  group('ErmesConnectionsHandler', () {
    late ErmesConnectionsHandler handler;

    setUp(() {
      handler = ErmesConnectionsHandler();
    });

    group('initial state', () {
      test('numberOfConnections is 0', () {
        expect(handler.numberOfConnections, equals(0));
      });

      test('getAllConnectionIds returns empty list', () {
        expect(handler.getAllConnectionIds(), isEmpty);
      });

      test('hasConnection returns false for any id', () {
        expect(handler.hasConnection('any-id'), isFalse);
      });
    });

    group('addConnection()', () {
      test('increases connection count', () {
        final conn = _TestConnection('peer-1');
        handler.addConnection(conn);
        expect(handler.numberOfConnections, equals(1));
      });

      test('multiple connections increase count', () {
        handler.addConnection(_TestConnection('peer-1'));
        handler.addConnection(_TestConnection('peer-2'));
        handler.addConnection(_TestConnection('peer-3'));
        expect(handler.numberOfConnections, equals(3));
      });

      test('getAllConnectionIds returns added ids', () {
        handler.addConnection(_TestConnection('peer-1'));
        handler.addConnection(_TestConnection('peer-2'));
        final ids = handler.getAllConnectionIds();
        expect(ids, containsAll(['peer-1', 'peer-2']));
      });

      test('hasConnection returns true after add', () {
        handler.addConnection(_TestConnection('peer-1'));
        expect(handler.hasConnection('peer-1'), isTrue);
      });
    });

    group('deleteConnection()', () {
      test('decreases connection count', () {
        final conn = _TestConnection('peer-1');
        handler.addConnection(conn);
        handler.deleteConnection(conn);
        expect(handler.numberOfConnections, equals(0));
      });

      test('removes specific connection', () {
        handler.addConnection(_TestConnection('peer-1'));
        final conn2 = _TestConnection('peer-2');
        handler.addConnection(conn2);
        handler.deleteConnection(conn2);
        expect(handler.getAllConnectionIds(), equals(['peer-1']));
      });

      test('hasConnection returns false after delete', () {
        final conn = _TestConnection('peer-1');
        handler.addConnection(conn);
        handler.deleteConnection(conn);
        expect(handler.hasConnection('peer-1'), isFalse);
      });
    });

    group('getConnection()', () {
      test('returns the correct connection', () {
        final conn = _TestConnection('peer-1');
        handler.addConnection(conn);
        final retrieved = handler.getConnection('peer-1');
        expect(retrieved, same(conn));
      });

      test('throws for non-existent connection', () {
        expect(
          () => handler.getConnection('non-existent'),
          throwsA(isA<Exception>()),
        );
      });

      test('error message contains peer ID', () {
        try {
          handler.getConnection('missing-peer');
        } on Exception catch (e) {
          expect(e.toString(), contains('missing-peer'));
        }
      });
    });

    group('saveState()', () {
      test('does not throw with no connections', () async {
        await handler.saveState();
      });

      test('does not throw with connections', () async {
        handler.addConnection(_TestConnection('peer-1'));
        await handler.saveState();
      });
    });

    group('loadState()', () {
      test('does not throw', () async {
        await handler.loadState();
      });
    });

    group('clearAllConnections()', () {
      test('removes all connections', () {
        handler.addConnection(_TestConnection('peer-1'));
        handler.addConnection(_TestConnection('peer-2'));
        handler.clearAllConnections();
        expect(handler.numberOfConnections, equals(0));
        expect(handler.getAllConnectionIds(), isEmpty);
      });

      test('is idempotent', () {
        handler.clearAllConnections();
        handler.clearAllConnections();
        expect(handler.numberOfConnections, equals(0));
      });
    });

    group('edge cases', () {
      test('delete non-existent connection does not throw', () {
        final conn = _TestConnection('non-existent');
        handler.deleteConnection(conn);
        expect(handler.numberOfConnections, equals(0));
      });

      test('add same peer id twice keeps last', () {
        handler.addConnection(_TestConnection('peer-1'));
        final conn2 = _TestConnection('peer-1');
        handler.addConnection(conn2);
        final retrieved = handler.getConnection('peer-1');
        expect(retrieved, same(conn2));
      });
    });
  });
}

void main() {
  testErmesConnectionsHandler();
}
