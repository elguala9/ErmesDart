import 'dart:io';

import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_signaling.dart';

/// Default lifetime, in seconds, of a signaling conversation (10 minutes).
const int secondsExpirationDefault = 600; // 10 minutes

/// Concrete implementation of [IErmesSignalingHandler].
///
/// Used by `IErmesSignalingRepository` to create local signals,
/// process remote signals and maintain the per-peer SHSP socket map.
///
/// Handshake sequence: `createSignal` discovers the public address via STUN
/// and builds a [SignalErmes]; the peer's `processSignal` resolves the sender,
/// selects an address (IPv6 preferred, else IPv4) and runs `handshake` to
/// establish the SHSP socket. Full sequence: `docs/flows/signaling_handshake.md`.
@isSingleton
class ErmesSignalingHandler
    with ErmesSignalingConnectionMixin
    implements IErmesSignalingHandler<ShspPeer> {
  /// Creates a handler whose dependencies are provided later via injection.
  ErmesSignalingHandler();

  /// Creates an empty instance used by the dependency injection framework.
  ErmesSignalingHandler.emptyForDI();

  /// Creates a fully wired handler with its STUN handler, socket, book
  /// service and an optional port override.
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

  /// STUN/SHSP handler used to discover the local public address.
  @isInjected
  @protected
  late IStunShspHandler stunShspHandler;

  /// Shared SHSP socket used to establish per-peer transports.
  @isInjected
  @protected
  @override
  late IShspSocket socket;

  /// Contact book service used to resolve peer information.
  @isInjected
  @protected
  late IErmesBookService<BookData> ermesBookService;

  /// Optional port that overrides the discovered public port.
  int? _overridePort;

  /// Optional custom STUN host used for fresh-socket discovery.
  String? _customStunHost;

  /// Optional custom STUN port used for fresh-socket discovery.
  int? _customStunPort;

  /// Set custom STUN server for direct fresh-socket discovery.
  void setCustomStunServer(String host, int port) {
    _customStunHost = host;
    _customStunPort = port;
  }

  /// Discovers the local public address via STUN and builds a signal
  /// describing the reachable IPv4/IPv6 endpoints and conversation window.
  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
  ]) async {
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
      publicKey: localPublicKey ?? '',
      epochTimestampStartConversation: nowEpoch,
      epochTimestampExpireConversation: nowEpoch + secondsExpirationDefault,
    );
  }

  /// Resolves the sender, builds a peer from the signal (preferring IPv6)
  /// and runs the handshake to establish the SHSP socket.
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

  /// Builds an SHSP peer from the signal, preferring IPv6 over IPv4, or
  /// returns null when no usable address is present.
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
