import 'package:iermes/iermes.dart';

import '../support/exceptions.dart';
import 'ermes_connection_key.dart';
import 'ermes_peer.dart';

/// The independent Connections to one remote peer, at most one per address
/// family (RFC section 5: failure or migration of one family MUST NOT affect
/// the other).
///
/// No state is shared between the members: each [ErmesPeer] owns its id
/// sequence, cipher state and ack / retransmission state. There is no
/// cross-family failover and no merging of message streams.
class ErmesPeerConnections {
  /// Creates an empty aggregate for [peer].
  ErmesPeerConnections(this.peer);

  /// Remote peer all the members connect to.
  final IdAccountType peer;

  final Map<ErmesConnectionContext, ErmesPeer> _byFamily = {};

  /// Send preference when no family is requested: IPv6 first.
  static const List<ErmesConnectionContext> _preference = [
    ErmesConnectionContext.ipv6,
    ErmesConnectionContext.ipv4,
  ];

  /// Families that currently have a Connection (live or not).
  List<ErmesConnectionContext> get contexts => _byFamily.keys.toList();

  /// Keys of the Connections held, one per family.
  List<ErmesConnectionKey> get keys => [
    for (final c in _byFamily.keys) ErmesConnectionKey(peer, c),
  ];

  /// Families whose Connection is currently live.
  List<ErmesConnectionContext> get connectedContexts => [
    for (final e in _byFamily.entries)
      if (e.value.isConnected()) e.key,
  ];

  /// Every Connection held, live or not.
  Iterable<ErmesPeer> get members => _byFamily.values;

  /// Whether a Connection over [context] is held.
  bool has(ErmesConnectionContext context) => _byFamily.containsKey(context);

  /// Connection over [context]; throws when that family is not held.
  ErmesPeer connectionOf(ErmesConnectionContext context) =>
      _byFamily[context] ??
      (throw CoreException('No ${context.label} Connection to $peer'));

  /// Adds (or replaces) the Connection over [context].
  void add(ErmesConnectionContext context, ErmesPeer connection) =>
      _byFamily[context] = connection;

  /// Whether at least one family is live.
  bool isConnected() => connectedContexts.isNotEmpty;

  /// Whether every held family is live (and at least one is held).
  bool isFullyConnected() =>
      _byFamily.isNotEmpty && connectedContexts.length == _byFamily.length;

  /// Sends [data] over [over], or over the preferred live family when
  /// omitted (the first held one when none is live, so it is queued).
  Future<void> send(TypeOfDataExternal data, {ErmesConnectionContext? over}) =>
      connectionOf(over ?? _defaultFamily()).send(data);

  ErmesConnectionContext _defaultFamily() {
    final live = connectedContexts;
    for (final context in _preference) {
      if (live.contains(context)) {
        return context;
      }
    }
    for (final context in _preference) {
      if (has(context)) {
        return context;
      }
    }
    throw CoreException('No Connection to $peer');
  }

  /// Disposes and forgets only the Connection over [context].
  Future<void> remove(ErmesConnectionContext context) async {
    final connection = _byFamily.remove(context);
    await connection?.dispose();
  }

  /// Disposes and forgets the families that are no longer live, leaving the
  /// live ones untouched. Returns the families removed.
  Future<List<ErmesConnectionContext>> removeDisconnected() async {
    final dead = [
      for (final e in _byFamily.entries)
        if (!e.value.isConnected()) e.key,
    ];
    for (final context in dead) {
      await remove(context);
    }
    return dead;
  }

  /// Disposes every Connection and forgets them.
  Future<void> dispose({bool flushBeforeClose = true}) async {
    final all = _byFamily.values.toList();
    _byFamily.clear();
    for (final connection in all) {
      await connection.dispose(flushBeforeClose: flushBeforeClose);
    }
  }
}
