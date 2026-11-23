import 'dart:io';

import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../stun/fresh_socket_stun.dart';
import '../stun/stun_discovery.dart';
import '../support/ermes_signal_type.dart';
import '../support/exceptions.dart';

/// Default lifetime, in seconds, of a signaling conversation (10 minutes).
const int secondsExpirationDefault = 600; // 10 minutes

/// Builds the local signal advertising [addr] and carrying the publisher's
/// [localIdSignaling] (RFC section 6.1). Throws [SignalingException] when the
/// id is missing or empty.
SignalErmes buildLocalSignal(
  PublicAddress addr, {
  required String? localIdSignaling,
  String? localPublicKey,
}) => buildLocalDualSignal(
  [addr],
  localIdSignaling: localIdSignaling,
  localPublicKey: localPublicKey,
);

/// Builds the local signal advertising every endpoint in [addrs]: an IPv4
/// pair, an IPv6 pair, or both (RFC section 6.2). Throws
/// [SignalingException] when the id is missing or empty.
SignalErmes buildLocalDualSignal(
  List<PublicAddress> addrs, {
  required String? localIdSignaling,
  String? localPublicKey,
}) {
  if (localIdSignaling == null || localIdSignaling.isEmpty) {
    throw SignalingException('A signal must carry the local IdSignaling');
  }
  final v4 = addrs.where((a) => isIpv4(a.publicIp));
  final v6 = addrs.where((a) => isIpv6(a.publicIp));
  final ipv4 = v4.isEmpty ? '' : v4.first.publicIp;
  final ipv6 = v6.isEmpty ? '' : v6.first.publicIp;
  final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  return SignalErmes(
    idSignaling: localIdSignaling,
    ipv4: ipv4,
    ipv4Port: ipv4.isEmpty ? '' : v4.first.publicPort.toString(),
    ipv6: ipv6,
    ipv6Port: ipv6.isEmpty ? '' : v6.first.publicPort.toString(),
    publicKey: localPublicKey ?? '',
    epochTimestampStartConversation: nowEpoch,
    epochTimestampExpireConversation: nowEpoch + secondsExpirationDefault,
  );
}

/// Builds an SHSP peer from [signal], preferring IPv6 over IPv4. When
/// [socketIpv6] is given it carries the IPv6 endpoint and [socket] the IPv4
/// one; otherwise [socket] carries whichever family is chosen. Throws
/// [SignalingException] when the signal carries no usable address.
ShspPeer buildPeerFromSignal(
  ISignalErmes signal,
  IdAccountType? peerId,
  IShspSocket socket, {
  IShspSocket? socketIpv6,
}) {
  final hasV6 = signal.ipv6.isNotEmpty && signal.ipv6Port.isNotEmpty;
  final hasV4 = signal.ipv4.isNotEmpty && signal.ipv4Port.isNotEmpty;
  if (!hasV6 && !hasV4) {
    throw SignalingException('No valid IP address found in signal');
  }
  final useV6 = hasV6;
  return ShspPeerFactory.create(
    remotePeer: ErmesPeerInfo(
      address: InternetAddress(useV6 ? signal.ipv6 : signal.ipv4),
      port: int.parse(useV6 ? signal.ipv6Port : signal.ipv4Port),
      id: peerId,
    ),
    socket: useV6 ? (socketIpv6 ?? socket) : socket,
  );
}
