import 'dart:io';

import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_signaling.dart';

const int secondsExpirationDefault = 600; // 10 minutes

/// Concrete implementation of [IErmesSignalingHandler].
///
/// Used by `IErmesSignalingRepository` to create local signals,
/// process remote signals and maintain the per-peer SHSP socket map.
@isSingleton
class ErmesSignalingHandler
    with ErmesSignalingConnectionMixin
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
  @override
  late IShspSocket socket;
  @isInjected
  @protected
  late IErmesBookService<BookData> ermesBookService;

  int? _overridePort;
  String? _customStunHost;
  int? _customStunPort;

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
}
