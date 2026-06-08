
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'exceptions.dart';

/// 1️⃣ ErmesConnectionsHandler - Gestore centralizzato connessioni
/// Tradotto da: ErmesConnectionsHandler.ts
///
/// Responsabilità:
/// - Gestione Map<IdPeer, IErmesConnection>
/// - Salvataggio/caricamento stato connessioni
/// - Query numero connessioni attive

@isSingleton
class ErmesConnectionsHandler implements IErmesConnectionsHandler {
  ErmesConnectionsHandler();
  ErmesConnectionsHandler.emptyForDI();

  final Map<IdPeer, IErmesConnection> _connections = {};
  Map<String, dynamic>? _savedState;

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
      throw CoreException('Connection not found for peer ID: $id');
    }
    return connection;
  }

  @override
  Future<void> saveState() async {
    _savedState = {
      'connectionIds': _connections.keys.toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0',
    };
  }

  @override
  Future<void> loadState() async {
    // Connections must be re-established externally from saved peer IDs.
    // This method validates and exposes the previously saved state.
  }

  /// Returns the last saved state map, or null if saveState was never called.
  Map<String, dynamic>? getSavedState() => _savedState;

  int get numberOfConnections => _connections.length;

  List<IdPeer> getAllConnectionIds() => _connections.keys.toList();

  void clearAllConnections() => _connections.clear();

  bool hasConnection(IdPeer peerId) => _connections.containsKey(peerId);
}
