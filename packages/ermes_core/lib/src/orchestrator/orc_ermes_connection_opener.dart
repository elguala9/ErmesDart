import 'dart:async';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../peer_connection/ermes_peer.dart';
import '../peer_connection/ermes_peer_factory.dart';
import '../support/exceptions.dart';
import 'orc_peer_info_from_signal.dart';
import 'orc_peer_signal_waiter.dart';
import 'orc_signal_cipher_applier.dart';

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
    IKeyExchange? keyExchange,
    OrcSignalCipherApplier? cipherApplier,
  })  : _keyExchange = keyExchange,
        _cipherApplier = cipherApplier ??
            (keyExchange == null ? null : OrcSignalCipherApplier(keyExchange)) {
    if (enableEncryption && keyExchange == null) {
      throw CoreException(
        'enableEncryption is true but no IKeyExchange was provided',
      );
    }
  }

  final IErmesSignalingServer signalingServer;
  final IErmesSignalingHandler<ShspPeer> signalingHandler;
  final IShspSocket socket;
  final IErmesBookService<BookData> bookService;
  final bool enableEncryption;
  final int connectionTimeoutMs;

  /// This peer's key pair, used to derive per-peer shared secrets.
  ///
  /// Non-null whenever [enableEncryption] is true, enforced by the constructor.
  final IKeyExchange? _keyExchange;

  /// Registers signal-derived shared secrets, retiring superseded ones.
  /// Shared across openers by `OrcErmes` so retirement spans re-dials.
  final OrcSignalCipherApplier? _cipherApplier;

  /// Waits for the peer signal while keeping ours fresh on the relay.
  late final OrcPeerSignalWaiter _signalWaiter =
      OrcPeerSignalWaiter(signalingServer, publishOwnSignal);

  static const Duration _confirmPollInterval = Duration(milliseconds: 500);

  // How long a fresh dial is watched for a live connection or a superseding
  // (fresher) peer signal. Deliberately short and independent of
  // [connectionTimeoutMs]: this watch runs its FULL budget whenever the dialed
  // peer does not flip `isConnected()` (e.g. right after a reconnect), so a
  // long value would stall every such open. Re-attempts against a stale port
  // are the OUTER rendezvous loop's job (it re-punches each window); the real
  // stale-signal defence is [OrcPeerSignalWaiter.isUsable] up front.
  static const int _redialConfirmMs = 5000;

  Future<ErmesPeer> open(
    IdPeer peer,
    void Function(TypeOfData data, IdPeer from) onData,
    Future<void> Function(IdPeer peer) onPeerDisconnect,
  ) async {
    final ourSignal = await publishOwnSignal(peer);

    var peerSignal = await _signalWaiter.wait(peer, ourSignal);
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
          peer, ermesPeer, peerSignal, sw, budget, ourSignal);
        fresher != null;
        fresher = await _awaitConnectionOrFresher(
          peer, ermesPeer, peerSignal, sw, budget, ourSignal)) {
      await ermesPeer.dispose();
      await signalingHandler.softClearConnection(peer);
      peerSignal = fresher;
      ermesPeer = await _dial(peer, peerSignal, onData);
    }

    ermesPeer.addOnDisconnectListener(() => unawaited(onPeerDisconnect(peer)));
    return ermesPeer;
  }

  /// Creates a fresh owner signal advertising our current NAT mapping and
  /// publishes it to the relay, returning it. Called on every dial so the peer
  /// always has a live endpoint to punch toward; also invoked on the
  /// already-connected fast path in `OrcErmes.openConnection` so a re-dial loop
  /// keeps our advertised mapping fresh even when a connection object exists.
  ///
  /// [peer] `null` broadcasts the signal to all peers instead of targeting one.
  Future<ISignalErmes> publishOwnSignal(IdPeer? peer) async {
    final ourSignal = await signalingHandler.createSignal(
      peer,
      _localPublicKey(),
    );
    await signalingServer.setSignal(ourSignal, peer);
    return ourSignal;
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
    _applySharedSecret(peer, peerSignal);
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

  /// Our local ECDH public key to advertise in the outgoing signal, or `null`
  /// when encryption is disabled. Only the public key leaves this process.
  String? _localPublicKey() =>
      enableEncryption ? _keyExchange?.publicKey : null;

  /// Derives the ECDH shared-secret cipher from the peer's public key carried
  /// in [peerSignal] and makes it the cipher toward [peer]. Runs on every
  /// (re)dial; a superseded signal key stops being used for encryption.
  void _applySharedSecret(IdPeer peer, ISignalErmes peerSignal) {
    if (enableEncryption) {
      _cipherApplier?.apply(peer, peerSignal.publicKey);
    }
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
    ISignalErmes ourSignal,
  ) async {
    while (sw.elapsed < budget) {
      if (ermesPeer.isConnected()) {
        return null;
      }
      try {
        final s = await signalingServer.getSignal(peer, forceRefresh: true);
        if (_signalWaiter.isUsable(s, ourSignal) &&
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
}
