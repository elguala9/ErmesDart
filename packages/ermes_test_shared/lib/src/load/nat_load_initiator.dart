// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import '../bootstrap/message_envelope.dart';
import '../bootstrap/nat_payload.dart';
import '../bootstrap/nat_test_protocol.dart';
import '../config/nat_rendezvous.dart';
import '../config/nat_verbose.dart';
import 'nat_load_metrics.dart';
import 'nat_load_protocol.dart';

/// Local peer (role A, the sender) for the P4 load and P5 adverse scenarios.
///
/// Drives one of three flows — a sustained sequenced stream, a payload-size
/// sweep, or an idle-then-resume keepalive — measuring latency and loss, then
/// prints the scenario's greppable metric line. P5 degradation is applied to
/// the path by the workflow; this engine is identical, it just must still pass.
class NatLoadInitiator {
  /// Creates the sender bound to [_orc], the remote [_peer] id, the selected
  /// load [scenario], and a log [tag].
  NatLoadInitiator(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  });

  /// Orchestrator used to send data and receive acks.
  final IOrcErmes<BookData> _orc;

  /// Id of the remote receiver peer.
  final String _peer;

  /// The P4/P5 load scenario this initiator drives.
  final NatLoadScenario scenario;

  /// Prefix used to label this role's log lines.
  final String tag;

  /// Sequence numbers acknowledged by the receiver.
  final Set<int> _acked = <int>{};

  /// Send timestamp (ms) per sequence number, for RTT measurement.
  final Map<int, int> _sentAtMs = <int, int>{};

  /// Accumulator for latency, retransmit, and duplicate metrics.
  final LoadMetrics _metrics = LoadMetrics();

  /// Times the peer was observed dropping out of the connection set mid-stream
  /// (a spurious disconnect the slow/jittery path should NOT have caused).
  /// Measured by [_startDisconnectMonitor]; reported by `latency-jitter`.
  int _falseDisconnects = 0;

  /// Completes when the receiver signals `ready`.
  final Completer<void> _ready = Completer<void>();

  /// Monotonic clock backing all latency measurements.
  final Stopwatch _clock = Stopwatch();

  /// Runs the selected scenario end to end and tears the orchestrator down.
  Future<void> run() async {
    await _install();
    print('[$tag] scenario=${scenario.id}; startup grace.');
    await Future<void>.delayed(NatTestProtocol.initiatorStartupGrace);
    await rendezvous(_orc, _peer, tag: tag);
    final probe = _startReadyProbe();
    try {
      await _ready.future.timeout(NatTestProtocol.readyTimeout);
    } finally {
      probe.cancel();
    }
    _clock.start();
    final metric = scenario.isKeepalive
        ? await _keepalive()
        : scenario.isSweep
            ? await _sweep()
            : await _sequenced();
    await _finish(metric);
  }

  /// Sustained sequenced stream (throughput, lossy, latency-jitter): send at a
  /// fixed cadence for the window, then retransmit any un-acked seq until the
  /// set is complete. Loss must end at zero — retransmission compensates.
  Future<String> _sequenced() async {
    final isThroughput = scenario == NatLoadScenario.throughput;
    final rate = NatLoadProtocol.targetRate();
    final gap = isThroughput
        ? Duration(milliseconds: (1000 / rate).floor().clamp(1, 1000))
        : NatLoadProtocol.adverseInterval;
    final total = isThroughput
        ? rate * NatLoadProtocol.duration().inSeconds
        : NatLoadProtocol.adverseMessages();
    final monitor = _startDisconnectMonitor();
    final sw = Stopwatch()..start();
    try {
      for (var seq = 0; seq < total; seq++) {
        await _sendData(seq);
        await Future<void>.delayed(gap);
      }
      await _drain(total);
    } finally {
      monitor.cancel();
    }
    final achieved = total / (sw.elapsedMilliseconds / 1000.0);
    return _sequencedMetric(rate, total, achieved);
  }

  /// Samples the connection set once a second and counts each present->absent
  /// transition of the peer, so `latency-jitter` can report REAL spurious
  /// disconnects instead of a hardcoded zero. Diagnostic only: the delivery
  /// gate is still `_drain`.
  Timer _startDisconnectMonitor() {
    var wasConnected = true;
    var checking = false;
    return Timer.periodic(const Duration(seconds: 1), (_) {
      if (checking) {
        return;
      }
      checking = true;
      unawaited(() async {
        try {
          final now = (await _orc.getConnections()).contains(_peer);
          if (wasConnected && !now) {
            _falseDisconnects++;
          }
          wasConnected = now;
        } on Object {
          // Best-effort probe; a transient read failure is not a disconnect.
        } finally {
          checking = false;
        }
      }());
    });
  }

  /// Builds the greppable metric line for the active sequenced scenario. Every
  /// value is derived from measured state: `lost`/`gaps` from the acked set
  /// (0 by construction once `_drain` returns) and `falseDisconnects` from the
  /// connection monitor.
  String _sequencedMetric(int rate, int total, double achieved) {
    final p = _metrics;
    final gaps = total - _acked.length;
    switch (scenario) {
      case NatLoadScenario.throughput:
        return 'throughput targetRate=$rate achievedRate='
            '${achieved.toStringAsFixed(1)} p50Ms=${p.p50()} '
            'p99Ms=${p.p99()} lost=$gaps';
      case NatLoadScenario.latencyJitter:
        return 'latency-jitter falseDisconnects=$_falseDisconnects '
            'duplicates=${p.duplicates} p50Ms=${p.p50()} p99Ms=${p.p99()}';
      case NatLoadScenario.lossy:
        return 'lossy sent=$total delivered=${_acked.length} '
            'retransmitted=${p.retransmits} gaps=$gaps';
      default:
        return '${scenario.id} sent=$total delivered=${_acked.length} '
            'gaps=$gaps';
    }
  }

  /// Payload-size sweep (large-payload, mtu-edge): one checksummed payload per
  /// size, each acked before the next. The receiver verifies the checksum.
  Future<String> _sweep() async {
    final sizes = NatLoadProtocol.sizes();
    var maxLatency = 0;
    for (var i = 0; i < sizes.length; i++) {
      final payload = NatPayload.build(sizes[i], i + 1);
      final sum = NatPayload.checksum(payload);
      final env = MessageEnvelope(
        type: DockerMsgType.testData,
        testName: 'sz:$i:$sum',
        seq: i,
        payload: payload,
      );
      final before = _clock.elapsedMilliseconds;
      _sentAtMs[i] = before;
      await _sendUntilAcked(i, env);
      final latency = _clock.elapsedMilliseconds - before;
      maxLatency = latency > maxLatency ? latency : maxLatency;
      print('[$tag] size=${sizes[i]}B acked in ${latency}ms.');
    }
    return '${scenario.id} sizes=$sizes acked=${_acked.length}/'
        '${sizes.length} maxLatencyMs=$maxLatency';
  }

  /// Idle the link with keepalive-only traffic, then resume: the connection
  /// must still be present (mapping held, no re-rendezvous) and the first real
  /// message must be acked at normal RTT, not after a reconnect.
  Future<String> _keepalive() async {
    await _sendUntilAcked(0, _dataEnv(0));
    final idle = NatLoadProtocol.idle();
    print('[$tag] idling ${idle.inSeconds}s with keepalive only.');
    final sw = Stopwatch()..start();
    while (sw.elapsed < idle) {
      await _send(const MessageEnvelope(type: DockerMsgType.keepalive));
      await Future<void>.delayed(NatLoadProtocol.keepaliveInterval);
    }
    final held = (await _orc.getConnections()).contains(_peer);
    // The whole point of keepalive: the low-rate traffic must hold the NAT
    // mapping so the connection survives the idle WITHOUT a re-rendezvous. If
    // it dropped, the scenario failed even if a later message gets acked.
    if (!held) {
      throw StateError('keepalive: connection dropped during the '
          '${idle.inSeconds}s idle — mapping went cold, re-rendezvous needed');
    }
    final before = _clock.elapsedMilliseconds;
    _sentAtMs[1] = before;
    await _sendUntilAcked(1, _dataEnv(1));
    final latency = _clock.elapsedMilliseconds - before;
    return 'keepalive idleMs=${idle.inMilliseconds} '
        'resumedWithoutRerendezvous=$held firstMsgLatencyMs=$latency';
  }

  /// Retransmits any un-acked sequence until all [total] are acknowledged or
  /// the budget elapses.
  Future<void> _drain(int total) async {
    final sw = Stopwatch()..start();
    while (_acked.length < total) {
      if (sw.elapsed > NatLoadProtocol.budget) {
        throw StateError('only ${_acked.length}/$total acked before budget');
      }
      for (var seq = 0; seq < total; seq++) {
        if (!_acked.contains(seq)) {
          _metrics.retransmits++;
          await _sendData(seq);
        }
      }
      await Future<void>.delayed(NatLoadProtocol.retransmitTimeout);
    }
  }

  /// Sends [env] and retransmits until [seq] is acked or the budget elapses.
  Future<void> _sendUntilAcked(int seq, MessageEnvelope env) async {
    final sw = Stopwatch()..start();
    while (!_acked.contains(seq)) {
      if (sw.elapsed > NatLoadProtocol.budget) {
        throw StateError('seq=$seq never acked within budget');
      }
      await _send(env);
      var waited = Duration.zero;
      while (!_acked.contains(seq) &&
          waited < NatLoadProtocol.retransmitTimeout) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        waited += const Duration(milliseconds: 100);
      }
      if (!_acked.contains(seq)) {
        _metrics.retransmits++;
      }
    }
  }

  /// Builds a small sequenced `testData` envelope for [seq]. The payload is
  /// deterministic and its checksum is carried in the `sz:<seq>:<checksum>`
  /// name so the receiver validates the CONTENT of every sequenced frame (not
  /// just its seq) via the same path the size sweep uses.
  MessageEnvelope _dataEnv(int seq) {
    final payload = NatPayload.build(8, seq);
    final sum = NatPayload.checksum(payload);
    return MessageEnvelope(
      type: DockerMsgType.testData,
      testName: 'sz:$seq:$sum',
      seq: seq,
      payload: payload,
    );
  }

  /// Records the send time for [seq] (once) and sends its data envelope.
  Future<void> _sendData(int seq) async {
    _sentAtMs.putIfAbsent(seq, () => _clock.elapsedMilliseconds);
    await _send(_dataEnv(seq));
  }

  /// Sends [env] to the peer; a send failure (degraded path) is logged only.
  Future<void> _send(MessageEnvelope env) async {
    try {
      await _orc.send(env.encode(), _peer);
    } on Object catch (e) {
      print('[$tag] send ${env.type.name} failed (path degraded?): $e');
    }
  }

  /// Installs the handler tracking `ready` and `ack` frames from the receiver.
  Future<void> _install() async {
    await _orc.onMessage((data, from) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.ready && !_ready.isCompleted) {
          _ready.complete();
        } else if (env.type == DockerMsgType.ack && env.seq != null) {
          _onAck(env.seq!);
        }
      } on Object catch (e) {
        print('[$tag] WARN: ignored undecodable frame (${data.length}B): $e');
      }
    });
  }

  /// Records an ack for [seq], counting duplicates and measuring its RTT.
  void _onAck(int seq) {
    if (_acked.contains(seq)) {
      _metrics.duplicates++;
      return;
    }
    _acked.add(seq);
    final sent = _sentAtMs[seq];
    if (sent != null) {
      _metrics.addRtt(_clock.elapsedMilliseconds - sent);
    }
  }

  /// Periodically probes the peer with `ready` until the handshake completes.
  Timer _startReadyProbe() {
    Future<void> probe() async {
      const p = MessageEnvelope(type: DockerMsgType.ready);
      try {
        await _orc.send(p.encode(), _peer);
      } on Object catch (_) {}
    }

    unawaited(probe());
    return Timer.periodic(
      NatTestProtocol.handshakeFrameInterval,
      (_) => unawaited(probe()),
    );
  }

  /// Signals `endOfTests`, prints [metric], and tears the orchestrator down.
  Future<void> _finish(String metric) async {
    const endOfTests = MessageEnvelope(type: DockerMsgType.endOfTests);
    await _orc.send(endOfTests.encode(), _peer);
    print('[$tag] LOAD METRICS: $metric');
    await logOwnSignal(tag);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }
}
