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
