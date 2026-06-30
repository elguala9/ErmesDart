/// Latency / retransmission bookkeeping for the P4/P5 load scenarios.
///
/// The sender records the round-trip time of every acked sequence and counts
/// retransmissions and duplicate acks, so the metric line can report achieved
/// latency percentiles and prove there were no duplicate deliveries.
class LoadMetrics {
  final List<int> _rtts = <int>[];

  /// Resends issued because an ack did not arrive within the timeout.
  int retransmits = 0;

  /// Acks received for a sequence that was already acknowledged — must stay 0
  /// (a duplicate delivery would mean retransmission fired too eagerly).
  int duplicates = 0;

  void addRtt(int ms) => _rtts.add(ms);

  /// 50th-percentile round-trip latency in ms (0 when nothing was measured).
  int p50() => _percentile(0.50);

  /// 99th-percentile round-trip latency in ms (0 when nothing was measured).
  int p99() => _percentile(0.99);

  int _percentile(double q) {
    if (_rtts.isEmpty) {
      return 0;
    }
    final sorted = List<int>.from(_rtts)..sort();
    final idx = (q * (sorted.length - 1)).round();
    return sorted[idx];
  }
}
