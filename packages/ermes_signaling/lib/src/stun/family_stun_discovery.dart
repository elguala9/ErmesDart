import 'dart:async';
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

import 'fresh_socket_stun.dart';
import 'stun_discovery.dart';


/// Number of STUN attempts for the primary (IPv4) family.
const int primaryStunAttempts = 5;

/// Number of STUN attempts for the optional (IPv6) family: a host without
/// IPv6 must not stall the signal, so this family gives up quickly.
const int secondaryStunAttempts = 1;

/// Overall budget of the optional (IPv6) discovery. On a host without IPv6
/// connectivity the STUN request only ends on its own (long) timeout, which
/// would delay every signal; past this budget the family is skipped.
const Duration secondaryStunBudget = Duration(milliseconds: 1500);

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

/// Discovers the optional IPv6 endpoint over [handler] within
/// [secondaryStunBudget]; `null` when it is not mapped in time.
Future<PublicAddress?> discoverSecondaryIpv6(IStunShspHandler handler) =>
    discoverFamilyAddress(
      handler,
      InternetAddressType.IPv6,
      attempts: secondaryStunAttempts,
    ).timeout(secondaryStunBudget, onTimeout: () => null);

/// Discovers the independent IPv4 and IPv6 endpoints in parallel, each over
/// its own STUN handler. Families that are not mapped are left out.
Future<List<PublicAddress>> discoverDualAddresses({
  required IStunShspHandler ipv4Handler,
  required IStunShspHandler ipv6Handler,
}) async {
  final found = await Future.wait([
    discoverFamilyAddress(ipv4Handler, InternetAddressType.IPv4),
    discoverSecondaryIpv6(ipv6Handler),
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
