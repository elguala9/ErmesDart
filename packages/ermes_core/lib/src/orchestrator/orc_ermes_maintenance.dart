import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../peer_connection/ermes_connections_handler.dart';
import '../support/exceptions.dart';
import '../utility/utility.dart';
import 'orc_ermes_callbacks.dart';
import 'orc_ermes_connections.dart';
import 'orc_ermes_passthrough.dart';

/// Orchestrator-wide operations: save, destroy, signal publishing and socket
/// refresh.
mixin OrcErmesMaintenance
    on OrcErmesCallbacks, OrcErmesPassthrough, OrcErmesConnections
    implements IOrcErmes<BookData> {
  /// Persistence of the connections state.
  @protected
  ErmesConnectionsHandler get connectionsHandler;

  /// DI key this orchestrator was built under.
  @protected
  String get registryKey;

  @override
  Future<void> destroy({bool force = false}) async {
    try {
      for (final held in connections.values) {
        await held.dispose(flushBeforeClose: !force);
      }
      connections.clear();
      clearMessageCallbacks();
      await signalingHandler.destroy();
      await signalingServer.destroy();
      bookService.destroy();
      connectionsHandler.clearAllConnections();
    } catch (e) {
      if (!force) {
        throw CoreException('Failed to destroy OrcErmes: $e');
      }
    }
  }

  @override
  Future<void> save() async => guardCoreOp(
    'Failed to save connections state',
    connectionsHandler.saveState,
  );

  @override
  Future<void> publishSignal() => guardCoreOp(
    'Failed to publish signal',
    () async {
      await newConnectionOpener().publishOwnSignal(null);
    },
  );

  @override
  Future<void> refreshSocket() => guardCoreOp(
    'Failed to refresh socket',
    () async {
      // Best-effort per family: a host without IPv6 must not block the
      // IPv4 refresh (and vice versa). A no-op when this OrcErmes was built
      // outside the registry (nothing to migrate there).
      await Future.wait([
        _tryMigrate(() => migrateStunShspSocketIpv4(key: registryKey)),
        _tryMigrate(() => migrateStunShspSocketIpv6(key: registryKey)),
      ]);

      // Rediscover our public addresses via STUN (inside `createSignal`) and
      // republish: once as a broadcast, then targeted at every peer.
      await republishOwnSignals();
    },
  );

  /// Republishes our signal as a broadcast, then toward every connected peer.
  @protected
  Future<void> republishOwnSignals() async {
    final opener = newConnectionOpener();
    await refreshOwnSignal(opener, null);
    for (final peer in List.of(connections.keys)) {
      await refreshOwnSignal(opener, peer);
    }
  }

  Future<void> _tryMigrate(
    Future<IStunShspHandler> Function() migrate,
  ) async {
    try {
      await migrate();
    } on Object {
      // Best-effort: this family's migration is retried on the next call.
    }
  }
}
