import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../../ermes_signaling.dart';

/// Concrete implementation of [IErmesSignalingHandler].
///
/// `createSignal` discovers each family's public endpoint via its own STUN
/// handler and advertises an IPv4 pair, an IPv6 pair, or both; the peer's
/// `processSignal` picks an address and runs `handshake`. Full sequence:
/// `docs/flows/signaling_handshake.md`.
@dependencyInjectable
class ErmesSignalingHandler
    with ErmesSignalingConnectionMixin
    implements IErmesSignalingHandler<ShspPeer> {
  /// Creates a handler over the `ipv4` STUN handler and socket, plus the
  /// optional, independent `ipv6` pair (null when the host has no IPv6).
  ErmesSignalingHandler(
    @Subkey('ipv4') this.stunShspHandler,
    @Subkey('ipv4') this.socket,
    this.ermesBookService, {
    @Subkey('ipv6') this.stunShspHandlerIpv6,
    @Subkey('ipv6') this.socketIpv6,
    int? overridePort,
  }) : _overridePort = overridePort;

  factory ErmesSignalingHandler.dependencyInjectionFactory({
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) {
    final stunShspHandler = RegistryManager.instance
        .getInstance<IStunShspHandler>(
          key: key,
          subkey: 'ipv4',
        ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final socket = RegistryManager.instance.getInstance<IShspSocket>(
      key: key,
      subkey: 'ipv4',
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final ermesBookService = RegistryManager.instance
        .getInstance<IErmesBookService<BookData>>(
          key: key,
        ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final stunShspHandlerIpv6 = RegistryManager.instance
        .tryGetInstance<IStunShspHandler>(
          key: key,
          subkey: 'ipv6',
        ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final socketIpv6 = RegistryManager.instance.tryGetInstance<IShspSocket>(
      key: key,
      subkey: 'ipv6',
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final overridePort = RegistryManager.instance.tryGetInstance<int>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesSignalingHandler(
      // GENERATED CODE - DO NOT MODIFY BY HAND
      stunShspHandler, // GENERATED CODE - DO NOT MODIFY BY HAND
      socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      ermesBookService, // GENERATED CODE - DO NOT MODIFY BY HAND
      stunShspHandlerIpv6: stunShspHandlerIpv6,
      socketIpv6: socketIpv6, // GENERATED CODE - DO NOT MODIFY BY HAND
      overridePort: overridePort, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Creates a handler; pass [handlerIpv6] and [shspSocketIpv6] to also run
  /// the independent IPv6 family.
  ErmesSignalingHandler.create(
    IStunShspHandler handler,
    IShspSocket shspSocket,
    IErmesBookService<BookData> bookService, {
    IStunShspHandler? handlerIpv6,
    IShspSocket? shspSocketIpv6,
    int? overridePort,
  }) : this(
         handler,
         shspSocket,
         bookService,
         stunShspHandlerIpv6: handlerIpv6,
         socketIpv6: shspSocketIpv6,
         overridePort: overridePort,
       );

  /// STUN handler of the IPv4 family.
  @protected
  final IStunShspHandler stunShspHandler;

  /// STUN handler of the optional IPv6 family; `null` skips that family.
  @protected
  final IStunShspHandler? stunShspHandlerIpv6;

  /// SHSP socket of the IPv4 family.
  @protected
  @override
  final IShspSocket socket;

  /// SHSP socket of the optional IPv6 family.
  @protected
  @override
  final IShspSocket? socketIpv6;

  /// Contact book service resolving peer information.
  @protected
  final IErmesBookService<BookData> ermesBookService;

  final int? _overridePort; // overrides the discovered public port
  String? _customStunHost; // fresh-socket STUN host
  int? _customStunPort; // fresh-socket STUN port
  /// Sets a custom STUN server for fresh-socket discovery.
  void setCustomStunServer(String host, int port) {
    _customStunHost = host;
    _customStunPort = port;
  }
  /// Discovers each family's public endpoint via STUN and builds a signal
  /// carrying [localIdSignaling].
  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
    String? localIdSignaling,
  ]) async =>
    buildLocalDualSignal(
      await discoverEndpoints(
        ipv4Handler: stunShspHandler,
        ipv6Handler: stunShspHandlerIpv6,
        customStunHost: _customStunHost,
        customStunPort: _customStunPort,
        overridePort: _overridePort,
      ),
      localIdSignaling: localIdSignaling,
      localPublicKey: localPublicKey,
    );

  /// Builds a peer from the signal (preferring IPv6), then handshakes.
  @override
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<ShspPeer> callback,
  ) async {
    final id = ermesBookService.getPeerInfo(from)?.id;
    final peer =
        buildPeerFromSignal(signal, id, socket, socketIpv6: socketIpv6);
    await handshake(ShspInstance.fromPeer(peer), callback, signal, from);
  }
}
