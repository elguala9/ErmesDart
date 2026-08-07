// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import '../bootstrap/message_envelope.dart';
import '../bootstrap/nat_test_protocol.dart';
import '../config/nat_network_change.dart';
import '../config/nat_rendezvous.dart';
import '../config/nat_verbose.dart';

/// Initiator (role A) for the `network-change` scenario.
///
/// After the first rendezvous it sends a `testData` heartbeat every
/// [NatTestProtocol.heartbeatInterval] and expects an `ack` for each. When the
/// moving peer changes network the acks stop; this class detects the silence,
/// re-rendezvous, and verifies the exchange resumes within
/// [NatTestProtocol.reconnectBudget], reporting reconnect time and the number
/// of heartbeats lost during the outage.
class NatHeartbeatInitiator {
  /// Creates the initiator bound to [_orc], the remote [_peer] id, and a log
  /// [tag].
  NatHeartbeatInitiator(this._orc, this._peer, {required this.tag});

  /// Orchestrator used to send heartbeats and receive acks.
  final IOrcErmes<BookData> _orc;

  /// Id of the remote (moving) peer being exchanged with.
  final String _peer;

  /// Prefix used to label this role's log lines.
  final String tag;

  /// Sequence numbers that have been acknowledged by the peer.
  final Set<int> _acked = <int>{};

  /// Sequence numbers that have been sent to the peer.
  final Set<int> _sent = <int>{};

  /// Monotonic clock driving silence detection and metrics.
  final Stopwatch _clock = Stopwatch();

  /// Timestamp (ms) of the most recent ack received.
  int _lastAckMs = 0;

  /// Timestamp (ms) marking the last ack before the outage began.
  int _gapStartMs = 0;

  /// Next sequence number to assign to an outgoing heartbeat.
  int _nextSeq = 0;

  /// Runs the full initiator lifecycle and tears the orchestrator down.
  Future<void> run() async {
    final ready = Completer<void>();
    await _installHandler(ready);

    print(
      '[$tag] Startup grace '
      '${NatTestProtocol.initiatorStartupGrace.inSeconds}s...',
    );
    await Future<void>.delayed(NatTestProtocol.initiatorStartupGrace);
    await rendezvous(_orc, _peer, tag: tag);

    print('[$tag] Connected; waiting for peer ready...');
    await ready.future.timeout(NatTestProtocol.readyTimeout);

    _clock.start();
    _lastAckMs = _clock.elapsedMilliseconds;
    await _confirmSteady();
    await _waitForBreak();
    final metrics = await _reconnect();
    await _finish(metrics);
  }

  /// Installs the message handler that tracks peer `ready` and `ack` frames,
  /// completing [ready] on the first `ready`.
  Future<void> _installHandler(Completer<void> ready) async {
    await _orc.onMessage((data, from) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.ready) {
          if (!ready.isCompleted) {
            print('[$tag] Peer signalled ready.');
            ready.complete();
          }
        } else if (env.type == DockerMsgType.ack && env.seq != null) {
          _acked.add(env.seq!);
          _lastAckMs = _clock.elapsedMilliseconds;
        }
      } on Object catch (e) {
        print('[$tag] WARN: ignored undecodable frame (${data.length}B): $e');
      }
    });
  }

  /// Milliseconds elapsed since the last acknowledged heartbeat.
  int _silenceMs() => _clock.elapsedMilliseconds - _lastAckMs;

  /// Sends one sequenced heartbeat; a send failure (link down) is logged only.
  Future<void> _sendHeartbeat() async {
    final seq = _nextSeq++;
    final env = MessageEnvelope(
      type: DockerMsgType.testData,
      testName: 'hb_$seq',
      seq: seq,
      payload: Uint8List.fromList([seq & 0xff]),
    );
    _sent.add(seq);
    try {
      await _orc.send(env.encode(), _peer);
    } on Object catch (e) {
      print('[$tag] heartbeat seq=$seq send failed (link down?): $e');
    }
  }

  /// Heartbeats until a steady, acknowledged exchange is established.
  Future<void> _confirmSteady() async {
    final sw = Stopwatch()..start();
    while (_acked.length < NatTestProtocol.preBreakHeartbeats) {
      if (sw.elapsed > NatTestProtocol.readyTimeout) {
        throw StateError('Steady exchange never established before timeout');
      }
      await _sendHeartbeat();
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    print('[$tag] Steady exchange confirmed (${_acked.length} acks).');
  }

  /// Keeps heartbeating until acks fall silent, signalling the network change.
  Future<void> _waitForBreak() async {
    print('[$tag] Steady; heartbeating until the network change...');
    final sw = Stopwatch()..start();
    while (_silenceMs() < NatTestProtocol.linkSilenceThreshold.inMilliseconds) {
      if (sw.elapsed > NatTestProtocol.breakWaitBudget) {
        throw StateError(
          'No network-change break observed within '
          '${NatTestProtocol.breakWaitBudget.inSeconds}s',
        );
      }
      await _sendHeartbeat();
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    _gapStartMs = _lastAckMs;
    print(
      '[$tag] Link silent for ${_silenceMs()}ms — break detected at '
      'seq=$_nextSeq.',
    );
  }

  /// Re-rendezvous after the break, confirms the exchange resumes, and returns
  /// the measured reconnect metrics.
  Future<ReconnectMetrics> _reconnect() async {
    print('[$tag] Re-rendezvous after network change...');
    final sw = Stopwatch()..start();
    await rendezvous(_orc, _peer, tag: tag)
        .timeout(NatTestProtocol.reconnectBudget);
    print('[$tag] Reconnected in ${sw.elapsed.inSeconds}s; confirming resume.');

    final baseline = _acked.length;
    while (_acked.length < baseline + NatTestProtocol.postReconnectHeartbeats) {
      if (sw.elapsed > NatTestProtocol.reconnectBudget) {
        throw StateError(
          'Exchange did not resume within '
          '${NatTestProtocol.reconnectBudget.inSeconds}s after the change',
        );
      }
      await _sendHeartbeat();
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }

    final lost = _sent.where((s) => !_acked.contains(s)).length;
    final metrics = ReconnectMetrics(
      outage: Duration(milliseconds: _lastAckMs - _gapStartMs),
      messagesLost: lost,
      messagesSent: _sent.length,
    );
    print('[$tag] Exchange resumed. ${metrics.describe()}');
    return metrics;
  }

  /// Signals `endOfTests`, prints the metrics, and tears the orchestrator down.
  Future<void> _finish(ReconnectMetrics metrics) async {
    const endOfTests = MessageEnvelope(type: DockerMsgType.endOfTests);
    await _orc.send(endOfTests.encode(), _peer);
    print('[$tag] RECONNECT METRICS: ${metrics.describe()}');
    await logOwnSignal(tag);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }
}
