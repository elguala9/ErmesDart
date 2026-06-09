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

  /// Delay between rendezvous attempts. Each attempt re-publishes a fresh
  /// STUN signal, keeping the NAT mapping alive.
  static const Duration rendezvousRetryInterval = Duration(seconds: 20);

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
}
