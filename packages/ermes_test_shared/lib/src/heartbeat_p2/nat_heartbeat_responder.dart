// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import '../bootstrap/message_envelope.dart';
import '../bootstrap/nat_test_protocol.dart';
import '../config/nat_rendezvous.dart';

/// Responder (role B, the moving peer) for the `network-change` scenario.
///
/// ACKs every `testData` heartbeat the initiator sends. Once steady it prints
/// [NatTestProtocol.steadyExchangeMarker] so the driver script knows it can
/// swap the network; after the swap kills the link it detects the silence,
/// re-rendezvous (republishing its signal from the new network), and resumes
/// ACKing until `endOfTests`, all within [NatTestProtocol.reconnectBudget].
class NatHeartbeatResponder {
  /// Creates the responder bound to [_orc], the remote [_peer] id, and a log
  /// [tag].
  NatHeartbeatResponder(this._orc, this._peer, {required this.tag});

  /// Orchestrator used to receive heartbeats and send acks.
  final IOrcErmes<BookData> _orc;

  /// Id of the remote initiator peer.
  final String _peer;

  /// Prefix used to label this role's log lines.
  final String tag;

  /// Completes when the initiator's `endOfTests` frame arrives.
  final Completer<void> _finished = Completer<void>();

  /// Monotonic clock driving silence detection.
  final Stopwatch _clock = Stopwatch();

  /// Total number of heartbeats received.
  int _received = 0;

  /// Heartbeats received up to the moment the break was detected.
  int _receivedBeforeBreak = 0;

  /// Timestamp (ms) of the most recent heartbeat received.
  int _lastDataMs = 0;

  /// Whether the steady-exchange marker has already been printed.
  bool _markerPrinted = false;

  /// Runs the full responder lifecycle and tears the orchestrator down.
  Future<void> run() async {
    await _installHandler();
    await rendezvous(_orc, _peer, tag: tag);

    _clock.start();
    _lastDataMs = _clock.elapsedMilliseconds;
    final readyPings = _startReadySignal();
    print('[$tag] Connected; ACKing heartbeats until the network change.');
    try {
      await _awaitSteadyThenBreak();
      readyPings.cancel();
      await _reconnect();
      await _finished.future.timeout(NatTestProtocol.reconnectBudget);
    } finally {
      readyPings.cancel();
    }
    _verify();
    print('[$tag] Exchange resumed and endOfTests received.');
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }

  /// Installs the message handler that acks `testData` and completes on
  /// `endOfTests`, rejecting frames from unexpected peers.
  Future<void> _installHandler() async {
    await _orc.onMessage((data, from) {
      if (from != _peer) {
        return; // stray traffic from another peer on the shared socket
      }
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.testData) {
          _onData(env);
        } else if (env.type == DockerMsgType.endOfTests) {
          print('[$tag] endOfTests received.');
          if (!_finished.isCompleted) {
            _finished.complete();
          }
        }
      } on Object catch (e) {
        print('[$tag] WARN: ignored undecodable frame from peer '
            '(${data.length}B): $e');
      }
    });
  }

  /// Records a received heartbeat and sends back its ack.
  void _onData(MessageEnvelope env) {
    if (env.seq == null) {
      return;
    }
    _received++;
    _lastDataMs = _clock.elapsedMilliseconds;
    final ack = MessageEnvelope(type: DockerMsgType.ack, seq: env.seq);
    unawaited(_orc.send(ack.encode(), _peer));
  }

  /// Milliseconds elapsed since the last received heartbeat.
  int _silenceMs() => _clock.elapsedMilliseconds - _lastDataMs;

  /// Sends `ready` until the first heartbeat arrives so a single lost `ready`
  /// cannot stall the initiator (mirrors the burst-mode responder).
  Timer _startReadySignal() {
    void sendReady() {
      if (_received > 0) {
        return;
      }
      const readyMsg = MessageEnvelope(type: DockerMsgType.ready);
      unawaited(_orc.send(readyMsg.encode(), _peer));
    }

    sendReady();
    return Timer.periodic(
      NatTestProtocol.readyResendInterval,
      (_) => sendReady(),
    );
  }

  /// Waits for a steady exchange, prints the marker, then waits for the
  /// network-change break (heartbeat silence).
  Future<void> _awaitSteadyThenBreak() async {
    final sw = Stopwatch()..start();
    while (_received < NatTestProtocol.preBreakHeartbeats) {
      if (sw.elapsed > NatTestProtocol.responderExchangeTimeout) {
        throw StateError('Steady exchange never reached before the break');
      }
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    _printMarker();
    _receivedBeforeBreak = _received;

    final waited = Stopwatch()..start();
    while (_silenceMs() < NatTestProtocol.linkSilenceThreshold.inMilliseconds) {
      if (waited.elapsed > NatTestProtocol.breakWaitBudget) {
        throw StateError(
          'No network-change break observed within '
          '${NatTestProtocol.breakWaitBudget.inSeconds}s',
        );
      }
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    print('[$tag] Link silent for ${_silenceMs()}ms — break detected.');
  }

  /// Prints the steady-exchange marker exactly once so the driver can act.
  void _printMarker() {
    if (_markerPrinted) {
      return;
    }
    _markerPrinted = true;
    print(
      '[$tag] ${NatTestProtocol.steadyExchangeMarker} steady after '
      '$_received heartbeats; ready for the network change.',
    );
  }

  /// Re-rendezvous after the break and waits until heartbeats resume.
  Future<void> _reconnect() async {
    print('[$tag] Re-rendezvous after network change...');
    final sw = Stopwatch()..start();
    await rendezvous(_orc, _peer, tag: tag)
        .timeout(NatTestProtocol.reconnectBudget);
    print(
      '[$tag] Reconnected in ${sw.elapsed.inSeconds}s; awaiting heartbeats.',
    );

    final baseline = _received;
    while (_received <= baseline) {
      if (sw.elapsed > NatTestProtocol.reconnectBudget) {
        throw StateError(
          'No heartbeats after reconnect within '
          '${NatTestProtocol.reconnectBudget.inSeconds}s',
        );
      }
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    print('[$tag] Heartbeats resumed ($_received received total).');
  }

  /// Asserts that heartbeats were actually received after the reconnect.
  void _verify() {
    if (_received <= _receivedBeforeBreak) {
      throw StateError('No heartbeats received after the reconnect');
    }
  }
}
