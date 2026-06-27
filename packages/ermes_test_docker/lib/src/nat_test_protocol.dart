/// Shared parameters for the two-peer NAT traversal test.
///
/// Both [nat_peer_a] and [nat_peer_b] import these so the initiator and
/// the responder agree on how many messages to expect and how long to
/// wait before declaring failure. Every bound is deliberately strict:
/// the test must fail loudly the moment reality diverges from this
/// contract.
class NatTestProtocol {
  const NatTestProtocol._();

  /// Number of `testData` messages the initiator sends and the responder
  /// must acknowledge. The responder treats a different count as failure.
  static const int messageCount = 5;

  /// Wall-clock budget for the rendezvous (repeated `openConnection`
  /// attempts) before giving up. Kept below the CI job timeout so the
  /// process exits with its own diagnostics rather than being killed.
  static const Duration rendezvousBudget = Duration(minutes: 6);

  /// Legacy fixed delay between rendezvous attempts. Superseded by the
  /// interval-window pacing ([windowPeriodSeconds] / [windowOpenSeconds]),
  /// which both peers derive from the signal so their dials stay aligned.
  /// Retained for reference / fallback experiments.
  static const Duration rendezvousRetryInterval = Duration(seconds: 20);

  /// Fallback rendezvous-window period, in seconds: how often a synchronized
  /// dial window opens. Mirrors `SignalErmes.secondsIntervalOpening`, so the
  /// value used before the first signal is published matches the value the
  /// signal itself carries. Both peers align their dials to absolute
  /// wall-clock periods (`epoch % windowPeriodSeconds`), so they attempt in
  /// the same slot without any manual start-time coordination.
  static const int windowPeriodSeconds = 60;

  /// Fallback rendezvous-window length, in seconds: how long each window
  /// stays open for a dial. Mirrors `SignalErmes.secondsIntervalWindow`.
  static const int windowOpenSeconds = 10;

  /// Grace period the initiator waits before its first attempt so the
  /// responder has a chance to publish its signal first.
  static const Duration initiatorStartupGrace = Duration(seconds: 15);

  /// How long the initiator waits for the responder's `ready` handshake
  /// before sending the batch. Generous because the responder may finish
  /// its rendezvous well after the initiator (relay skew between the two
  /// CI jobs); sending before the responder's side is up loses the batch.
  static const Duration readyTimeout = Duration(minutes: 5);

  /// How often the responder re-sends `ready` until the first `testData`
  /// arrives, so a single lost `ready` does not stall the exchange.
  static const Duration readyResendInterval = Duration(seconds: 3);

  /// How long the initiator waits for all ACKs after sending the batch.
  static const Duration ackTimeout = Duration(seconds: 90);

  /// How long the responder waits for the full sequence + endOfTests once
  /// its connection is established.
  static const Duration responderExchangeTimeout = Duration(minutes: 3);

  // --- network-change scenario -----------------------------------------------
  // These govern the sustained-exchange variant selected with the environment
  // variable `NAT_SCENARIO=network-change`. Instead of a one-shot burst the
  // peers keep exchanging a `testData`/`ack` heartbeat across a mid-run
  // network change so the swap has a live connection to break and the core's
  // auto-reconnect (`handlePeerDisconnect` -> `openConnection`) is observed.

  /// Value of `NAT_SCENARIO` that selects the sustained network-change variant.
  static const String networkChangeScenario = 'network-change';

  /// Cadence of the steady `testData`/`ack` heartbeat once connected.
  static const Duration heartbeatInterval = Duration(seconds: 2);

  /// Acknowledged heartbeats required before the exchange is declared steady.
  /// The responder prints [steadyExchangeMarker] only after this many, so the
  /// driver script does not swap the network before there is a live exchange.
  static const int preBreakHeartbeats = 3;

  /// Freshly acknowledged heartbeats required after the swap to declare the
  /// exchange resumed.
  static const int postReconnectHeartbeats = 3;

  /// Silence (no `ack` on the initiator / no `testData` on the responder) that
  /// counts as the link being down. Four missed heartbeats: long enough not to
  /// trip on a single lost packet, short enough to react quickly to the swap.
  static const Duration linkSilenceThreshold = Duration(seconds: 8);

  /// Wall-clock budget from break detection to a resumed exchange. Exceeding it
  /// fails the test: the core did not re-rendezvous in time.
  static const Duration reconnectBudget = Duration(minutes: 5);

  /// How long a peer keeps heartbeating while waiting for the network change
  /// at all. Generous because the PC variant triggers the change by hand.
  static const Duration breakWaitBudget = Duration(minutes: 5);

  /// Stable, greppable line the responder prints once the steady exchange is
  /// running. The driver script waits for this before swapping the network
  /// (`READY_MARKER` in run-net-change-test-compose.sh defaults to this exact
  /// text).
  static const String steadyExchangeMarker = 'STEADY EXCHANGE LIVE;';

  // --- encryption scenarios (P3) ---------------------------------------------
  // Pure-exchange variants selected with `NAT_SCENARIO=encrypted` / `rekey`.
  // Both peers perform a real ECDH handshake over the freshly punched
  // connection, register the derived AES cipher in `ErmesPeerCipherHandler`,
  // and from then on every `OrcErmes.send` is encrypted transparently by
  // `buildMessageRoot` and decrypted by the receive path. No network is
  // manipulated, so these are the safest CI scenarios and gate the rest.

  /// Value of `NAT_SCENARIO` that selects the encrypted burst exchange.
  static const String encryptedScenario = 'encrypted';

  /// Value of `NAT_SCENARIO` that selects the mid-session key-rotation variant.
  static const String rekeyScenario = 'rekey';

  /// Cadence of the plaintext handshake frames (ECDH public key, then the
  /// "decrypt cipher ready" confirmation) until both sides can encrypt.
  static const Duration handshakeFrameInterval = Duration(milliseconds: 500);

  /// Wall-clock budget for the cipher handshake once the peers are connected.
  static const Duration handshakeBudget = Duration(minutes: 3);

  /// Extra confirmation frames a peer keeps sending after it can encrypt, so
  /// the last "decrypt ready" reliably reaches a peer that is still finishing
  /// its own handshake. Prevents a lost final frame from stranding one side.
  static const int handshakeLingerFrames = 3;

  /// Encrypted heartbeats the rekey initiator sends BEFORE rotating the key.
  static const int rekeyBeforeMessages = 5;

  /// Encrypted heartbeats the rekey initiator sends AFTER rotating the key.
  static const int rekeyAfterMessages = 5;

  /// Stable, greppable line the encrypted/rekey responder prints once it has
  /// established the cipher and is exchanging encrypted heartbeats.
  static const String cipherReadyMarker = 'CIPHER EXCHANGE LIVE;';
}
