// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import '../bootstrap/message_envelope.dart';
import '../bootstrap/nat_test_protocol.dart';

/// Sends `testData` heartbeats to a peer and tracks which sequence numbers were
/// acknowledged, so the P1 reconnection engines can reason about loss and link
/// silence without each one re-implementing the bookkeeping.
class HeartbeatPump {
  /// Creates the pump bound to [_orc], the remote [_peer] id, and a log [tag].
  HeartbeatPump(this._orc, this._peer, {required this.tag});

  /// Orchestrator used to send heartbeats.
  final IOrcErmes<BookData> _orc;

  /// Id of the remote peer being heartbeated.
  final String _peer;

  /// Prefix used to label log lines.
  final String tag;

  /// Sequence numbers acknowledged by the peer.
  final Set<int> _acked = <int>{};

  /// Sequence numbers sent to the peer.
  final Set<int> _sent = <int>{};

  /// Monotonic clock backing the silence measurement.
  final Stopwatch _clock = Stopwatch();

  /// Timestamp (ms) of the most recent ack received.
  int _lastAckMs = 0;

  /// Next sequence number to assign to an outgoing heartbeat.
  int _nextSeq = 0;

  /// Number of heartbeats acknowledged so far.
  int get ackedCount => _acked.length;

  /// Number of heartbeats sent so far.
  int get sentCount => _sent.length;

  /// Heartbeats sent that were never acknowledged.
  int get lostCount => _sent.where((s) => !_acked.contains(s)).length;

  /// Records an incoming ack; resets the silence clock.
  void onAck(int seq) {
    _acked.add(seq);
    _lastAckMs = _clock.elapsedMilliseconds;
  }

  /// Starts (or restarts) the silence clock from "now".
  void startClock() {
    if (!_clock.isRunning) {
      _clock.start();
    }
    _lastAckMs = _clock.elapsedMilliseconds;
  }

  /// Milliseconds since the last acknowledged heartbeat.
  int silenceMs() => _clock.elapsedMilliseconds - _lastAckMs;

  /// Sends a single heartbeat. A send failure (link down) is logged, not
  /// thrown: the scenario decides whether silence is expected.
  Future<void> sendOne() async {
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

  /// Heartbeats once per [NatTestProtocol.heartbeatInterval] until [done] is
  /// true, throwing if [budget] elapses first. [what] names the milestone in
  /// the failure message.
  Future<void> pumpUntil(
    bool Function() done, {
    required Duration budget,
    required String what,
  }) async {
    final sw = Stopwatch()..start();
    while (!done()) {
      if (sw.elapsed > budget) {
        throw StateError('$what not reached within ${budget.inSeconds}s');
      }
      await sendOne();
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
  }
}
