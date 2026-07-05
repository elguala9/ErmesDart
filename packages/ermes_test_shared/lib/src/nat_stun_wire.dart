// Low-level STUN Binding client used by the NAT diagnostics. stdout is the
// test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// A reflexive (public) IP/port pair reported by a STUN server.
typedef StunAddress = ({String ip, int port});

/// Sends STUN Binding Requests from a single bound UDP socket and returns the
/// reflexive address each server reports. Reusing ONE socket across servers is
/// exactly what lets the caller tell an endpoint-independent (cone) mapping
/// from an endpoint-dependent (symmetric) one.
class StunProbe {
  /// Wraps [_sock] and starts listening for STUN responses on it. A socket
  /// error (e.g. the network briefly going unreachable on a CI runner) is
  /// swallowed so it can never surface as an unhandled async error.
  StunProbe(this._sock) {
    _sub = _sock.listen(_onEvent, onError: (Object _) {});
  }

  final RawDatagramSocket _sock;
  late final StreamSubscription<RawSocketEvent> _sub;
  Completer<StunAddress?>? _pending;

  void _onEvent(RawSocketEvent ev) {
    if (ev != RawSocketEvent.read) {
      return;
    }
    final dg = _sock.receive();
    if (dg == null || dg.data.length < 20) {
      return;
    }
    final parsed = _parseXorMappedAddress(dg.data);
    final pending = _pending;
    if (parsed != null && pending != null && !pending.isCompleted) {
      pending.complete(parsed);
    }
  }

  /// Queries [addr]:[port] and returns its reflexive address, or null on a
  /// 3s timeout. Calls must be serialized (one request in flight at a time).
  Future<StunAddress?> query(InternetAddress addr, int port) {
    final completer = _pending = Completer<StunAddress?>();
    try {
      // send() throws synchronously when the network is unreachable; treat
      // that as "no answer" rather than letting it abort the caller.
      _sock.send(_bindingRequest(), addr, port);
    } on Object {
      return Future<StunAddress?>.value();
    }
    return completer.future
        .timeout(const Duration(seconds: 3), onTimeout: () => null);
  }

  /// Cancels the listener and closes the underlying socket.
  Future<void> close() async {
    await _sub.cancel();
    _sock.close();
  }
}

Uint8List _bindingRequest() {
  final txId = Uint8List(12);
  final rng = Random();
  for (var i = 0; i < 12; i++) {
    txId[i] = rng.nextInt(256);
  }
  return Uint8List(20)
    ..[0] = 0
    ..[1] = 1
    ..[4] = 0x21
    ..[5] = 0x12
    ..[6] = 0xA4
    ..[7] = 0x42
    ..setRange(8, 20, txId);
}

StunAddress? _parseXorMappedAddress(Uint8List data) {
  if (data[0] != 1 || data[1] != 1) {
    return null;
  }
  var off = 20;
  while (off + 4 <= data.length) {
    final t = (data[off] << 8) | data[off + 1];
    final l = (data[off + 2] << 8) | data[off + 3];
    if (t == 0x0020 && l >= 8) {
      final xp = ((data[off + 6] << 8) | data[off + 7]) ^ 0x2112;
      final xi = ((data[off + 8] << 24) |
              (data[off + 9] << 16) |
              (data[off + 10] << 8) |
              data[off + 11]) ^
          0x2112A442;
      final ip = '${(xi >> 24) & 0xFF}.${(xi >> 16) & 0xFF}'
          '.${(xi >> 8) & 0xFF}.${xi & 0xFF}';
      return (ip: ip, port: xp);
    }
    off += 4 + l + (4 - l % 4) % 4;
  }
  return null;
}
