import 'dart:async';
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

import 'fresh_socket_stun.dart';
import 'stun_discovery.dart';


/// Number of STUN attempts for the primary (IPv4) family.
const int primaryStunAttempts = 5;

/// Number of STUN attempts for the optional (IPv6) family: a host without
/// IPv6 must not stall the signal, so this family gives up quickly.
const int secondaryStunAttempts = 2;

/// Asks [handler] for the public endpoint of exactly one address [family].
///
/// Returns `null` when the family is not mapped after [attempts] tries: a
/// missing family is skipped by the caller, never an error (RFC section 5).
Future<PublicAddress?> discoverFamilyAddress(
  IStunShspHandler handler,
  InternetAddressType family, {
  int attempts = primaryStunAttempts,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    try {
      final response = await handler.performStunRequest();
      final ip = response.publicIp(family);
      final port = response.publicPort(family);
      if (ip != null && ip.isNotEmpty && port != null) {
        return (publicIp: ip, publicPort: port);
      }
    } on Exception {
      // Request failed; retry below.
    }
    if (attempt < attempts - 1) {
      await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
  }
  return null;
}

/// Discovers the independent IPv4 and IPv6 endpoints in parallel, each over
/// its own STUN handler. Families that are not mapped are left out.
Future<List<PublicAddress>> discoverDualAddresses({
  required IStunShspHandler ipv4Handler,
  required IStunShspHandler ipv6Handler,
}) async {
  final found = await Future.wait([
    discoverFamilyAddress(ipv4Handler, InternetAddressType.IPv4),
    discoverFamilyAddress(
      ipv6Handler,
      InternetAddressType.IPv6,
      attempts: secondaryStunAttempts,
    ),
  ]);
  return [
    for (final address in found)
      if (address != null) address,
  ];
}

/// Public endpoints to advertise: one per address family when [ipv6Handler]
/// is configured (each family over its own STUN handler), else the single
/// legacy endpoint. A custom STUN host forces the legacy path.
Future<List<PublicAddress>> discoverEndpoints({
  required IStunShspHandler ipv4Handler,
  required IStunShspHandler? ipv6Handler,
  required String? customStunHost,
  required int? customStunPort,
  required int? overridePort,
}) async {
  if (ipv6Handler != null && customStunHost == null) {
    final dual = await discoverDualAddresses(
      ipv4Handler: ipv4Handler,
      ipv6Handler: ipv6Handler,
    );
    if (dual.isNotEmpty) {
      return dual;
    }
  }
  return [
    await discoverPublicAddress(
      stunShspHandler: ipv4Handler,
      customStunHost: customStunHost,
      customStunPort: customStunPort,
      overridePort: overridePort,
    ),
  ];
}
