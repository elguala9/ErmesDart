import 'type_aliases.dart';

/// Per-connection context mixed into the session-key KDF (RFC section 8.1).
///
/// Two Connections to the same counterpart over different address families
/// derive different key material from the same ECDH shared secret. Both
/// sides use the family of the Connection, never local or remote ports, so
/// the context is identical on each end.
enum ErmesConnectionContext {
  /// Connection carried over IPv4.
  ipv4('ipv4'),

  /// Connection carried over IPv6.
  ipv6('ipv6');

  const ErmesConnectionContext(this.label);

  /// Builds the context from the address family of a Connection.
  factory ErmesConnectionContext.fromFamily({required bool isIpv6}) =>
      isIpv6 ? ErmesConnectionContext.ipv6 : ErmesConnectionContext.ipv4;

  /// Wire label used in the KDF `info` field.
  final String label;
}

/// Key under which the per-connection cipher of [peer] over [context] is
/// stored in the peer cipher handler.
String peerCipherKey(IdAccountType peer, ErmesConnectionContext context) =>
    '$peer|${context.label}';
