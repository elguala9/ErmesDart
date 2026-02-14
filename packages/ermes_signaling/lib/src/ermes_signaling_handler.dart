import 'dart:async';
import 'dart:io';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_implementations/single_hand_shake_protocol_monorepo.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart' hide StunResponse;
import 'package:stun/stun.dart';

import '../ermes_signaling.dart';


const int SECONDSEXPIRATION_DEFAULT = 600; // 100 minuti secondi

/// Implementazione concreta di IErmesSignalingHandler
/// This class should be used by IErmesSignalingRepository. It handles the creation and processing of signaling messages
@includeInBarrelFile
class ErmesSignalingHandler implements IErmesSignalingHandler<ShspPeer> {
  ErmesSignalingHandler(IStunHandler stunHandler, IShspSocket socket) {
    _stunHandler = stunHandler;
    _socket = socket;
  }

  late IStunHandler _stunHandler;
  late IShspSocket _socket;

  // Map to track active connections
  final Map<IdAccountType, ShspInstance> _activeConnections = {};

  // Map to track callbacks waiting for socket ready events
  final Map<IdAccountType, List<SocketReadyCallback<ShspPeer>>>
      _socketReadyCallbacks = {};

  @override
  Future<void> clearConnection(IdAccountType remotePeerId) async {
    _activeConnections.remove(remotePeerId);
    _socketReadyCallbacks.remove(remotePeerId);
  }

  @override
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) async {
    final StunResponse response = await _stunHandler.performStunRequest();
    String ipv4 = '';
    String ipv4Port = '';
    String ipv6 = '';
    String ipv6Port = '';
    if(response.ipVersion == IpVersion.v4)
      ipv4 = response.publicIp;
      ipv4Port = response.publicPort.toString(); 
    if(response.ipVersion == IpVersion.v6)
      ipv6 = response.publicIp;
      ipv6Port = response.publicPort.toString(); 

    return SignalErmes(
      ipv4Port: ipv4Port,
      ipv4: ipv4,
      ipv6Port: ipv6Port,
      ipv6: ipv6,
      publicKey: '',
      epochTimestampStartConversation: DateTime.now().toUtc().millisecondsSinceEpoch~/1000,
      epochTimestampExpireConversation: DateTime.now().toUtc().millisecondsSinceEpoch~/1000 + SECONDSEXPIRATION_DEFAULT, 
    );
  }

  @override
  Future<void> destroy() async {
    // Close all active connections
    for (final instance in _activeConnections.values) {
      try {
        // TODO: Verify the correct method name for closing a ShspInstance
        // await instance.close();
      } catch (e) {
        // Log but continue
      }
    }

    _activeConnections.clear();
    _socketReadyCallbacks.clear();

    // TODO: Verify the correct method for closing the socket
    // await _socket.close();
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
  Future<void> processSignal(ISignalErmes signal, IdAccountType from, SocketReadyCallback<ShspPeer> callback) 
    async {
    ShspPeer? peer;
    if(signal.ipv6 != '' && signal.ipv6Port != '')
      // connect using IPv6
      peer = ShspPeerFactory.create(
        remotePeer: PeerInfo(address: InternetAddress(signal.ipv6), 
                              port: int.parse(signal.ipv6Port)), 
                              socket: _socket
        );

    if(signal.ipv4 != '' && signal.ipv4Port != '' && peer == null)
      // connect using IPv4
      peer = ShspPeerFactory.create(
        remotePeer: PeerInfo(address: InternetAddress(signal.ipv4), 
                              port: int.parse(signal.ipv4Port)), 
                              socket: _socket
        );
  
    if(peer == null)
      throw Exception('No valid IP address found in signal');

    final ShspInstance instance = ShspInstance.fromPeer(peer);

    // Perform handshake with the peer
    await handshake(instance, callback, signal, from);
  }

  Future<void> handshake(ShspInstance instance,
      SocketReadyCallback<ShspPeer> callback,
      ISignalErmes signal,
      IdAccountType from) async {
    try {
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
    } catch (e) {
      throw Exception('Handshake failed with peer $from: $e');
    }
  }

  @override
  Future<bool> isSocketReady(IdAccountType of) async {
    return _activeConnections.containsKey(of);
  }

  @override
  Future<SocketDto<ShspPeer>> getSocket(IdAccountType of) async {
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
  Future<void> softClearConnection(IdAccountType remotePeerId) async {
    final instance = _activeConnections[remotePeerId];

    if (instance != null) {
      try {
        // TODO: Verify the correct method name for closing a ShspInstance
        // await instance.close();
      } catch (e) {
        // Log error but continue
      }
    }

    _activeConnections.remove(remotePeerId);
    _socketReadyCallbacks.remove(remotePeerId);
  }

  @override
  Future<List<IdAccountType>> getAllPeerIds() async {
    return _activeConnections.keys.toList();
  }

  @override
  Future<SocketDto<ShspPeer>> waitForConnect(IdAccountType peerId, int ms) async {
    // Check if already connected
    if (_activeConnections.containsKey(peerId)) {
      return await getSocket(peerId);
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
