import 'dart:io';

import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../../ermes_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';

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
@dependencyInjectable
class ErmesSignalingHandler
    with ErmesSignalingConnectionMixin
    implements IErmesSignalingHandler<ShspPeer> {
  /// Creates a fully wired handler with its STUN handler, socket, book
  /// service and an optional port override.
  ///
  /// The STUN handler and socket are resolved under the `ipv4` subkey:
  /// stun_shsp and shsp register one of each per address family, and this
  /// handler drives the IPv4-primary path.
  ErmesSignalingHandler(
    @Subkey('ipv4') this.stunShspHandler,
    @Subkey('ipv4') this.socket,
    this.ermesBookService, {
    int? overridePort,
  }) : _overridePort = overridePort;

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ErmesSignalingHandler.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final stunShspHandler = RegistryManager.instance.getInstance<IStunShspHandler>(key: key, subkey: 'ipv4'); // GENERATED CODE - DO NOT MODIFY BY HAND
    final socket = RegistryManager.instance.getInstance<IShspSocket>(key: key, subkey: 'ipv4'); // GENERATED CODE - DO NOT MODIFY BY HAND
    final ermesBookService = RegistryManager.instance.getInstance<IErmesBookService<BookData>>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final overridePort = RegistryManager.instance.tryGetInstance<int>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesSignalingHandler( // GENERATED CODE - DO NOT MODIFY BY HAND
      stunShspHandler, // GENERATED CODE - DO NOT MODIFY BY HAND
      socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      ermesBookService, // GENERATED CODE - DO NOT MODIFY BY HAND
      overridePort: overridePort, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Creates a fully wired handler with its STUN handler, socket, book
  /// service and an optional port override.
  ErmesSignalingHandler.create(
    IStunShspHandler handler,
    IShspSocket shspSocket,
    IErmesBookService<BookData> bookService, {
    int? overridePort,
  }) : this(handler, shspSocket, bookService, overridePort: overridePort);

  /// STUN/SHSP handler used to discover the local public address.
  @protected
  final IStunShspHandler stunShspHandler;

  /// Shared SHSP socket used to establish per-peer transports.
  @protected
  @override
  final IShspSocket socket;

  /// Contact book service used to resolve peer information.
  @protected
  final IErmesBookService<BookData> ermesBookService;

  /// Optional port that overrides the discovered public port.
  final int? _overridePort;

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
