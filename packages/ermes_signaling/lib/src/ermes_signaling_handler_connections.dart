import 'dart:async';

import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_signaling.dart';

/// Connection lifecycle and socket-readiness behaviour for
/// [ErmesSignalingHandler].
///
/// This mixin owns the per-peer SHSP socket map and the pending
/// socket-ready callbacks, exposing the methods that operate purely on
/// that state. The host class supplies the underlying [socket] used when
/// tearing everything down.
mixin ErmesSignalingConnectionMixin {
  /// The shared SHSP socket owned by the host class.
  IShspSocket get socket;

  final Map<IdAccountType, ShspInstance> activeConnections = {};
  final Map<IdAccountType, List<SocketReadyCallback<ShspPeer>>>
      socketReadyCallbacks = {};

  Future<void> handshake(
    ShspInstance instance,
    SocketReadyCallback<ShspPeer> callback,
    ISignalErmes signal,
    IdAccountType from,
  ) async {
    // A new signal for this peer supersedes any prior transport: close the
    // stale instance before replacing it so the old socket is not leaked.
    activeConnections[from]?.close();
    instance.sendHandshake();
    activeConnections[from] = instance;
    callback(
      SocketDto<ShspPeer>(
        socket: instance as ShspPeer,
        connectionId: from,
        remotePeerId: from,
      ),
    );
  }

  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<ShspPeer> callback,
  ) async {
    socketReadyCallbacks.putIfAbsent(from, () => []).add(callback);
    if (activeConnections.containsKey(from)) {
      callback(await getSocket(from));
    }
  }

  Future<bool> isSocketReady(IdAccountType of) async =>
      activeConnections.containsKey(of);

  Future<SocketDto<ShspPeer>> getSocket(IdAccountType of) async {
    final instance = activeConnections[of];
    if (instance == null) {
      throw SignalingException('Socket not ready for peer $of');
    }
    return SocketDto<ShspPeer>(
      socket: instance as ShspPeer,
      connectionId: of,
      remotePeerId: of,
    );
  }

  Future<void> clearConnection(IdAccountType remotePeerId) async {
    activeConnections.remove(remotePeerId);
    socketReadyCallbacks.remove(remotePeerId);
  }

  Future<void> softClearConnection(IdAccountType remotePeerId) async {
    activeConnections[remotePeerId]?.close();
    activeConnections.remove(remotePeerId);
    socketReadyCallbacks.remove(remotePeerId);
  }

  Future<List<IdAccountType>> getAllPeerIds() async =>
      activeConnections.keys.toList();

  Future<void> destroy() async {
    for (final instance in activeConnections.values) {
      instance.close();
    }
    activeConnections.clear();
    socketReadyCallbacks.clear();
    socket.close();
  }

  Future<SocketDto<ShspPeer>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async {
    if (activeConnections.containsKey(peerId)) {
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
