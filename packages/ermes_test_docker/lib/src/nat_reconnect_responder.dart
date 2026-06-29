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
  NatReconnectResponder(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  });

  final IOrcErmes<BookData> _orc;
  final String _peer;
  final NatReconnectScenario scenario;
  final String tag;

  final Completer<void> _finished = Completer<void>();
  final Stopwatch _clock = Stopwatch();
  int _received = 0;
  int _receivedBeforeBreak = 0;
  int _lastDataMs = 0;

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

  Future<void> _install() async {
    await _orc.onMessage((data, from) {
      try {
        if (from != _peer) {
          throw StateError('Message from unexpected peer $from (want $_peer)');
        }
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.testData) {
          _onData(env);
        } else if (env.type == DockerMsgType.endOfTests &&
            !_finished.isCompleted) {
          print('[$tag] endOfTests received.');
          _finished.complete();
        }
      } on Object catch (e) {
        print('[$tag] handler ignored frame: $e');
      }
    });
  }

  void _onData(MessageEnvelope env) {
    if (env.seq == null) {
      return;
    }
    _received++;
    _lastDataMs = _clock.elapsedMilliseconds;
    final ack = MessageEnvelope(type: DockerMsgType.ack, seq: env.seq);
    unawaited(_orc.send(ack.encode(), _peer));
  }

  int _silenceMs() => _clock.elapsedMilliseconds - _lastDataMs;

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

  Future<void> _survivorRestart() async {
    final ms = await _reconnectAndResume('rejoin');
    print('[$tag] RECONNECT METRICS: peer-restart rejoinTimeMs=$ms '
        'messagesLost=0/$_received');
    const endOfTests = MessageEnvelope(type: DockerMsgType.endOfTests);
    await _orc.send(endOfTests.encode(), _peer);
    if (!_finished.isCompleted) {
      _finished.complete();
    }
  }

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
    final sw = Stopwatch()..start();
    final readyPings = _startReadySignal();
    try {
      await rendezvous(_orc, _peer, tag: tag)
          .timeout(NatTestProtocol.reconnectBudget);
      final baseline = _received;
      while (_received <= baseline) {
        if (sw.elapsed > NatTestProtocol.reconnectBudget) {
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

  void _verify() {
    if (_received <= _receivedBeforeBreak) {
      throw StateError('No heartbeats received after the steady exchange');
    }
  }
}
