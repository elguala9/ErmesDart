// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_reconnect_protocol.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';

/// Survivor (role B) for the P1 disconnection / reconnection scenarios.
///
/// ACKs every heartbeat, prints [NatTestProtocol.steadyExchangeMarker] once the
/// exchange is steady, then reacts to each break the LOCAL peer produces by
/// re-rendezvousing (the moved/restarted side gets a fresh signal, so this side
/// must re-dial too). For `peer-restart` it also owns completion: it measures
/// the rejoin time and releases the restarted peer with `endOfTests`.
class NatReconnectResponder {
  /// Creates the survivor bound to [_orc] and the remote [_peer], for the
  /// given [scenario], prefixing logs with [tag].
  NatReconnectResponder(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  });

  /// Orchestrator used to receive heartbeats and send acks/ready frames.
  final IOrcErmes<BookData> _orc;

  /// Identifier of the remote peer.
  final String _peer;

  /// The reconnection scenario being verified.
  final NatReconnectScenario scenario;

  /// Log prefix identifying this peer in the greppable output.
  final String tag;

  /// Completes when the exchange ends (end-of-tests or peer-restart done).
  final Completer<void> _finished = Completer<void>();

  /// Clock used to measure link silence.
  final Stopwatch _clock = Stopwatch();

  /// Total heartbeats received.
  int _received = 0;

  /// Heartbeat count captured when the steady exchange was reached.
  int _receivedBeforeBreak = 0;

  /// Timestamp (ms) of the last data frame, used for silence detection.
  int _lastDataMs = 0;

  /// Runs the full survivor flow: install, rendezvous, reach steady exchange,
  /// react to the break(s), verify resumption, then tear down.
  Future<void> run() async {
    await _install();
    await rendezvous(_orc, _peer, tag: tag);
    _clock.start();
    _lastDataMs = _clock.elapsedMilliseconds;
    final readyPings = _startReadySignal();
    print('[$tag] scenario=${scenario.id}; ACKing until the break.');
    await _awaitSteady();
    readyPings.cancel();
    _receivedBeforeBreak = _received;
    print('[$tag] ${NatTestProtocol.steadyExchangeMarker} steady after '
        '$_received heartbeats.');

    if (scenario == NatReconnectScenario.peerRestart) {
      await _survivorRestart();
    } else {
      await _survivorLoop();
    }
    _verify();
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }

  /// Registers the message handler that acks data frames and completes on
  /// end-of-tests, rejecting frames from unexpected peers.
  Future<void> _install() async {
    await _orc.onMessage((data, from) {
      if (from != _peer) {
        return; // stray traffic from another peer on the shared socket
      }
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.testData) {
          _onData(env);
        } else if (env.type == DockerMsgType.endOfTests &&
            !_finished.isCompleted) {
          print('[$tag] endOfTests received.');
          _finished.complete();
        }
      } on Object catch (e) {
        print('[$tag] WARN: ignored undecodable frame from peer '
            '(${data.length}B): $e');
      }
    });
  }

  /// Counts a received heartbeat and acks its sequence number.
  void _onData(MessageEnvelope env) {
    if (env.seq == null) {
      return;
    }
    _received++;
    _lastDataMs = _clock.elapsedMilliseconds;
    final ack = MessageEnvelope(type: DockerMsgType.ack, seq: env.seq);
    unawaited(_orc.send(ack.encode(), _peer));
  }

  /// Milliseconds elapsed since the last data frame arrived.
  int _silenceMs() => _clock.elapsedMilliseconds - _lastDataMs;

  /// Periodically emits `ready` frames so the initiator can (re-)establish the
  /// exchange; failures during a teardown are swallowed.
  Timer _startReadySignal() {
    Future<void> sendReady() async {
      const readyMsg = MessageEnvelope(type: DockerMsgType.ready);
      try {
        await _orc.send(readyMsg.encode(), _peer);
      } on Object catch (_) {
        // Link is torn down between break and re-rendezvous: the ready is
        // best-effort and resumes once the connection is back. Swallowing the
        // error keeps the periodic timer from crashing the survivor process.
      }
    }

    unawaited(sendReady());
    return Timer.periodic(
      NatTestProtocol.readyResendInterval,
      (_) => unawaited(sendReady()),
    );
  }

  /// Waits until enough pre-break heartbeats have arrived, or throws on
  /// timeout.
  Future<void> _awaitSteady() async {
    final sw = Stopwatch()..start();
    while (_received < NatReconnectProtocol.preBreakHeartbeats) {
      if (sw.elapsed > NatTestProtocol.responderExchangeTimeout) {
        throw StateError('Steady exchange never reached before the break');
      }
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
  }

  /// Reconnects on every break until the initiator sends `endOfTests`. A
  /// sub-threshold flap never trips the silence wait, so the loop simply exits
  /// when `endOfTests` arrives without re-rendezvousing.
  Future<void> _survivorLoop() async {
    while (!_finished.isCompleted) {
      await _waitSilenceOrFinished();
      if (_finished.isCompleted) {
        break;
      }
      await _reconnectAndResume('survivor');
    }
  }

  /// Owns completion for `peer-restart`: measures the rejoin time, prints the
  /// metric, and releases the restarted peer with `endOfTests`.
  Future<void> _survivorRestart() async {
    final ms = await _reconnectAndResume('rejoin');
    // The survivor counts only what it RECEIVED; it cannot know how many the
    // restarted peer sent, so it claims no "messagesLost" figure it never
    // measured. Loss across the restart is asserted by the initiator side.
    print('[$tag] RECONNECT METRICS: peer-restart rejoinTimeMs=$ms '
        'received=$_received');
    const endOfTests = MessageEnvelope(type: DockerMsgType.endOfTests);
    await _orc.send(endOfTests.encode(), _peer);
    if (!_finished.isCompleted) {
      _finished.complete();
    }
  }

  /// Waits until the link falls silent past the threshold or the exchange
  /// finishes; for `peer-restart` a missing drop within budget is an error.
  Future<void> _waitSilenceOrFinished() async {
    final sw = Stopwatch()..start();
    final threshold = NatTestProtocol.linkSilenceThreshold.inMilliseconds;
    while (_silenceMs() < threshold && !_finished.isCompleted) {
      if (sw.elapsed > NatTestProtocol.breakWaitBudget) {
        if (scenario == NatReconnectScenario.peerRestart) {
          throw StateError('No peer drop observed before the wait budget');
        }
        return; // flap / steady: no break is a valid outcome here.
      }
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
  }

  Future<int> _reconnectAndResume(String label) async {
    print('[$tag] $label: link silent ${_silenceMs()}ms — re-rendezvous.');
    // long-outage keeps the initiator offline for >10 min, so the survivor must
    // keep re-dialing past the whole outage instead of the plain 5 min budget.
    final budget = NatReconnectProtocol.reconnectBudgetFor(scenario);
    final sw = Stopwatch()..start();
    final readyPings = _startReadySignal();
    try {
      await rendezvous(_orc, _peer, tag: tag, budget: budget)
          .timeout(budget + const Duration(seconds: 30));
      // One fresh beat after reconnect is enough evidence the exchange resumed:
      // the INITIATOR side already gates on the full postReconnectHeartbeats
      // acks. Requiring the full count HERE too deadlocks — the survivor
      // captures its baseline one beat behind the initiator (the beat in flight
      // during confirmation is counted pre-baseline), so it would wait for a
      // beat the initiator, already satisfied and gone, will never send.
      final baseline = _received;
      final resume = Stopwatch()..start();
      while (_received <= baseline) {
        if (resume.elapsed > NatTestProtocol.reconnectBudget) {
          throw StateError('No heartbeats after reconnect within '
              '${NatTestProtocol.reconnectBudget.inSeconds}s');
        }
        await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
      }
    } finally {
      readyPings.cancel();
    }
    print('[$tag] $label complete in ${sw.elapsedMilliseconds}ms.');
    return sw.elapsedMilliseconds;
  }

  /// Asserts heartbeats resumed after the steady exchange, throwing otherwise.
  void _verify() {
    if (_received <= _receivedBeforeBreak) {
      throw StateError('No heartbeats received after the steady exchange');
    }
  }
}
