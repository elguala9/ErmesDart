import 'dart:io';

/// P4 (load / stress) and P5 (adverse conditions) scenarios. All run the same
/// reliable sequenced exchange; P5 differs only in that the workflow degrades
/// the path (`tc netem` / `ip link set mtu`) on the Linux runner before the
/// peer launches — the Dart engine just asserts the exchange still completes.
enum NatLoadScenario {
  // --- P4: pure load -------------------------------------------------------
  /// Sustained fixed-rate sequenced stream measuring throughput and latency.
  throughput('throughput'),

  /// Sweep of increasingly large checksummed payloads.
  largePayload('large-payload'),

  /// Idle-then-resume: keepalive-only traffic, then verify the mapping held.
  keepalive('keepalive'),
  // --- P5: adverse path (degradation applied externally) -------------------
  /// Sequenced stream over a lossy path; retransmission must recover fully.
  lossy('lossy'),

  /// Sequenced stream over a high-latency/jitter path.
  latencyJitter('latency-jitter'),

  /// Payload sweep near the MTU edge to exercise fragmentation.
  mtuEdge('mtu-edge');

  /// Binds the enum value to its `NAT_SCENARIO` selector [id].
  const NatLoadScenario(this.id);

  /// The `NAT_SCENARIO` value that selects this variant.
  final String id;

  /// True for the size-sweep variant (one checksummed payload per size).
  bool get isSweep => this == largePayload || this == mtuEdge;

  /// True for the idle-then-resume variant.
  bool get isKeepalive => this == keepalive;
}

/// Resolves the active P4/P5 scenario from `NAT_SCENARIO`, or null otherwise.
NatLoadScenario? currentLoadScenario() {
  final raw = Platform.environment['NAT_SCENARIO'];
  for (final s in NatLoadScenario.values) {
    if (s.id == raw) {
      return s;
    }
  }
  return null;
}

/// True when this process should run a P4/P5 load scenario.
bool isLoadScenario() => currentLoadScenario() != null;

/// Tuning for the load / adverse scenarios. Every knob has an environment
/// override so CI cost (and the netem parameters the workflow documents) stay
/// adjustable without recompiling.
class NatLoadProtocol {
  /// Private constructor; this class only exposes static tuning helpers.
  const NatLoadProtocol._();

  /// Target send rate (messages/second) for `throughput`. `TARGET_RATE` env.
  static int targetRate() => _envInt('TARGET_RATE', 20, min: 1);

  /// Sustained-send window for the sequenced scenarios. `DURATION` (seconds).
  static Duration duration() =>
      Duration(seconds: _envInt('DURATION', 30, min: 1));

  /// Payload sizes (bytes) swept by `large-payload` / `mtu-edge`. `SIZES` env
  /// is a comma-separated list; defaults span 1 KB → 1 MB.
  static List<int> sizes() {
    final raw = Platform.environment['SIZES'];
    if (raw == null || raw.trim().isEmpty) {
      return const [1024, 65536, 262144, 1048576];
    }
    final out = <int>[];
    for (final p in raw.split(',')) {
      final n = int.tryParse(p.trim());
      if (n != null && n > 0) {
        out.add(n);
      }
    }
    return out.isEmpty ? const [1024] : out;
  }

  /// Idle window for `keepalive`. `IDLE_DURATION` (seconds); modest on CI so
  /// the job stays under its timeout while still outlasting NAT UDP timeouts.
  static Duration idle() =>
      Duration(seconds: _envInt('IDLE_DURATION', 60, min: 5));

  /// Cadence of keepalive frames during the idle window.
  static const Duration keepaliveInterval = Duration(seconds: 15);

  /// Sequenced messages for the adverse (P5) scenarios.
  static int adverseMessages() => _envInt('ADVERSE_MESSAGES', 40, min: 1);

  /// Per-message cadence for the adverse sequenced streams.
  static const Duration adverseInterval = Duration(milliseconds: 250);

  /// How long an un-acked sequence waits before the sender retransmits it.
  /// Generous so high-RTT (`latency-jitter`) does not trip a premature resend.
  static const Duration retransmitTimeout = Duration(seconds: 6);

  /// Overall wall-clock budget for the receiver / drain phase.
  static const Duration budget = Duration(minutes: 5);

  /// Reads env var [name] as an int, returning [fallback] when unset, invalid,
  /// or below [min].
  static int _envInt(String name, int fallback, {int min = 0}) {
    final raw = Platform.environment[name];
    final n = raw == null ? null : int.tryParse(raw);
    return (n == null || n < min) ? fallback : n;
  }
}
