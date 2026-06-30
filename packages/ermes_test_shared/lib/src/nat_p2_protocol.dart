import 'dart:io';

import 'nat_test_protocol.dart';

/// P2 message-reliability scenarios. The break / gap is always produced on the
/// LOCAL peer (role A, the sender); the runner (role B) is the receiver that
/// verifies completeness, order and (for gap-detection) drives the missing-ID
/// request path.
enum NatP2Scenario {
  /// Keep emitting sequenced data *during* an in-process outage; after
  /// reconnect every sequence number must arrive, in order.
  losslessReconnect('lossless-reconnect'),

  /// One multi-MB payload (forces chunking), link broken mid-stream; the
  /// payload must reassemble byte-for-byte after resume.
  fragmentedBreak('fragmented-break'),

  /// Initiator skips targeted sequence numbers; the receiver requests the exact
  /// missing IDs and the initiator resends only those.
  gapDetection('gap-detection');

  const NatP2Scenario(this.id);

  /// The `NAT_SCENARIO` value that selects this variant.
  final String id;
}

/// Resolves the active P2 scenario from `NAT_SCENARIO`, or null otherwise.
NatP2Scenario? currentP2Scenario() {
  final raw = Platform.environment['NAT_SCENARIO'];
  for (final s in NatP2Scenario.values) {
    if (s.id == raw) {
      return s;
    }
  }
  return null;
}

/// True when this process should run one of the P2 reliability scenarios.
bool isP2Scenario() => currentP2Scenario() != null;

/// Tuning for the P2 scenarios. Kept in its own file so the family does not
/// collide with P1/P3 timing constants.
class NatP2Protocol {
  const NatP2Protocol._();

  /// Sequenced messages the `lossless-reconnect` initiator emits across the
  /// outage. The receiver must end with this exact set, no gaps.
  static const int losslessMessages = 30;

  /// Which message index triggers the in-process break (sender keeps sending
  /// straight through it, so several messages fall into the outage window).
  static const int losslessBreakAtSeq = 10;

  /// Outage length for `lossless-reconnect`: above
  /// [NatTestProtocol.linkSilenceThreshold] so the link genuinely tears down.
  static const Duration losslessOutage = Duration(seconds: 12);

  /// Payload size for `fragmented-break`. Large enough to span many transport
  /// chunks. Overridable with `FRAGMENT_BYTES` to keep CI cost controllable.
  static const int fragmentedPayloadBytes = 2 * 1024 * 1024;

  /// Environment variable that overrides [fragmentedPayloadBytes].
  static const String fragmentBytesEnv = 'FRAGMENT_BYTES';

  /// Sequence numbers the `gap-detection` initiator deliberately withholds on
  /// the first pass, forcing the receiver to request them explicitly.
  static const List<int> gapInducedSeqs = [3, 7, 11, 17];

  /// Total sequenced messages in the `gap-detection` stream.
  static const int gapTotalMessages = 20;

  /// Per-message send cadence for the sequenced P2 streams.
  static const Duration sendInterval = Duration(milliseconds: 200);

  /// How long the receiver waits for the full set before failing.
  static const Duration receiveBudget = Duration(minutes: 4);

  /// Cadence at which the receiver re-asks for still-missing IDs.
  static const Duration requestInterval = Duration(seconds: 3);

  /// Reads [fragmentBytesEnv], falling back to [fragmentedPayloadBytes].
  static int fragmentBytes() {
    final raw = Platform.environment[fragmentBytesEnv];
    final parsed = raw == null ? null : int.tryParse(raw);
    return (parsed == null || parsed < 1024) ? fragmentedPayloadBytes : parsed;
  }
}
