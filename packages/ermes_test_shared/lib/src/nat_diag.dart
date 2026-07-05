// NAT-type diagnostics for the NAT-traversal binaries: classifies the runner's
// NAT as cone vs symmetric so a rendezvous failure can be attributed to our
// code vs the network/infra WITHOUT guessing. stdout is the test transport in
// CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:io';

import 'nat_stun_wire.dart';

export 'nat_stun_wire.dart' show StunAddress;

/// A public STUN server (host + port).
typedef _Server = ({String host, int port});

/// Two independent public STUN servers with DISTINCT IPs. Querying both from
/// one socket and comparing the reported external port discriminates an
/// endpoint-independent (cone) mapping from an endpoint-dependent (symmetric).
const List<_Server> _servers = [
  (host: 'stun.l.google.com', port: 19302),
  (host: 'stun.cloudflare.com', port: 3478),
];

/// Probes the NAT from a throwaway socket and prints a single `[NAT-DIAG]`
/// verdict line. Best-effort: never throws, so it cannot fail a scenario.
Future<void> runNatDiagnostics({required String tag}) async {
  RawDatagramSocket? sock;
  try {
    sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final local = '0.0.0.0:${sock.port}';
    final probe = StunProbe(sock);
    final a1 = await _resolve(_servers[0].host);
    final a2 = await _resolve(_servers[1].host);
    final e1 = a1 == null ? null : await probe.query(a1, _servers[0].port);
    final e2 = a2 == null ? null : await probe.query(a2, _servers[1].port);
    final e1b = a1 == null ? null : await probe.query(a1, _servers[0].port);
    await probe.close();
    _printVerdict(tag, local, e1, e2, e1b);
  } on Object catch (e) {
    sock?.close();
    print('[$tag] [NAT-DIAG] failed: $e');
  }
}

/// Discovers this peer's current reflexive address from a throwaway socket, or
/// null if STUN is unreachable. Used to spot mapping churn across punches.
Future<StunAddress?> probeExternalAddress() async {
  RawDatagramSocket? sock;
  try {
    sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final probe = StunProbe(sock);
    final addr = await _resolve(_servers[0].host);
    final ext = addr == null ? null : await probe.query(addr, _servers[0].port);
    await probe.close();
    return ext;
  } on Object {
    sock?.close();
    return null;
  }
}

Future<InternetAddress?> _resolve(String host) async {
  final addrs =
      await InternetAddress.lookup(host, type: InternetAddressType.IPv4);
  return addrs.isEmpty ? null : addrs.first;
}

void _printVerdict(
  String tag,
  String local,
  StunAddress? e1,
  StunAddress? e2,
  StunAddress? e1b,
) {
  final String mapping;
  final String verdict;
  if (e1 == null || e2 == null) {
    mapping = 'unknown';
    verdict = 'unknown (a STUN server was unreachable)';
  } else if (e1.port == e2.port) {
    mapping = 'endpoint-independent';
    verdict = 'cone — hole-punch CAN work, so a re-punch failure is OUR bug';
  } else {
    mapping = 'endpoint-dependent';
    verdict = 'symmetric — hole-punch needs a relay, so this is infra/GitHub';
  }
  final overTime = (e1 == null || e1b == null)
      ? 'unknown'
      : (e1.port == e1b.port ? 'stable' : 'CHANGED');
  print(
    '[$tag] [NAT-DIAG] local=$local ext1=${_fmt(e1)} ext2=${_fmt(e2)} '
    'ext1b=${_fmt(e1b)} MAPPING=$mapping PORT-OVER-TIME=$overTime '
    'VERDICT=$verdict',
  );
}

String _fmt(StunAddress? a) => a == null ? 'n/a' : '${a.ip}:${a.port}';
