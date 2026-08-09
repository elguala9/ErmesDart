import 'dart:async';

import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../../ermes_signaling.dart';

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

  /// Active SHSP instances keyed by the remote peer they connect to.
  final Map<IdAccountType, ShspInstance> activeConnections = {};

  /// Pending socket-ready callbacks queued per remote peer.
  final Map<IdAccountType, List<SocketReadyCallback<ShspPeer>>>
  socketReadyCallbacks = {};

  /// Performs the handshake for a peer, superseding any prior connection,
  /// then notifies the caller with the ready socket.
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

  /// Registers a callback for when a peer's socket becomes ready, invoking it
  /// immediately if the connection already exists.
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<ShspPeer> callback,
  ) async {
    socketReadyCallbacks.putIfAbsent(from, () => []).add(callback);
    if (activeConnections.containsKey(from)) {
      callback(await getSocket(from));
    }
  }

  /// Reports whether an active connection exists for the given peer.
  Future<bool> isSocketReady(IdAccountType of) async =>
      activeConnections.containsKey(of);

  /// Returns the socket for the peer; throws if no connection is ready.
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

  /// Forgets a peer's connection and callbacks without closing the socket.
  Future<void> clearConnection(IdAccountType remotePeerId) async {
    activeConnections.remove(remotePeerId);
    socketReadyCallbacks.remove(remotePeerId);
  }

  /// Closes and forgets a peer's connection along with its callbacks.
  Future<void> softClearConnection(IdAccountType remotePeerId) async {
    activeConnections[remotePeerId]?.close();
    activeConnections.remove(remotePeerId);
    socketReadyCallbacks.remove(remotePeerId);
  }

  /// Returns the IDs of all peers with an active connection.
  Future<List<IdAccountType>> getAllPeerIds() async =>
      activeConnections.keys.toList();

  /// Closes every connection, clears all state and shuts down the socket.
  Future<void> destroy() async {
    for (final instance in activeConnections.values) {
      instance.close();
    }
    activeConnections.clear();
    socketReadyCallbacks.clear();
    socket.close();
  }

  /// Waits up to [ms] milliseconds for a peer's socket to become ready,
  /// completing with an error on timeout.
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
