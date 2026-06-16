import 'dart:async';

import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_peer.dart';
import 'exceptions.dart';
import 'factories/ermes_peer_factory.dart';
import 'orc_peer_info_from_signal.dart';

/// Encapsulates the multi-step handshake performed by
/// `OrcErmes.openConnection`: signal publish, peer-signal polling, dialing
/// and re-dialing when a fresher peer signal supersedes the one in use.
class OrcConnectionOpener {
  OrcConnectionOpener({
    required this.signalingServer,
    required this.signalingHandler,
    required this.socket,
    required this.bookService,
    required this.enableEncryption,
    required this.connectionTimeoutMs,
  });

  final IErmesSignalingServer signalingServer;
  final IErmesSignalingHandler<ShspPeer> signalingHandler;
  final IShspSocket socket;
  final IErmesBookService<BookData> bookService;
  final bool enableEncryption;
  final int connectionTimeoutMs;

  static const int _maxSignalAttempts = 60;
  static const Duration _confirmPollInterval = Duration(milliseconds: 500);

  // How long a fresh dial is watched for a live connection or a superseding
  // (fresher) peer signal. Short and independent of [connectionTimeoutMs]:
  // with synchronized rendezvous windows the peer republishes within seconds.
  static const int _redialConfirmMs = 5000;

  Future<ErmesPeer> open(
    IdPeer peer,
    void Function(TypeOfData data, IdPeer from) onData,
    Future<void> Function(IdPeer peer) onPeerDisconnect,
  ) async {
    final ourSignal = await signalingHandler.createSignal(peer);
    await signalingServer.setSignal(ourSignal, peer);

    var peerSignal = await _waitForPeerSignal(peer);
    var ermesPeer = await _dial(peer, peerSignal, onData);

    // Re-dial when the peer republishes a fresher signal: the mapping we
    // punched toward may be stale (a leftover the relay still serves), so a
    // newer signal means a live mapping to aim at instead of a dead port.
    final sw = Stopwatch()..start();
    final budget = Duration(
      milliseconds: connectionTimeoutMs < _redialConfirmMs
          ? connectionTimeoutMs
          : _redialConfirmMs,
    );
    for (var fresher = await _awaitConnectionOrFresher(
          peer, ermesPeer, peerSignal, sw, budget);
        fresher != null;
        fresher = await _awaitConnectionOrFresher(
          peer, ermesPeer, peerSignal, sw, budget)) {
      await ermesPeer.dispose();
      await signalingHandler.softClearConnection(peer);
      peerSignal = fresher;
      ermesPeer = await _dial(peer, peerSignal, onData);
    }

    ermesPeer.addOnDisconnectListener(() => unawaited(onPeerDisconnect(peer)));
    return ermesPeer;
  }

  Future<ErmesPeer> _dial(
    IdPeer peer,
    ISignalErmes peerSignal,
    void Function(TypeOfData data, IdPeer from) onData,
  ) async {
    bookService.setAccount(
      AccountInfo<BookData>(
        account: peer,
        peerInfo: peerInfoFromSignal(peerSignal, peer),
      ),
    );
    final ermesPeer = ErmesPeerFactory.create(
      ErmesPeerConfig(
        remotePeerId: peer,
        socket: socket,
        signalingHandler: signalingHandler,
        ermesBookService: bookService,
        idHandler: IdHandlerServiceFactory.createDefault(),
        timeoutMs: connectionTimeoutMs,
        enableEncryption: enableEncryption,
      ),
    )..addOnMessageListener((data) => onData(data, peer));
    await ermesPeer.initialize(initiateKeyExchange: enableEncryption);
    return ermesPeer;
  }

  /// Returns `null` once [ermesPeer] connects or the budget runs out (caller
  /// keeps the optimistic peer), or a peer signal newer than [current] when
  /// one appears so the caller can re-dial toward the live mapping.
  Future<ISignalErmes?> _awaitConnectionOrFresher(
    IdPeer peer,
    ErmesPeer ermesPeer,
    ISignalErmes current,
    Stopwatch sw,
    Duration budget,
  ) async {
    while (sw.elapsed < budget) {
      if (ermesPeer.isConnected()) {
        return null;
      }
      try {
        final s = await signalingServer.getSignal(peer, forceRefresh: true);
        if (!s.isExpired() &&
            s.epochTimestampStartConversation >
                current.epochTimestampStartConversation) {
          return s;
        }
      } on Exception {
        // transient relay read failure — keep polling
      }
      await Future<void>.delayed(_confirmPollInterval);
    }
    return null;
  }

  Future<ISignalErmes> _waitForPeerSignal(IdPeer peer) async {
    for (var attempt = 0; attempt < _maxSignalAttempts; attempt++) {
      try {
        // Force a relay round-trip on every poll: a cached read can pin us
        // to a stale signal persisted from an earlier session.
        final s = await signalingServer.getSignal(peer, forceRefresh: true);
        if (!s.isExpired()) {
          return s;
        }
      } on Exception {
        // peer hasn't published yet — keep polling
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw CoreException(
      'Timeout waiting for peer signal after $_maxSignalAttempts attempts',
    );
  }
}
