import 'dart:io';

import 'package:iermes/iermes.dart';

import '../support/exceptions.dart';

/// Extracts an [ErmesPeerInfo] from a remote [ISignalErmes].
///
/// Prefers IPv6 when present and non-empty, otherwise falls back to
/// IPv4. Throws [CoreException] when neither produces a valid host/port.
ErmesPeerInfo peerInfoFromSignal(ISignalErmes signal, IdAccountType peerId) {
  String? host;
  int? port;

  if (signal.ipv6.isNotEmpty && signal.ipv6 != '::') {
    host = signal.ipv6;
    port = int.tryParse(signal.ipv6Port);
  }

  if ((host == null || host.isEmpty) && signal.ipv4.isNotEmpty) {
    host = signal.ipv4;
    port = int.tryParse(signal.ipv4Port);
  }

  if (host == null || host.isEmpty || port == null || port <= 0) {
    throw CoreException(
      'Invalid peer signal for $peerId: no valid IP address. '
      'IPv6: ${signal.ipv6}:${signal.ipv6Port}, '
      'IPv4: ${signal.ipv4}:${signal.ipv4Port}',
    );
  }

  return ErmesPeerInfo(
    address: InternetAddress(host),
    port: port,
    id: peerId,
  );
}

/// Address-family context of a Connection toward [peerInfo] (RFC 8.1 KDF
/// context). Both sides dial over the same family, so they agree.
ErmesConnectionContext connectionContextOf(ErmesPeerInfo peerInfo) =>
    ErmesConnectionContext.fromFamily(
      isIpv6: peerInfo.address.type == InternetAddressType.IPv6,
    );

/// Endpoint of each address family advertised by [signal], restricted to
/// the families in [available] (the ones this host has a socket for).
///
/// A family absent from the signal, or without a valid host / port, is left
/// out; the result is empty when no common family exists (RFC section 6.2:
/// a signal carries an IPv4 pair, an IPv6 pair, or both).
Map<ErmesConnectionContext, ErmesPeerInfo> peerInfosFromSignal(
  ISignalErmes signal,
  IdAccountType peerId,
  Iterable<ErmesConnectionContext> available,
) {
  final pairs = {
    ErmesConnectionContext.ipv4: (signal.ipv4, signal.ipv4Port),
    ErmesConnectionContext.ipv6: (signal.ipv6, signal.ipv6Port),
  };
  final infos = <ErmesConnectionContext, ErmesPeerInfo>{};
  for (final context in available) {
    final (host, portText) = pairs[context] ?? ('', '');
    final port = int.tryParse(portText);
    if (host.isEmpty || host == '::' || port == null || port <= 0) {
      continue;
    }
    infos[context] = ErmesPeerInfo(
      address: InternetAddress(host),
      port: port,
      id: peerId,
    );
  }
  return infos;
}
