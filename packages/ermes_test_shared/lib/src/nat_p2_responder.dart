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
  /// Creates the responder bound to [_orc] and the remote [_peer], for the
  /// given [scenario], prefixing logs with [tag].
  NatP2Responder(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  });

  /// Orchestrator used to receive frames and send acks.
  final IOrcErmes<BookData> _orc;

  /// Identifier of the remote peer this responder talks to.
  final String _peer;

  /// The reliability scenario being verified.
  final NatP2Scenario scenario;

  /// Log prefix identifying this peer in the greppable output.
  final String tag;

  /// Sequence numbers received so far.
  final Set<int> _received = <int>{};

  /// Sequence numbers already requested from the sender.
  final List<int> _requested = <int>[];

  /// Completes once the expected set (or checksum) is satisfied.
  final Completer<void> _finished = Completer<void>();

  /// Clock used to measure link silence.
  final Stopwatch _clock = Stopwatch();

  /// Whether the reassembled fragmented payload matched its checksum.
  bool _checksumOk = false;

  /// Timestamp (ms) of the last data frame, used for silence detection.
  int _lastDataMs = 0;

  /// Expected total number of sequenced messages for the active scenario.
  int get _total => scenario == NatP2Scenario.gapDetection
      ? NatP2Protocol.gapTotalMessages
      : NatP2Protocol.losslessMessages;

  /// These scenarios' initiator tears the link down mid-stream and re-punches,
  /// so this side must re-rendezvous too (see [_survivorLoop]).
  bool get _breaks =>
      scenario == NatP2Scenario.losslessReconnect ||
      scenario == NatP2Scenario.fragmentedBreak;

  /// Runs the full receiver flow: install, rendezvous, receive/verify the
  /// scenario's stream, print the metric line, then tear down.
  Future<void> run() async {
    await _install();
    await rendezvous(_orc, _peer, tag: tag);
    _clock.start();
    _lastDataMs = _clock.elapsedMilliseconds;
    final ready = _startReadySignal();
    print('[$tag] scenario=${scenario.id}; receiving.');
    Timer? requester;
    if (scenario == NatP2Scenario.gapDetection) {
      requester = _startMissingRequester();
    }
    final survivor = _breaks ? _survivorLoop() : Future<void>.value();
    try {
      await _finished.future.timeout(NatP2Protocol.receiveBudget);
    } finally {
      ready.cancel();
      requester?.cancel();
    }
    await survivor;
    _verify();
    print('[$tag] P2 METRICS: ${_metric()}');
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }

  /// Milliseconds elapsed since the last data frame arrived.
  int _silenceMs() => _clock.elapsedMilliseconds - _lastDataMs;

  /// Re-rendezvous whenever the link falls silent past
  /// [NatTestProtocol.linkSilenceThreshold]. The initiator closes the
  /// connection and re-punches mid-stream; without a matching re-punch here
  /// the resumed data never crosses the now-stale NAT mapping and the receive
  /// budget simply times out. Mirrors `NatReconnectResponder._survivorLoop`.
  Future<void> _survivorLoop() async {
    final threshold = NatTestProtocol.linkSilenceThreshold.inMilliseconds;
    while (!_finished.isCompleted) {
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
      if (_finished.isCompleted || _silenceMs() < threshold) {
        continue;
      }
      print('[$tag] link silent ${_silenceMs()}ms — re-rendezvous.');
      try {
        await rendezvous(_orc, _peer, tag: tag);
      } on Object catch (e) {
        print('[$tag] re-rendezvous failed: $e');
      }
      _lastDataMs = _clock.elapsedMilliseconds;
    }
  }

  /// Registers the message handler that dispatches data and end-of-tests
  /// frames, rejecting frames from unexpected peers.
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

  /// Records a received data frame, acks it, and checks for completion.
  void _onData(MessageEnvelope env) {
    if (env.seq == null) {
      return;
    }
    _lastDataMs = _clock.elapsedMilliseconds;
    if (scenario == NatP2Scenario.fragmentedBreak) {
      _onFragment(env);
    } else {
      _received.add(env.seq!);
    }
    final ack = MessageEnvelope(type: DockerMsgType.ack, seq: env.seq);
    unawaited(_orc.send(ack.encode(), _peer));
    _maybeFinish();
  }

  /// Verifies a reassembled fragmented payload against its expected checksum.
  void _onFragment(MessageEnvelope env) {
    final payload = env.payload ?? Uint8List(0);
    final expected = int.tryParse((env.testName ?? '').split(':').last);
    final actual = NatPayload.checksum(payload);
    _checksumOk = expected != null && expected == actual;
    _received.add(0);
    print('[$tag] fragment ${payload.length}B checksum '
        '${_checksumOk ? "OK" : "MISMATCH ($actual != $expected)"}.');
  }

  /// Completes [_finished] once the scenario's success condition is met.
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

  /// Periodically emits `ready` frames so the initiator knows to start sending.
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

  /// Asserts the final received set is complete (or checksum matched),
  /// throwing when a gap remains.
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

  /// Builds the greppable metric line for the active scenario.
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
