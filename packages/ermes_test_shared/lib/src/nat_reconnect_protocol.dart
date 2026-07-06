import 'dart:io';

import 'nat_test_protocol.dart';

/// P1 disconnection / reconnection scenarios. The break is always produced on
/// the LOCAL peer (role A); the runner (role B) is the stable survivor.
///
/// These constants live in their own file (not [NatTestProtocol]) so the P1
/// work never collides with the encryption scenarios being wired in parallel.
/// The shared heartbeat timings ([NatTestProtocol.heartbeatInterval],
/// [NatTestProtocol.linkSilenceThreshold], [NatTestProtocol.reconnectBudget],
/// ...) are reused as-is.
enum NatReconnectScenario {
  /// Local peer cleanly tears the link down (`disconnectNow` + close), then
  /// both sides re-rendezvous and resume with no loss.
  gracefulReconnect('graceful-reconnect'),

  /// Local peer process is hard-killed and relaunched with the same identity
  /// by its driver script; the runner survivor must detect the drop and the
  /// restarted peer must rejoin. The binary itself just heartbeats.
  peerRestart('peer-restart'),

  /// Local peer pauses its data path for less than [linkSilenceThreshold];
  /// the connection must NOT be torn down.
  flap('flap'),

  /// Local peer breaks/restores the link [flapCyclesEnv] times, each break
  /// long enough to force a genuine reconnect.
  flapStorm('flap-storm'),

  /// Local peer breaks the link longer than the relay signal lifetime so the
  /// published signal expires, then restores; both sides republish.
  longOutage('long-outage');

  /// Binds each variant to its `NAT_SCENARIO` selector [id].
  const NatReconnectScenario(this.id);

  /// The `NAT_SCENARIO` value that selects this variant.
  final String id;
}

/// Resolves the active P1 scenario from `NAT_SCENARIO`, or null when the
/// environment selects a non-P1 variant (burst, network-change, encrypted...).
NatReconnectScenario? currentReconnectScenario() {
  final raw = Platform.environment['NAT_SCENARIO'];
  for (final s in NatReconnectScenario.values) {
    if (s.id == raw) {
      return s;
    }
  }
  return null;
}

/// True when this process should run one of the P1 reconnection scenarios.
bool isReconnectScenario() => currentReconnectScenario() != null;

/// Tuning shared across the P1 scenarios, kept apart from [NatTestProtocol]
/// purely to avoid editing a file another scenario family is changing.
class NatReconnectProtocol {
  /// Private constructor: this class is a namespace for constants only.
  const NatReconnectProtocol._();

  /// Acknowledged heartbeats required before the local peer produces the
  /// break, so there is a genuinely live exchange to interrupt.
  static const int preBreakHeartbeats = NatTestProtocol.preBreakHeartbeats;

  /// Freshly acknowledged heartbeats required after a reconnect to declare the
  /// exchange resumed.
  static const int postReconnectHeartbeats =
      NatTestProtocol.postReconnectHeartbeats;

  /// Length of the sub-threshold pause for the `flap` scenario. Comfortably
  /// below [NatTestProtocol.linkSilenceThreshold] (8 s) so the silence
  /// detector must not trip.
  static const Duration flapPause = Duration(seconds: 4);

  /// How long the `flap` scenario keeps heartbeating after the pause to prove
  /// the connection survived and never re-rendezvoused.
  static const Duration flapObserveAfter = Duration(seconds: 10);

  /// Length of each `flap-storm` outage. Above [linkSilenceThreshold] so every
  /// cycle forces a real teardown + reconnect.
  static const Duration flapStormOutage = Duration(seconds: 12);

  /// Default number of break/restore cycles for `flap-storm`; overridable with
  /// the `FLAP_CYCLES` environment variable.
  static const int defaultFlapCycles = 3;

  /// Environment variable that overrides the `flap-storm` cycle count.
  static const String flapCyclesEnv = 'FLAP_CYCLES';

  /// Outage length for `long-outage`: longer than the relay signal lifetime
  /// (`epochTimestampExpireConversation` ≈ 10 min) so the signal expires.
  /// Overridable with `LONG_OUTAGE_SECONDS` to keep CI cost controllable.
  static const Duration longOutage = Duration(minutes: 11);

  /// Environment variable that overrides the `long-outage` outage length.
  static const String longOutageSecondsEnv = 'LONG_OUTAGE_SECONDS';

  /// Trailing wall-clock the survivor keeps re-dialing AFTER the outage has
  /// elapsed, for `long-outage` only. The whole [longOutageDuration] is dead
  /// time — the initiator is absent — so only this slice is a genuine
  /// reconnection window. NAT re-punch after a cold mapping needs several
  /// synchronized 60-90s windows to land an overlapping hole punch, so this is
  /// deliberately wider than the plain [NatTestProtocol.reconnectBudget] (which
  /// left only ~2-3 attempts once both peers were back online).
  static const Duration longOutageReconnectBudget = Duration(minutes: 10);

  /// Reads [flapCyclesEnv], falling back to [defaultFlapCycles].
  static int flapCycles() {
    final raw = Platform.environment[flapCyclesEnv];
    final parsed = raw == null ? null : int.tryParse(raw);
    return (parsed == null || parsed < 1) ? defaultFlapCycles : parsed;
  }

  /// Reads [longOutageSecondsEnv], falling back to [longOutage].
  static Duration longOutageDuration() {
    final raw = Platform.environment[longOutageSecondsEnv];
    final parsed = raw == null ? null : int.tryParse(raw);
    return (parsed == null || parsed < 1)
        ? longOutage
        : Duration(seconds: parsed);
  }

  /// Wall-clock budget the SURVIVOR allows for a single re-rendezvous after a
  /// break. For most scenarios the outage is seconds, so
  /// [NatTestProtocol.reconnectBudget] (5 min) is ample. `long-outage` is the
  /// exception: the initiator stays offline for [longOutageDuration] (>10 min),
  /// so the survivor must keep re-dialing past the whole outage — with the
  /// plain 5 min budget it gives up before the peer can possibly return.
  static Duration reconnectBudgetFor(NatReconnectScenario? scenario) {
    if (scenario == NatReconnectScenario.longOutage) {
      return longOutageDuration() + longOutageReconnectBudget;
    }
    return NatTestProtocol.reconnectBudget;
  }
}
