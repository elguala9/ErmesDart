// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';

/// Responder (role B, the moving peer) for the `network-change` scenario.
///
/// ACKs every `testData` heartbeat the initiator sends. Once steady it prints
/// [NatTestProtocol.steadyExchangeMarker] so the driver script knows it can
/// swap the network; after the swap kills the link it detects the silence,
/// re-rendezvous (republishing its signal from the new network), and resumes
/// ACKing until `endOfTests`, all within [NatTestProtocol.reconnectBudget].
class NatHeartbeatResponder {
  NatHeartbeatResponder(this._orc, this._peer, {required this.tag});

  final IOrcErmes<BookData> _orc;
  final String _peer;
  final String tag;

  final Completer<void> _finished = Completer<void>();
  final Stopwatch _clock = Stopwatch();
  int _received = 0;
  int _receivedBeforeBreak = 0;
  int _lastDataMs = 0;
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

  Future<void> _installHandler() async {
    await _orc.onMessage((data, from) {
      try {
        if (from != _peer) {
          throw StateError('Message from unexpected peer $from (want $_peer)');
        }
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

  void _verify() {
    if (_received <= _receivedBeforeBreak) {
      throw StateError('No heartbeats received after the reconnect');
    }
  }
}
