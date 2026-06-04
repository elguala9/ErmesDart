import 'dart:async';
import 'dart:io';

import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_signaling.dart';
import 'stun/stun_discovery.dart';

const int secondsExpirationDefault = 600; // 10 minutes

/// Concrete implementation of [IErmesSignalingHandler].
///
/// Used by `IErmesSignalingRepository` to create local signals,
/// process remote signals and maintain the per-peer SHSP socket map.
@isSingleton
class ErmesSignalingHandler implements IErmesSignalingHandler<ShspPeer> {
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

  int? _overridePort;
  String? _customStunHost;
  int? _customStunPort;

  final Map<IdAccountType, ShspInstance> _activeConnections = {};
  final Map<IdAccountType, List<SocketReadyCallback<ShspPeer>>>
      _socketReadyCallbacks = {};

  /// Set custom STUN server for direct fresh-socket discovery.
  void setCustomStunServer(String host, int port) {
    _customStunHost = host;
    _customStunPort = port;
  }

  @override
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) async {
    final addr = await discoverPublicAddress(
      stunShspHandler: stunShspHandler,
      customStunHost: _customStunHost,
      customStunPort: _customStunPort,
      overridePort: _overridePort,
    );

    final ipv4 = isIpv4(addr.publicIp) ? addr.publicIp : '';
    final ipv4Port = ipv4.isEmpty ? '' : addr.publicPort.toString();
    final ipv6 = isIpv6(addr.publicIp) ? addr.publicIp : '';
    final ipv6Port = ipv6.isEmpty ? '' : addr.publicPort.toString();

    final nowEpoch =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    return SignalErmes(
      ipv4: ipv4,
      ipv4Port: ipv4Port,
      ipv6: ipv6,
      ipv6Port: ipv6Port,
      publicKey: '',
      epochTimestampStartConversation: nowEpoch,
      epochTimestampExpireConversation: nowEpoch + secondsExpirationDefault,
    );
  }

  @override
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<ShspPeer> callback,
  ) async {
    final peerInfo = ermesBookService.getPeerInfo(from);
    final peer = _buildPeer(signal, peerInfo?.id);
    if (peer == null) {
      throw SignalingException('No valid IP address found in signal');
    }
    final instance = ShspInstance.fromPeer(peer);
    await handshake(instance, callback, signal, from);
  }

  ShspPeer? _buildPeer(ISignalErmes signal, IdAccountType? peerId) {
    if (signal.ipv6.isNotEmpty && signal.ipv6Port.isNotEmpty) {
      return ShspPeerFactory.create(
        remotePeer: ErmesPeerInfo(
          address: InternetAddress(signal.ipv6),
          port: int.parse(signal.ipv6Port),
          id: peerId,
        ),
        socket: socket,
      );
    }
    if (signal.ipv4.isNotEmpty && signal.ipv4Port.isNotEmpty) {
      return ShspPeerFactory.create(
        remotePeer: ErmesPeerInfo(
          address: InternetAddress(signal.ipv4),
          port: int.parse(signal.ipv4Port),
          id: peerId,
        ),
        socket: socket,
      );
    }
    return null;
  }

  Future<void> handshake(
    ShspInstance instance,
    SocketReadyCallback<ShspPeer> callback,
    ISignalErmes signal,
    IdAccountType from,
  ) async {
    instance.sendHandshake();
    _activeConnections[from] = instance;
    callback(
      SocketDto<ShspPeer>(
        socket: instance as ShspPeer,
        connectionId: from,
        remotePeerId: from,
      ),
    );
  }

  @override
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<ShspPeer> callback,
  ) async {
    _socketReadyCallbacks.putIfAbsent(from, () => []).add(callback);
    if (_activeConnections.containsKey(from)) {
      callback(await getSocket(from));
    }
  }

  @override
  Future<bool> isSocketReady(IdAccountType of) async =>
      _activeConnections.containsKey(of);

  @override
  Future<SocketDto<ShspPeer>> getSocket(IdAccountType of) async {
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
  Future<void> clearConnection(IdAccountType remotePeerId) async {
    _activeConnections.remove(remotePeerId);
    _socketReadyCallbacks.remove(remotePeerId);
  }

  @override
  Future<void> softClearConnection(IdAccountType remotePeerId) async {
    _activeConnections[remotePeerId]?.close();
    _activeConnections.remove(remotePeerId);
    _socketReadyCallbacks.remove(remotePeerId);
  }

  @override
  Future<List<IdAccountType>> getAllPeerIds() async =>
      _activeConnections.keys.toList();

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
  Future<SocketDto<ShspPeer>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async {
    if (_activeConnections.containsKey(peerId)) {
      return getSocket(peerId);
    }

    final completer = Completer<SocketDto<ShspPeer>>();
    Timer? timeoutTimer;

    await onSocketReady(peerId, (socket) {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete(socket);
      }
    });

    timeoutTimer = Timer(Duration(milliseconds: ms), () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Connection timeout after ${ms}ms'),
        );
      }
    });

    return completer.future;
  }
}
