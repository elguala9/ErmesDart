// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:ermes_core/ermes_core.dart' show ErmesReceiveStats;
import 'package:stun_shsp/stun_shsp.dart' show IShspTrafficTap, ShspTrafficTap;

/// Per-endpoint datagram counters seen by the SHSP socket.
class _EndpointCounters {
  int rx = 0;
  int rxDropped = 0;
  int tx = 0;
  int txRejected = 0;
  int rxBytes = 0;
  int txBytes = 0;

  @override
  String toString() =>
      'rx=$rx(${rxBytes}B) rxDropped=$rxDropped '
      'tx=$tx(${txBytes}B) txRejected=$txRejected';
}

/// Records the real remote endpoint of every SHSP datagram.
///
/// Unlike the liveness counters, which only see frames the core dispatched to
/// a peer, this shows where packets actually come from and go to, and how
/// many were dropped because no peer callback matched their source.
class _NatTrafficTap implements IShspTrafficTap {
  final Map<String, _EndpointCounters> _byEndpoint = {};

  _EndpointCounters _at(InternetAddress address, int port) => _byEndpoint
      .putIfAbsent('${address.address}:$port', _EndpointCounters.new);

  @override
  void onReceive(InternetAddress address, int port, int length, bool matched) {
    final c = _at(address, port);
    c.rx += 1;
    c.rxBytes += length;
    if (!matched) {
      c.rxDropped++;
    }
  }

  @override
  void onSend(InternetAddress address, int port, int length, int result) {
    final c = _at(address, port);
    c.tx += 1;
    c.txBytes += length;
    if (result == 0) {
      c.txRejected++;
    }
  }

  /// Prints and clears the counters gathered since the last dump.
  void dump(String tag, String label) {
    if (_byEndpoint.isEmpty) {
      print('[$tag] [TRAFFIC-DIAG] $label: no datagrams');
    }
    for (final e in _byEndpoint.entries) {
      print('[$tag] [TRAFFIC-DIAG] $label: ${e.key} ${e.value}');
    }
    _byEndpoint.clear();
  }
}

final _tap = _NatTrafficTap();
Timer? _periodic;

/// Installs the process-wide traffic tap, clears the receive counters and
/// dumps both every [period], so long payload phases are covered too.
void installNatTrafficDiag(
  String tag, {
  Duration period = const Duration(seconds: 20),
}) {
  ShspTrafficTap.instance = _tap;
  ErmesReceiveStats.active = ErmesReceiveStats();
  _periodic?.cancel();
  _periodic = Timer.periodic(period, (_) => logNatTrafficDiag(tag, 'periodic'));
}

/// Prints per-endpoint SHSP traffic and the core receive counters gathered
/// since the previous call, then resets them.
void logNatTrafficDiag(String tag, String label) {
  if (ShspTrafficTap.instance == null) {
    return;
  }
  _tap.dump(tag, label);
  final stats = ErmesReceiveStats.active;
  if (stats != null) {
    print('[$tag] [RECV-DIAG] $label: $stats');
    stats.reset();
  }
}
