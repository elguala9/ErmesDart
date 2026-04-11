import 'dart:async';
import 'dart:io';

import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_signaling.dart';

const int secondsExpirationDefault = 600; // 100 minuti secondi

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

  // Override port for SHSP socket in Docker testing (fallback port if STUN fails)
  int? _overridePort;

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
    // Retry STUN request with exponential backoff
    // If all attempts fail, fall back to localhost with a default port
    dynamic stunResponse;
    int stunAttempts = 0;
    int delayMs = 500;

    while (stunResponse == null && stunAttempts < 10) {
      try {
        stunResponse = await stunShspHandler.performStunRequest();
      } catch (e) {
        stunAttempts++;
        if (stunAttempts < 10) {
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          delayMs = (delayMs * 1.5).toInt();
        }
      }
    }

    // Fallback: if all STUN attempts fail, resolve local hostname to IP for Docker testing
    if (stunResponse == null) {
      try {
        // Resolve this container's hostname to get its IP address
        final thisHostname = Platform.localHostname;
        final localAddresses = await InternetAddress.lookup(thisHostname);
        final localIp = localAddresses.isNotEmpty ? localAddresses.first.address : '127.0.0.1';
        final port = _overridePort ?? 9000;
        stunResponse = _FallbackStunResponse(localIp, port);
        print('[ErmesSignalingHandler] Fallback STUN: $localIp:$port (hostname: $thisHostname, override: $_overridePort)');
      } catch (e) {
        // Ultimate fallback to loopback if hostname resolution fails
        final port = _overridePort ?? 9000;
        stunResponse = _FallbackStunResponse('127.0.0.1', port);
        print('[ErmesSignalingHandler] Fallback STUN (no hostname): 127.0.0.1:$port (error: $e)');
      }
    }

    var ipv4 = '';
    var ipv4Port = '';
    var ipv6 = '';
    var ipv6Port = '';

    // Extract IP version info from response (handles both real StunResponse and fallback)
    final publicIp = (stunResponse as dynamic).publicIp as String;
    final publicPort = (stunResponse as dynamic).publicPort as int;

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
    } catch (_) {
      return false;
    }
  }

  /// Check if address is IPv6
  bool _isIpv6(String address) {
    try {
      final addr = InternetAddress(address);
      return addr.type == InternetAddressType.IPv6;
    } catch (_) {
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
      throw Exception(
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
      throw Exception('Socket not ready for peer $of');
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
      final instance = _activeConnections[remotePeerId]!;
      instance.close();
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
}

/// Fallback STUN response for testing when STUN discovery fails
/// Used when performStunRequest() times out after all retry attempts
class _FallbackStunResponse {
  final String publicIp;
  final int publicPort;

  _FallbackStunResponse(this.publicIp, this.publicPort);
}
