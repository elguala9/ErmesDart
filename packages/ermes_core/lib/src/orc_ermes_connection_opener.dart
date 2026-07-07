import 'dart:async';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
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

  static const Duration _peerSignalPollInterval = Duration(seconds: 1);
  static const Duration _confirmPollInterval = Duration(milliseconds: 500);

  // How long a fresh dial is watched for a live connection or a superseding
  // (fresher) peer signal. Deliberately short and independent of
  // [connectionTimeoutMs]: this watch runs its FULL budget whenever the dialed
  // peer does not flip `isConnected()` (e.g. right after a reconnect), so a
  // long value would stall every such open. Re-attempts against a stale port
  // are the OUTER rendezvous loop's job (it re-punches each window); the real
  // stale-signal defence is [_isStale] rejecting leftovers up front.
  static const int _redialConfirmMs = 5000;

  // How many declared republish periods a peer signal may be old before it is
  // treated as a leftover from a process that stopped dialing (see [_isStale]).
  static const int _maxSignalAgeFactor = 2;

  Future<ErmesPeer> open(
    IdPeer peer,
    void Function(TypeOfData data, IdPeer from) onData,
    Future<void> Function(IdPeer peer) onPeerDisconnect,
  ) async {
    final ourSignal = await signalingHandler.createSignal(
      peer,
      _localPublicKey(),
    );
    await signalingServer.setSignal(ourSignal, peer);

    var peerSignal = await _waitForPeerSignal(peer, ourSignal);
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
  String? _localPublicKey() => enableEncryption
      ? SingletonDIAccess.get<IKeyExchange>().publicKey
      : null;

  /// Derives the ECDH shared-secret cipher from the peer's public key carried
  /// in [peerSignal] and registers it on the retained per-peer cipher for both
  /// directions. Runs on every (re)dial: a fresher signal means a fresh key is
  /// added while the existing [ErmesPeerCipher] — and its prior keys — is kept.
  void _applySharedSecret(IdPeer peer, ISignalErmes peerSignal) {
    if (!enableEncryption || peerSignal.publicKey.isEmpty) {
      return;
    }
    final keyExchange = SingletonDIAccess.get<IKeyExchange>();
    final cipher = deriveSharedSecretCipher(keyExchange, peerSignal.publicKey);
    final handler = ErmesPeerCipherHandler();
    var peerCipher = handler.get(peer);
    if (peerCipher == null) {
      peerCipher = ErmesPeerCipher();
      handler.set(peer, peerCipher);
    }
    peerCipher
      ..addEncryptCipher(cipher)
      ..addDecryptCipher(cipher);
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
        if (!s.isExpired() &&
            !_isSelfSignal(s, ourSignal) &&
            !_isStale(s) &&
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

  Future<ISignalErmes> _waitForPeerSignal(
    IdPeer peer,
    ISignalErmes ourSignal,
  ) async {
    // Bound the wait by WALL-CLOCK ([connectionTimeoutMs]), not a fixed attempt
    // count: every poll forces a relay round-trip whose latency we do not
    // control, so a slow relay would stretch "N attempts" into many minutes —
    // long enough to blow past the synchronized rendezvous windows the outer
    // loop relies on to make both peers punch together. When no fresh signal
    // appears within the budget we throw so the OUTER rendezvous loop re-paces
    // to the next window instead of blocking here across several of them.
    final sw = Stopwatch()..start();
    final budget = Duration(milliseconds: connectionTimeoutMs);
    while (sw.elapsed < budget) {
      try {
        // Force a relay round-trip on every poll: a cached read can pin us
        // to a stale signal persisted from an earlier session.
        final s = await signalingServer.getSignal(peer, forceRefresh: true);
        // Reject our OWN signal handed back by the relay (no live peer has
        // published yet): dialing it would punch at ourselves and only ever
        // "connect" by NAT hairpin, masking the absent peer. Also reject a
        // STALE signal — a leftover the relay still serves from an earlier
        // process of the same identity — whose port is long dead.
        if (!s.isExpired() && !_isSelfSignal(s, ourSignal) && !_isStale(s)) {
          return s;
        }
      } on Exception {
        // peer hasn't published yet — keep polling
      }
      await Future<void>.delayed(_peerSignalPollInterval);
    }
    throw CoreException(
      'Timeout waiting for peer signal after ${budget.inSeconds}s',
    );
  }

  /// True when [s] is older than [_maxSignalAgeFactor] declared republish
  /// periods. A peer following the handshake republishes its signal on every
  /// dial (each `openConnection` calls `createSignal`), i.e. at least once per
  /// `secondsIntervalOpening` window, so a signal this old belongs to a
  /// process that stopped dialing — typically an earlier run whose NAT mapping
  /// is gone — even though its 10-minute expiry has not elapsed yet. Signals
  /// that declare no period (0, including all pre-period wire formats) keep
  /// the expiry-only behaviour.
  bool _isStale(ISignalErmes s) {
    if (s.secondsIntervalOpening <= 0) {
      return false;
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final age = now - s.epochTimestampStartConversation;
    return age > _maxSignalAgeFactor * s.secondsIntervalOpening;
  }

  /// True when [candidate] advertises the very endpoint we published in
  /// [ours] — same public IP AND port on either family. That can only be our
  /// own signal reflected by the relay; a genuine peer behind the same NAT
  /// still gets a distinct port, so this never rejects a real counterpart.
  bool _isSelfSignal(ISignalErmes candidate, ISignalErmes ours) {
    final sameV4 = candidate.ipv4.isNotEmpty &&
        candidate.ipv4 == ours.ipv4 &&
        candidate.ipv4Port == ours.ipv4Port;
    final sameV6 = candidate.ipv6.isNotEmpty &&
        candidate.ipv6 == ours.ipv6 &&
        candidate.ipv6Port == ours.ipv6Port;
    return sameV4 || sameV6;
  }
}
