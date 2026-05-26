import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_signaling.dart';

const int secondsExpirationDefault = 600; // 100 minuti secondi

/// Normalized public address extracted from any STUN discovery
/// path (fresh-socket, stun_shsp handler, or hostname fallback).
typedef _PublicAddress = ({String publicIp, int publicPort});

/// Implementazione concreta di IErmesSignalingHandler.
///
/// This class should be used by IErmesSignalingRepository.
/// It handles the creation and processing of signaling
/// messages.
@isSingleton
class ErmesSignalingHandler
    implements IErmesSignalingHandler<ShspPeer> {
  ErmesSignalingHandler();

  ErmesSignalingHandler.emptyForDI();

  ErmesSignalingHandler.create(
    IStunShspHandler handler,
    IShspSocket shspSocket,
    IErmesBookService<BookData> bookService, {
    int? overridePort,
  }) {
    stunShspHandler = handler;
    socket = shspSocket;
    ermesBookService = bookService;
    _overridePort = overridePort;
  }
  @isInjected
  @protected
  late IStunShspHandler stunShspHandler;
  @isInjected
  @protected
  late IShspSocket socket;
  @isInjected
  @protected
  late IErmesBookService<BookData> ermesBookService;

  // Override port for SHSP socket in Docker testing
  // (fallback port if STUN fails)
  int? _overridePort;

  // Custom STUN server for fresh-socket STUN workaround
  String? _customStunHost;
  int? _customStunPort;

  /// Set custom STUN server for direct fresh-socket discovery.
  void setCustomStunServer(String host, int port) {
    _customStunHost = host;
    _customStunPort = port;
  }

  // Map to track active connections
  final Map<IdAccountType, ShspInstance> _activeConnections =
      {};

  // Map to track callbacks waiting for socket ready events
  final Map<IdAccountType, List<SocketReadyCallback<ShspPeer>>>
      _socketReadyCallbacks = {};

  @override
  Future<void> clearConnection(
    IdAccountType remotePeerId,
  ) async {
    _activeConnections.remove(remotePeerId);
    _socketReadyCallbacks.remove(remotePeerId);
  }

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
  ]) async {
    // STUN discovery: use a fresh temporary socket to discover
    // our public IP. We use the discovered IP combined with the
    // SHSP override port, since MASQUERADE preserves source
    // ports when possible.
    _PublicAddress? stunResponse;

    // Try fresh-socket STUN first (lightweight, avoids
    // dual-stack issues)
    try {
      final result = await _freshSocketStun();
      if (result != null) {
        final port = _overridePort ?? result.publicPort;
        stunResponse =
            (publicIp: result.publicIp, publicPort: port);
      }
    } on Exception {
      // Fresh-socket STUN failed; fall through to next strategy.
    }

    // Fallback: built-in stun_shsp handler
    if (stunResponse == null) {
      var stunAttempts = 0;
      while (stunResponse == null && stunAttempts < 5) {
        try {
          final r = await stunShspHandler.performStunRequest();
          stunResponse =
              (publicIp: r.publicIp, publicPort: r.publicPort);
        } on Exception {
          stunAttempts++;
          if (stunAttempts < 5) {
            await Future<void>.delayed(
              Duration(milliseconds: 500 * stunAttempts),
            );
          }
        }
      }
    }

    // Fallback: local hostname resolution
    if (stunResponse == null) {
      try {
        final thisHostname = Platform.localHostname;
        final localAddresses =
            await InternetAddress.lookup(thisHostname);
        final localIp = localAddresses.isNotEmpty
            ? localAddresses.first.address
            : '127.0.0.1';
        final port = _overridePort ?? 9000;
        stunResponse = (publicIp: localIp, publicPort: port);
      } on Exception {
        final port = _overridePort ?? 9000;
        stunResponse =
            (publicIp: '127.0.0.1', publicPort: port);
      }
    }

    var ipv4 = '';
    var ipv4Port = '';
    var ipv6 = '';
    var ipv6Port = '';

    final publicIp = stunResponse.publicIp;
    final publicPort = stunResponse.publicPort;

    if (_isIpv4(publicIp)) {
      ipv4 = publicIp;
      ipv4Port = publicPort.toString();
    } else if (_isIpv6(publicIp)) {
      ipv6 = publicIp;
      ipv6Port = publicPort.toString();
    }

    final nowEpoch =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/
            1000;

    return SignalErmes(
      ipv4Port: ipv4Port,
      ipv4: ipv4,
      ipv6Port: ipv6Port,
      ipv6: ipv6,
      publicKey: '',
      epochTimestampStartConversation: nowEpoch,
      epochTimestampExpireConversation:
          nowEpoch + secondsExpirationDefault,
    );
  }

  /// Check if address is IPv4
  bool _isIpv4(String address) {
    try {
      final addr = InternetAddress(address);
      return addr.type == InternetAddressType.IPv4;
    } on Exception {
      return false;
    }
  }

  /// Check if address is IPv6
  bool _isIpv6(String address) {
    try {
      final addr = InternetAddress(address);
      return addr.type == InternetAddressType.IPv6;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> destroy() async {
    for (final instance in _activeConnections.values) {
      instance.close();
    }
    _activeConnections.clear();
    _socketReadyCallbacks.clear();
    socket.close();
  }

  @override
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<ShspPeer> callback,
  ) async {
    // Add callback to list
    if (!_socketReadyCallbacks.containsKey(from)) {
      _socketReadyCallbacks[from] = [];
    }
    _socketReadyCallbacks[from]!.add(callback);

    // If socket is already ready, invoke immediately
    if (_activeConnections.containsKey(from)) {
      final socketDto = await getSocket(from);
      callback(socketDto);
    }
  }

  @override
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<ShspPeer> callback,
  ) async {
    // Retrieve peer info from book service
    final peerInfo = ermesBookService.getPeerInfo(from);

    ShspPeer? peer;
    if (signal.ipv6 != '' && signal.ipv6Port != '') {
      // connect using IPv6
      peer = ShspPeerFactory.create(
        remotePeer: ErmesPeerInfo(
          address: InternetAddress(signal.ipv6),
          port: int.parse(signal.ipv6Port),
          id: peerInfo?.id,
        ),
        socket: socket,
      );
    }

    if (signal.ipv4 != '' &&
        signal.ipv4Port != '' &&
        peer == null) {
      // connect using IPv4
      peer = ShspPeerFactory.create(
        remotePeer: ErmesPeerInfo(
          address: InternetAddress(signal.ipv4),
          port: int.parse(signal.ipv4Port),
          id: peerInfo?.id,
        ),
        socket: socket,
      );
    }

    if (peer == null) {
      throw SignalingException(
        'No valid IP address found in signal',
      );
    }

    final instance = ShspInstance.fromPeer(peer);

    // Perform handshake with the peer
    await handshake(instance, callback, signal, from);
  }

  Future<void> handshake(
    ShspInstance instance,
    SocketReadyCallback<ShspPeer> callback,
    ISignalErmes signal,
    IdAccountType from,
  ) async {
    // Send handshake to the peer
    instance.sendHandshake();

    // Store the active connection
    _activeConnections[from] = instance;

    // Create socket DTO with the ShspInstance peer
    final socketDto = SocketDto<ShspPeer>(
      socket: instance as ShspPeer,
      connectionId: from,
      remotePeerId: from,
    );

    // Notify callback that socket is ready
    callback(socketDto);
  }

  @override
  Future<bool> isSocketReady(
    IdAccountType of,
  ) async =>
      _activeConnections.containsKey(of);

  @override
  Future<SocketDto<ShspPeer>> getSocket(
    IdAccountType of,
  ) async {
    final instance = _activeConnections[of];

    if (instance == null) {
      throw SignalingException('Socket not ready for peer $of');
    }

    return SocketDto<ShspPeer>(
      socket: instance as ShspPeer,
      connectionId: of,
      remotePeerId: of,
    );
  }

  @override
  Future<void> softClearConnection(
    IdAccountType remotePeerId,
  ) async {
    if (_activeConnections.containsKey(remotePeerId)) {
      _activeConnections[remotePeerId]!.close();
    }

    _activeConnections.remove(remotePeerId);
    _socketReadyCallbacks.remove(remotePeerId);
  }

  @override
  Future<List<IdAccountType>> getAllPeerIds() async =>
      _activeConnections.keys.toList();

  @override
  Future<SocketDto<ShspPeer>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async {
    // Check if already connected
    if (_activeConnections.containsKey(peerId)) {
      return getSocket(peerId);
    }

    final completer = Completer<SocketDto<ShspPeer>>();
    Timer? timeoutTimer;

    void onReady(SocketDto<ShspPeer> socket) {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete(socket);
      }
    }

    await onSocketReady(peerId, onReady);

    timeoutTimer = Timer(
      Duration(milliseconds: ms),
      () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException(
              'Connection timeout after ${ms}ms',
            ),
          );
        }
      },
    );

    return completer.future;
  }

  /// Lightweight STUN Binding Request via a fresh temporary UDP
  /// socket. Returns the NAT-mapped public IP and port.
  Future<_FallbackStunResponse?> _freshSocketStun() async {
    final stunAddr = _customStunHost;
    final stunPort = _customStunPort;
    if (stunAddr == null || stunPort == null) {
      return null;
    }

    final addrs = await InternetAddress.lookup(
      stunAddr,
      type: InternetAddressType.IPv4,
    );
    if (addrs.isEmpty) {
      return null;
    }

    RawDatagramSocket? sock;
    try {
      sock = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      final txId = Uint8List(12);
      final rng = Random();
      for (var i = 0; i < 12; i++) {
        txId[i] = rng.nextInt(256);
      }
      final req = Uint8List(20)
        ..[0] = 0
        ..[1] = 1 // Binding Request
        ..[4] = 0x21
        ..[5] = 0x12
        ..[6] = 0xA4
        ..[7] = 0x42
        ..setRange(8, 20, txId);

      sock.send(req, addrs.first, stunPort);

      final c = Completer<_FallbackStunResponse?>();
      StreamSubscription<RawSocketEvent>? sub;
      sub = sock.listen((ev) {
        if (ev != RawSocketEvent.read) {
          return;
        }
        final dg = sock!.receive();
        if (dg == null || dg.data.length < 20) {
          return;
        }
        if (dg.data[0] != 1 || dg.data[1] != 1) {
          return; // not Binding Response
        }
        var off = 20;
        while (off + 4 <= dg.data.length) {
          final t = (dg.data[off] << 8) | dg.data[off + 1];
          final l =
              (dg.data[off + 2] << 8) | dg.data[off + 3];
          if (t == 0x0020 && l >= 8) {
            final xp =
                ((dg.data[off + 6] << 8) | dg.data[off + 7]) ^
                    0x2112;
            final xi = ((dg.data[off + 8] << 24) |
                    (dg.data[off + 9] << 16) |
                    (dg.data[off + 10] << 8) |
                    dg.data[off + 11]) ^
                0x2112A442;
            final ip =
                '${(xi >> 24) & 0xFF}.${(xi >> 16) & 0xFF}'
                '.${(xi >> 8) & 0xFF}.${xi & 0xFF}';
            if (!c.isCompleted) {
              sub?.cancel();
              c.complete(_FallbackStunResponse(ip, xp));
            }
            return;
          }
          off += 4 + l + (4 - l % 4) % 4;
        }
      });
      final r = await c.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          sub?.cancel();
          return null;
        },
      );
      sock.close();
      return r;
    } on Exception {
      sock?.close();
      return null;
    }
  }
}

/// Fallback STUN response for testing when STUN discovery fails
/// Used when performStunRequest() times out after all retry
/// attempts
class _FallbackStunResponse {

  _FallbackStunResponse(this.publicIp, this.publicPort);
  final String publicIp;
  final int publicPort;
}
