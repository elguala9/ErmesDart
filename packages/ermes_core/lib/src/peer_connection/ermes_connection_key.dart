import 'package:iermes/iermes.dart';

/// Identity of one Connection: a remote peer over one address family
/// (RFC section 2, "Connection").
///
/// Everything that is per Connection (message-id sequence, cipher state,
/// ack / retransmission state) is keyed by this, never by the peer alone.
class ErmesConnectionKey {
  /// Creates the key of [peer] over [context].
  const ErmesConnectionKey(this.peer, this.context);

  /// Remote peer of the Connection.
  final IdAccountType peer;

  /// Address family of the Connection.
  final ErmesConnectionContext context;

  /// Key of this Connection in the peer cipher handler.
  String get cipherKey => peerCipherKey(peer, context);

  @override
  bool operator ==(Object other) =>
      other is ErmesConnectionKey &&
      other.peer == peer &&
      other.context == context;

  @override
  int get hashCode => Object.hash(peer, context);

  @override
  String toString() => cipherKey;
}
