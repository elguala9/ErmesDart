import 'dart:async';
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

import 'fresh_socket_stun.dart';

/// Multi-strategy STUN discovery:
/// 1. fresh-socket STUN (if a custom STUN host is configured)
/// 2. the shared `stun_shsp` handler (with up to 5 retries)
/// 3. local-hostname fallback (always succeeds, may return 127.0.0.1)
///
/// The returned port honors [overridePort] when provided.
Future<PublicAddress> discoverPublicAddress({
  required IStunShspHandler stunShspHandler,
  required String? customStunHost,
  required int? customStunPort,
  required int? overridePort,
}) async {
  try {
    final fresh = await freshSocketStun(
      customStunHost: customStunHost,
      customStunPort: customStunPort,
    );
    if (fresh != null) {
      return (
        publicIp: fresh.publicIp,
        publicPort: overridePort ?? fresh.publicPort,
      );
    }
  } on Exception {
    // Fresh-socket STUN failed; fall through.
  }

  final fromHandler = await _stunShspWithRetries(stunShspHandler);
  if (fromHandler != null) {
    return fromHandler;
  }

  return _localHostnameFallback(overridePort);
}

Future<PublicAddress?> _stunShspWithRetries(
  IStunShspHandler handler,
) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      final response = await handler.performStunRequest();
      final address = _pickAddress(response);
      if (address != null) {
        return address;
      }
    } on Exception {
      // Request failed; retry below.
    }
    if (attempt < 4) {
      await Future<void>.delayed(
        Duration(milliseconds: 500 * (attempt + 1)),
      );
    }
  }
  return null;
}

/// Picks the endpoint to advertise from a STUN response.
///
/// Since stun 1.6.1 a [StunResponse] carries both families at once, so the
/// family has to be chosen here rather than by the handler. IPv6 wins when it
/// is mapped, matching the previous IPv6-first behaviour; the rendezvous
/// keepalive warms BOTH families, so either endpoint stays live.
PublicAddress? _pickAddress(StunResponse response) {
  const preference = [InternetAddressType.IPv6, InternetAddressType.IPv4];
  for (final type in preference) {
    final ip = response.publicIp(type);
    final port = response.publicPort(type);
    if (ip != null && ip.isNotEmpty && port != null) {
      return (publicIp: ip, publicPort: port);
    }
  }
  return null;
}

Future<PublicAddress> _localHostnameFallback(int? overridePort) async {
  final port = overridePort ?? 9000;
  try {
    final thisHostname = Platform.localHostname;
    final localAddresses = await InternetAddress.lookup(thisHostname);
    final localIp = localAddresses.isNotEmpty
        ? localAddresses.first.address
        : '127.0.0.1';
    return (publicIp: localIp, publicPort: port);
  } on Exception {
    return (publicIp: '127.0.0.1', publicPort: port);
  }
}

/// Returns true when [address] parses as an IPv4 literal.
bool isIpv4(String address) => _typeOf(address) == InternetAddressType.IPv4;

/// Returns true when [address] parses as an IPv6 literal.
bool isIpv6(String address) => _typeOf(address) == InternetAddressType.IPv6;

InternetAddressType? _typeOf(String address) {
  try {
    return InternetAddress(address).type;
  } on Exception {
    return null;
  }
}
