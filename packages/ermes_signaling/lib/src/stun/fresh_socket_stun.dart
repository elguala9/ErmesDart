import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Public IP/port pair returned by STUN discovery.
typedef PublicAddress = ({String publicIp, int publicPort});

/// Lightweight STUN Binding Request via a fresh temporary UDP socket.
///
/// Used as the primary discovery path because it avoids the dual-stack
/// quirks of the shared `stun_shsp` handler. Returns `null` when no
/// custom STUN server is configured, when DNS resolution fails, or when
/// the request times out.
Future<PublicAddress?> freshSocketStun({
  required String? customStunHost,
  required int? customStunPort,
}) async {
  if (customStunHost == null || customStunPort == null) {
    return null;
  }

  final addrs = await InternetAddress.lookup(
    customStunHost,
    type: InternetAddressType.IPv4,
  );
  if (addrs.isEmpty) {
    return null;
  }

  RawDatagramSocket? sock;
  try {
    sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final req = _buildBindingRequest();
    sock.send(req, addrs.first, customStunPort);

    final completer = Completer<PublicAddress?>();
    StreamSubscription<RawSocketEvent>? sub;
    sub = sock.listen((ev) {
      if (ev != RawSocketEvent.read) {
        return;
      }
      final dg = sock!.receive();
      if (dg == null || dg.data.length < 20) {
        return;
      }
      final parsed = _parseXorMappedAddress(dg.data);
      if (parsed != null && !completer.isCompleted) {
        sub?.cancel();
        completer.complete(parsed);
      }
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        sub?.cancel();
        return null;
      },
    );
    sock.close();
    return result;
  } on Exception {
    sock?.close();
    return null;
  }
}

Uint8List _buildBindingRequest() {
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

PublicAddress? _parseXorMappedAddress(Uint8List data) {
  if (data[0] != 1 || data[1] != 1) {
    return null;
  }
  var off = 20;
  while (off + 4 <= data.length) {
    final t = (data[off] << 8) | data[off + 1];
    final l = (data[off + 2] << 8) | data[off + 3];
    if (t == 0x0020 && l >= 8) {
      final xp = ((data[off + 6] << 8) | data[off + 7]) ^ 0x2112;
      final xi =
          ((data[off + 8] << 24) |
              (data[off + 9] << 16) |
              (data[off + 10] << 8) |
              data[off + 11]) ^
          0x2112A442;
      final ip =
          '${(xi >> 24) & 0xFF}.${(xi >> 16) & 0xFF}'
          '.${(xi >> 8) & 0xFF}.${xi & 0xFF}';
      return (publicIp: ip, publicPort: xp);
    }
    off += 4 + l + (4 - l % 4) % 4;
  }
  return null;
}
