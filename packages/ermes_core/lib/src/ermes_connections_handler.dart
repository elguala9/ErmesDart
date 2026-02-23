import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// 1️⃣ ErmesConnectionsHandler - Gestore centralizzato connessioni
/// Tradotto da: ErmesConnectionsHandler.ts
///
/// Responsabilità:
/// - Gestione Map<IdPeer, IErmesConnection>
/// - Salvataggio/caricamento stato connessioni
/// - Query numero connessioni attive
@includeInBarrelFile
class ErmesConnectionsHandler implements IErmesConnectionsHandler {
  final Map<IdPeer, IErmesConnection> _connections = {};

  @override
  void addConnection(IErmesConnection connection) {
    final peerId = connection.getIdConnection();
    _connections[peerId] = connection;
  }

  @override
  void deleteConnection(IErmesConnection connection, {bool close = true}) {
    final peerId = connection.getIdConnection();
    _connections.remove(peerId);
  }

  @override
  IErmesConnection getConnection(IdPeer id) {
    final connection = _connections[id];
    if (connection == null) {
      throw Exception('Connection not found for peer ID: $id');
    }
    return connection;
  }

  @override
  Future<void> saveState() async {
    _serializeConnectionsState();
  }

  @override
  Future<void> loadState() async {
    try {
      // Loading connections state logic would go here
    } on Exception catch (error) {
      if (!error.toString().contains('not found')) {
        throw Exception('Failed to load connections state: $error');
      }
    }
  }

  Map<String, dynamic> _serializeConnectionsState() => {
    'connectionIds': _connections.keys.toList(),
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'version': '1.0',
  };

  int get numberOfConnections => _connections.length;

  List<IdPeer> getAllConnectionIds() => _connections.keys.toList();

  void clearAllConnections() => _connections.clear();

  bool hasConnection(IdPeer peerId) => _connections.containsKey(peerId);
}
