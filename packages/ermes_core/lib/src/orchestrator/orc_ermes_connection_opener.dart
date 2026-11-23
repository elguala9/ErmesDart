import 'dart:async';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show ShspPeer;

import '../peer_connection/ermes_peer.dart';
import '../support/exceptions.dart';
import 'orc_family_sockets.dart';
import 'orc_fresher_signal_watcher.dart';
import 'orc_opener_dialer.dart';
import 'orc_peer_signal_waiter.dart';
import 'orc_signal_cipher_applier.dart';
import 'orc_static_signal_opener.dart';
import 'orc_symmetric_nat_detector.dart';

/// Encapsulates the multi-step handshake performed by
/// `OrcErmes.openConnection`: signal publish, peer-signal polling, dialing
/// and re-dialing when a fresher peer signal supersedes the one in use.
class OrcConnectionOpener {
  OrcConnectionOpener({
    required this.signalingServer,
    required this.signalingHandler,
    required this.sockets,
    required this.bookService,
    required this.enableEncryption,
    required this.connectionTimeoutMs,
    IKeyExchange? keyExchange,
    OrcSignalCipherApplier? cipherApplier,
    IErmesSignalLastSeenStore? lastSeen,
    OrcSymmetricNatDetector? natDetector,
  })  : _keyExchange = keyExchange,
        natDetector = natDetector ?? OrcSymmetricNatDetector(),
        _lastSeen = lastSeen,
        cipherApplier = cipherApplier ??
            (keyExchange == null ? null : OrcSignalCipherApplier(keyExchange)) {
    if (enableEncryption && keyExchange == null) {
      throw CoreException(
        'enableEncryption is true but no IKeyExchange was provided',
      );
    }
  }

  final IErmesSignalingServer signalingServer;
  final IErmesSignalingHandler<ShspPeer> signalingHandler;
  /// SHSP sockets this opener can dial over, one per address family.
  final OrcFamilySockets sockets;
  final IErmesBookService<BookData> bookService;
  final bool enableEncryption;
  final int connectionTimeoutMs;

  /// This peer's key pair; non-null whenever [enableEncryption] is true.
  final IKeyExchange? _keyExchange;

  /// Registers signal-derived shared secrets, retiring superseded ones.
  /// Shared across openers by `OrcErmes` so retirement spans re-dials.
  final OrcSignalCipherApplier? cipherApplier;

  /// Flags peers unreachable behind a symmetric NAT (shared by `OrcErmes`).
  final OrcSymmetricNatDetector natDetector;

  /// Newest accepted peer signal per counterpart, shared across openers.
  final IErmesSignalLastSeenStore? _lastSeen;

  /// Waits for the peer signal while keeping ours fresh on the relay.
  late final OrcPeerSignalWaiter _signalWaiter = OrcPeerSignalWaiter(
      signalingServer, publishOwnSignal, lastSeen: _lastSeen);

  /// Watches each fresh dial for a live connection or a fresher signal.
  late final OrcFresherSignalWatcher _watcher =
      OrcFresherSignalWatcher(signalingServer, _signalWaiter);

  /// Runs the handshake and returns one Connection per address family that
  /// is available on both peers, except the families in [skip] (already
  /// live). A family whose dial fails is dropped without affecting the
  /// others; the call throws only when no family could be established.
  /// A [staticPeerSignal] (RFC 6.2) is dialed directly, without the relay.
  Future<Map<ErmesConnectionContext, ErmesPeer>> open(
    IdPeer peer,
    void Function(TypeOfData data, IdPeer from) onData,
    Future<void> Function(IdPeer peer) onPeerDisconnect, {
    Set<ErmesConnectionContext> skip = const {},
    ISignalErmes? staticPeerSignal,
  }) async {
    natDetector.assertAllowed(peer);
    try {
      if (staticPeerSignal != null) {
        return await openStatic(
            peer, staticPeerSignal, onData, onPeerDisconnect, skip);
      }
      return await _openViaRelay(peer, onData, onPeerDisconnect, skip);
    } on ErmesSymmetricNatException {
      rethrow;
    } on Exception {
      natDetector.record(peer, connected: false);
      rethrow;
    }
  }

  Future<Map<ErmesConnectionContext, ErmesPeer>> _openViaRelay(
    IdPeer peer,
    void Function(TypeOfData data, IdPeer from) onData,
    Future<void> Function(IdPeer peer) onPeerDisconnect,
    Set<ErmesConnectionContext> skip,
  ) async {
    final ourSignal = await publishOwnSignal(peer);

    var peerSignal = await _signalWaiter.wait(peer, ourSignal);
    var dialed = await dialAll(peer, peerSignal, onData, skip, ourSignal);

    // Re-dial when the peer republishes a fresher signal: the mapping we
    // punched toward may be stale (a leftover the relay still serves), so a
    // newer signal means a live mapping to aim at instead of a dead port.
    final sw = Stopwatch()..start();
    final budget = OrcFresherSignalWatcher.budgetFor(connectionTimeoutMs);
    for (var fresher = await _watcher.awaitConnectionOrFresher(
          peer, dialed.values, sw, budget, ourSignal);
        fresher != null;
        fresher = await _watcher.awaitConnectionOrFresher(
          peer, dialed.values, sw, budget, ourSignal)) {
      for (final stale in dialed.values) {
        await stale.dispose();
      }
      await signalingHandler.softClearConnection(peer);
      peerSignal = fresher;
      dialed = await dialAll(peer, peerSignal, onData, skip, ourSignal);
    }

    return settle(peer, dialed, onPeerDisconnect);
  }
  /// Creates a fresh owner signal advertising our current NAT mapping and
  /// publishes it to the relay, returning it. Called on every dial and on the
  /// already-connected fast path in `OrcErmes.openConnection`, so the peer
  /// always has a live endpoint to punch toward. [peer] `null` broadcasts.
  Future<ISignalErmes> publishOwnSignal(IdPeer? peer) async {
    final ourSignal = await signalingHandler.createSignal(
      peer,
      _localPublicKey(),
      await signalingServer.getIdAccount(),
    );
    await signalingServer.setSignal(ourSignal, peer);
    return ourSignal;
  }

  /// Our local ECDH public key to advertise, or `null` without encryption.
  String? _localPublicKey() =>
      enableEncryption ? _keyExchange?.publicKey : null;
}
