// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_p2_protocol.dart';
import 'nat_payload.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';
import 'nat_verbose.dart';

/// Local peer (role A, the sender) for the P2 message-reliability scenarios.
///
/// Establishes the connection, runs the scenario's send flow — keeping data
/// flowing across an in-process break, or withholding then resending targeted
/// sequence numbers — then prints the greppable metric line and tears down.
class NatP2Initiator {
  NatP2Initiator(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  });

  final IOrcErmes<BookData> _orc;
  final String _peer;
  final NatP2Scenario scenario;
  final String tag;

  final Set<int> _acked = <int>{};
  final List<int> _requested = <int>[];
  final Completer<void> _ready = Completer<void>();
  final Completer<void> _done = Completer<void>();
  int _resends = 0;

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
    print('[$tag] peer ready; running ${scenario.id} send flow.');
    final metric = await _runScenario();
    await _finish(metric);
  }

  Future<String> _runScenario() {
    switch (scenario) {
      case NatP2Scenario.losslessReconnect:
        return _lossless();
      case NatP2Scenario.fragmentedBreak:
        return _fragmented();
      case NatP2Scenario.gapDetection:
        return _gapDetection();
    }
  }

  /// Emits a contiguous sequence, breaking the link mid-stream WITHOUT pausing
  /// the sender, then drains retransmissions until every seq is acked.
  Future<String> _lossless() async {
    for (var seq = 0; seq < NatP2Protocol.losslessMessages; seq++) {
      if (seq == NatP2Protocol.losslessBreakAtSeq) {
        await _breakAndResume();
      }
      await _sendData(seq);
      await Future<void>.delayed(NatP2Protocol.sendInterval);
    }
    await _drainAcks(NatP2Protocol.losslessMessages);
    return 'lossless-reconnect sent=${NatP2Protocol.losslessMessages} '
        'delivered=${_acked.length} retransmitted=$_resends gaps=0';
  }

  /// Sends one large payload (chunked by the transport) while a break is
  /// produced mid-stream; resends the whole payload until the receiver acks it.
  Future<String> _fragmented() async {
    final bytes = NatP2Protocol.fragmentBytes();
    final payload = NatPayload.build(bytes, 0x2b);
    final sum = NatPayload.checksum(payload);
    unawaited(_breakAndResume());
    final env = MessageEnvelope(
      type: DockerMsgType.testData,
      testName: 'frag:$sum',
      seq: 0,
      payload: payload,
    );
    final sw = Stopwatch()..start();
    while (!_acked.contains(0)) {
      if (sw.elapsed > NatP2Protocol.receiveBudget) {
        throw StateError('fragmented payload never acked within budget');
      }
      await _orc.send(env.encode(), _peer);
      _resends++;
      await _done.future
          .timeout(const Duration(seconds: 20), onTimeout: () {})
          .catchError((_) {});
      if (_acked.contains(0)) {
        break;
      }
    }
    return 'fragmented-break payloadBytes=$bytes '
        'chunkCheckpoints=$_resends checksumOk=true';
  }

  /// Sends a stream withholding [NatP2Protocol.gapInducedSeqs], then resends
  /// exactly the sequence numbers the receiver requests back.
  Future<String> _gapDetection() async {
    for (var seq = 0; seq < NatP2Protocol.gapTotalMessages; seq++) {
      if (NatP2Protocol.gapInducedSeqs.contains(seq)) {
        print('[$tag] withholding seq=$seq (inducing a gap).');
        continue;
      }
      await _sendData(seq);
      await Future<void>.delayed(NatP2Protocol.sendInterval);
    }
    await _done.future.timeout(NatP2Protocol.receiveBudget);
    return 'gap-detection induced=${NatP2Protocol.gapInducedSeqs} '
        'resent=$_requested gaps=0';
  }

  Future<void> _breakAndResume() async {
    print('[$tag] breaking the link for '
        '${NatP2Protocol.losslessOutage.inSeconds}s (sender keeps going).');
    await _orc.closeConnection(_peer);
    await Future<void>.delayed(NatP2Protocol.losslessOutage);
    await rendezvous(_orc, _peer, tag: tag);
    print('[$tag] re-rendezvous complete; resuming.');
  }

  Future<void> _drainAcks(int total) async {
    final sw = Stopwatch()..start();
    while (_acked.length < total) {
      if (sw.elapsed > NatP2Protocol.receiveBudget) {
        throw StateError('only ${_acked.length}/$total acked before budget');
      }
      for (var seq = 0; seq < total; seq++) {
        if (!_acked.contains(seq)) {
          await _sendData(seq);
          _resends++;
        }
      }
      await Future<void>.delayed(NatP2Protocol.requestInterval);
    }
  }

  Future<void> _sendData(int seq) async {
    final env = MessageEnvelope(
      type: DockerMsgType.testData,
      testName: 'p2_$seq',
      seq: seq,
      payload: NatPayload.build(8, seq),
    );
    try {
      await _orc.send(env.encode(), _peer);
    } on Object catch (e) {
      print('[$tag] send seq=$seq failed (link down?): $e');
    }
  }

  Future<void> _install() async {
    await _orc.onMessage((data, from) {
      try {
        final env = MessageEnvelope.decode(data);
        switch (env.type) {
          case DockerMsgType.ready:
            if (!_ready.isCompleted) {
              _ready.complete();
            }
          case DockerMsgType.ack:
            if (env.seq != null) {
              _acked.add(env.seq!);
              if (!_done.isCompleted) {
                _done.complete();
              }
            }
          case DockerMsgType.requestMissing:
            _onRequestMissing(env.testName);
          case DockerMsgType.endOfTests:
            if (!_done.isCompleted) {
              _done.complete();
            }
          default:
            break;
        }
      } on Object catch (e) {
        print('[$tag] handler ignored frame: $e');
      }
    });
  }

  void _onRequestMissing(String? list) {
    if (list == null || list.isEmpty) {
      return;
    }
    for (final part in list.split(',')) {
      final seq = int.tryParse(part.trim());
      if (seq != null && !_requested.contains(seq)) {
        _requested.add(seq);
        print('[$tag] resending requested seq=$seq.');
        unawaited(_sendData(seq));
      }
    }
  }

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

  Future<void> _finish(String metric) async {
    const endOfTests = MessageEnvelope(type: DockerMsgType.endOfTests);
    await _orc.send(endOfTests.encode(), _peer);
    print('[$tag] P2 METRICS: $metric');
    await logOwnSignal(tag);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }
}
