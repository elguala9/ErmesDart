// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_p2_protocol.dart';
import 'nat_payload.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';

/// Survivor (role B, the receiver) for the P2 message-reliability scenarios.
///
/// ACKs every `testData`, tracks which sequence numbers arrived, and — for
/// `gap-detection` — proactively requests the IDs still missing. Verifies the
/// final set has no gaps (and, for `fragmented-break`, that the reassembled
/// payload checksum matches) before declaring PASS.
class NatP2Responder {
  NatP2Responder(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  });

  final IOrcErmes<BookData> _orc;
  final String _peer;
  final NatP2Scenario scenario;
  final String tag;

  final Set<int> _received = <int>{};
  final List<int> _requested = <int>[];
  final Completer<void> _finished = Completer<void>();
  bool _checksumOk = false;

  int get _total => scenario == NatP2Scenario.gapDetection
      ? NatP2Protocol.gapTotalMessages
      : NatP2Protocol.losslessMessages;

  Future<void> run() async {
    await _install();
    await rendezvous(_orc, _peer, tag: tag);
    final ready = _startReadySignal();
    print('[$tag] scenario=${scenario.id}; receiving.');
    Timer? requester;
    if (scenario == NatP2Scenario.gapDetection) {
      requester = _startMissingRequester();
    }
    try {
      await _finished.future.timeout(NatP2Protocol.receiveBudget);
    } finally {
      ready.cancel();
      requester?.cancel();
    }
    _verify();
    print('[$tag] P2 METRICS: ${_metric()}');
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }

  Future<void> _install() async {
    await _orc.onMessage((data, from) {
      try {
        if (from != _peer) {
          throw StateError('frame from unexpected peer $from');
        }
        final env = MessageEnvelope.decode(data);
        switch (env.type) {
          case DockerMsgType.testData:
            _onData(env);
          case DockerMsgType.endOfTests:
            _maybeFinish();
          default:
            break;
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
    if (scenario == NatP2Scenario.fragmentedBreak) {
      _onFragment(env);
    } else {
      _received.add(env.seq!);
    }
    final ack = MessageEnvelope(type: DockerMsgType.ack, seq: env.seq);
    unawaited(_orc.send(ack.encode(), _peer));
    _maybeFinish();
  }

  void _onFragment(MessageEnvelope env) {
    final payload = env.payload ?? Uint8List(0);
    final expected = int.tryParse((env.testName ?? '').split(':').last);
    final actual = NatPayload.checksum(payload);
    _checksumOk = expected != null && expected == actual;
    _received.add(0);
    print('[$tag] fragment ${payload.length}B checksum '
        '${_checksumOk ? "OK" : "MISMATCH ($actual != $expected)"}.');
  }

  void _maybeFinish() {
    final complete = scenario == NatP2Scenario.fragmentedBreak
        ? _checksumOk
        : _received.length >= _total;
    if (complete && !_finished.isCompleted) {
      _finished.complete();
    }
  }

  /// Lists the sequence numbers still missing and asks the sender for exactly
  /// those — the explicit missing-ID request path `gap-detection` exercises.
  Timer _startMissingRequester() =>
      Timer.periodic(NatP2Protocol.requestInterval, (_) {
      final missing = <int>[];
      for (var seq = 0; seq < _total; seq++) {
        if (!_received.contains(seq)) {
          missing.add(seq);
        }
      }
      if (missing.isEmpty) {
        return;
      }
      for (final m in missing) {
        if (!_requested.contains(m)) {
          _requested.add(m);
        }
      }
      final env = MessageEnvelope(
        type: DockerMsgType.requestMissing,
        testName: missing.join(','),
      );
      print('[$tag] requesting missing IDs: $missing');
      unawaited(_orc.send(env.encode(), _peer));
    });

  Timer _startReadySignal() {
    Future<void> sendReady() async {
      const readyMsg = MessageEnvelope(type: DockerMsgType.ready);
      try {
        await _orc.send(readyMsg.encode(), _peer);
      } on Object catch (_) {}
    }

    unawaited(sendReady());
    return Timer.periodic(
      NatTestProtocol.readyResendInterval,
      (_) => unawaited(sendReady()),
    );
  }

  void _verify() {
    if (scenario == NatP2Scenario.fragmentedBreak) {
      if (!_checksumOk) {
        throw StateError('fragmented payload checksum never matched');
      }
      return;
    }
    for (var seq = 0; seq < _total; seq++) {
      if (!_received.contains(seq)) {
        throw StateError('missing seq=$seq; received ${_received.length}'
            '/$_total: $_received');
      }
    }
  }

  String _metric() {
    switch (scenario) {
      case NatP2Scenario.losslessReconnect:
        return 'lossless-reconnect delivered=${_received.length} gaps=0';
      case NatP2Scenario.fragmentedBreak:
        return 'fragmented-break checksumOk=$_checksumOk';
      case NatP2Scenario.gapDetection:
        return 'gap-detection requested=$_requested '
            'delivered=${_received.length} gaps=0';
    }
  }
}
