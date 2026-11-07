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
}) {
  if (localIdSignaling == null || localIdSignaling.isEmpty) {
    throw SignalingException('A signal must carry the local IdSignaling');
  }
  final ipv4 = isIpv4(addr.publicIp) ? addr.publicIp : '';
  final ipv6 = isIpv6(addr.publicIp) ? addr.publicIp : '';
  final port = addr.publicPort.toString();
  final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  return SignalErmes(
    idSignaling: localIdSignaling,
    ipv4: ipv4,
    ipv4Port: ipv4.isEmpty ? '' : port,
    ipv6: ipv6,
    ipv6Port: ipv6.isEmpty ? '' : port,
    publicKey: localPublicKey ?? '',
    epochTimestampStartConversation: nowEpoch,
    epochTimestampExpireConversation: nowEpoch + secondsExpirationDefault,
  );
}

/// Builds an SHSP peer from [signal], preferring IPv6 over IPv4. Throws
/// [SignalingException] when the signal carries no usable address.
ShspPeer buildPeerFromSignal(
  ISignalErmes signal,
  IdAccountType? peerId,
  IShspSocket socket,
) {
  final useV6 = signal.ipv6.isNotEmpty && signal.ipv6Port.isNotEmpty;
  final useV4 = signal.ipv4.isNotEmpty && signal.ipv4Port.isNotEmpty;
  if (!useV6 && !useV4) {
    throw SignalingException('No valid IP address found in signal');
  }
  return ShspPeerFactory.create(
    remotePeer: ErmesPeerInfo(
      address: InternetAddress(useV6 ? signal.ipv6 : signal.ipv4),
      port: int.parse(useV6 ? signal.ipv6Port : signal.ipv4Port),
      id: peerId,
    ),
    socket: socket,
  );
}
