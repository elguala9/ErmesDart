// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_load_protocol.dart';
import 'nat_payload.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';

/// Survivor (role B, the receiver) for the P4 load and P5 adverse scenarios.
///
/// ACKs every `testData` (so the sender can measure latency and loss),
/// verifies the checksum of every sized payload, ignores keepalive traffic,
/// and finishes when the sender sends `endOfTests`. A single checksum mismatch
/// or zero received messages fails the run.
class NatLoadResponder {
  NatLoadResponder(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  });

  final IOrcErmes<BookData> _orc;
  final String _peer;
  final NatLoadScenario scenario;
  final String tag;

  final Set<int> _received = <int>{};
  final Completer<void> _finished = Completer<void>();
  int _checksumFailures = 0;
  int _keepalives = 0;

  Future<void> run() async {
    await _install();
    await rendezvous(_orc, _peer, tag: tag);
    final ready = _startReadySignal();
    print('[$tag] scenario=${scenario.id}; receiving + acking.');
    try {
      await _finished.future.timeout(NatLoadProtocol.budget);
    } finally {
      ready.cancel();
    }
    _verify();
    print('[$tag] LOAD METRICS: ${scenario.id} received=${_received.length} '
        'keepalives=$_keepalives checksumFailures=$_checksumFailures');
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
          case DockerMsgType.keepalive:
            _keepalives++;
          case DockerMsgType.endOfTests:
            if (!_finished.isCompleted) {
              _finished.complete();
            }
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
    _verifyChecksum(env);
    _received.add(env.seq!);
    final ack = MessageEnvelope(type: DockerMsgType.ack, seq: env.seq);
    unawaited(_orc.send(ack.encode(), _peer));
  }

  /// Sized payloads carry `sz:<seq>:<checksum>` in [MessageEnvelope.testName];
  /// recompute over the reassembled bytes and count any mismatch.
  void _verifyChecksum(MessageEnvelope env) {
    final name = env.testName ?? '';
    if (!name.startsWith('sz:')) {
      return;
    }
    final expected = int.tryParse(name.split(':').last);
    final actual = NatPayload.checksum(env.payload ?? Uint8List(0));
    if (expected == null || expected != actual) {
      _checksumFailures++;
      print('[$tag] checksum MISMATCH seq=${env.seq} '
          '($actual != $expected, ${env.payload?.length ?? 0}B).');
    }
  }

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
    if (_received.isEmpty) {
      throw StateError('no messages received before endOfTests');
    }
    if (_checksumFailures > 0) {
      throw StateError('$_checksumFailures payload checksum mismatch(es)');
    }
  }
}
