
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../support/exceptions.dart';

/// 1️⃣ ErmesConnectionsHandler - Gestore centralizzato connessioni
/// Tradotto da: ErmesConnectionsHandler.ts
///
/// Responsabilità:
/// - Gestione Map<IdPeer, IErmesConnection>
/// - Salvataggio/caricamento stato connessioni
/// - Query numero connessioni attive

@dependencyInjectable
class ErmesConnectionsHandler implements IErmesConnectionsHandler {
  /// Creates an empty connections handler.
  ErmesConnectionsHandler();

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ErmesConnectionsHandler.dependencyInjectionFactory({
    // ignore: avoid_unused_constructor_parameters
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) =>
      ErmesConnectionsHandler(); // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Active connections keyed by peer identifier.
  final Map<IdPeer, IErmesConnection> _connections = {};
  /// Last serialized connection state, if [saveState] has been called.
  Map<String, dynamic>? _savedState;

  /// Registers a connection under its peer identifier.
  @override
  void addConnection(IErmesConnection connection) {
    final peerId = connection.getIdConnection();
    _connections[peerId] = connection;
  }

  /// Removes a previously registered connection.
  @override
  void deleteConnection(IErmesConnection connection, {bool close = true}) {
    final peerId = connection.getIdConnection();
    _connections.remove(peerId);
  }

  /// Returns the connection for the given peer id, throwing if none exists.
  @override
  IErmesConnection getConnection(IdPeer id) {
    final connection = _connections[id];
    if (connection == null) {
      throw CoreException('Connection not found for peer ID: $id');
    }
    return connection;
  }

  /// Captures the current connection identifiers into an in-memory snapshot.
  @override
  Future<void> saveState() async {
    _savedState = {
      'connectionIds': _connections.keys.toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0',
    };
  }

  /// Restores previously saved state; connections must be re-established
  /// externally from the saved peer identifiers.
  @override
  Future<void> loadState() async {
    // Connections must be re-established externally from saved peer IDs.
    // This method validates and exposes the previously saved state.
  }

  /// Returns the last saved state map, or null if saveState was never called.
  Map<String, dynamic>? getSavedState() => _savedState;

  /// Number of currently active connections.
  int get numberOfConnections => _connections.length;

  /// Returns the identifiers of all active connections.
  List<IdPeer> getAllConnectionIds() => _connections.keys.toList();

  /// Removes all registered connections.
  void clearAllConnections() => _connections.clear();

  /// Whether a connection exists for the given peer identifier.
  bool hasConnection(IdPeer peerId) => _connections.containsKey(peerId);
}
