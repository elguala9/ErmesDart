// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_heartbeat_pump.dart';
import 'nat_reconnect_breaks.dart';
import 'nat_reconnect_protocol.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';
import 'nat_verbose.dart';

/// Local peer (role A) for the P1 disconnection / reconnection scenarios.
///
/// Establishes a steady heartbeat, then hands off to [ReconnectBreaks] which
/// produces the break IN-PROCESS (no firewall/root needed) and verifies the
/// exchange resumes. Prints one greppable metric line the job asserts on.
class NatReconnectInitiator {
  NatReconnectInitiator(
    this._orc,
    this._peer, {
    required this.scenario,
    required this.tag,
  }) : _pump = HeartbeatPump(_orc, _peer, tag: tag);

  final IOrcErmes<BookData> _orc;
  final String _peer;
  final NatReconnectScenario scenario;
  final String tag;
  final HeartbeatPump _pump;
  final Completer<void> _ended = Completer<void>();

  Future<void> run() async {
    final ready = Completer<void>();
    await _install(ready);
    print('[$tag] scenario=${scenario.id}; startup grace.');
    await Future<void>.delayed(NatTestProtocol.initiatorStartupGrace);
    await rendezvous(_orc, _peer, tag: tag);
    await ready.future.timeout(NatTestProtocol.readyTimeout);

    _pump.startClock();
    await _pump.pumpUntil(
      () => _pump.ackedCount >= NatReconnectProtocol.preBreakHeartbeats,
      budget: NatTestProtocol.readyTimeout,
      what: 'steady exchange',
    );
    print('[$tag] ${NatTestProtocol.steadyExchangeMarker} ready to break.');

    final metric = await _runScenario();
    await _finish(metric);
  }

  Future<void> _install(Completer<void> ready) async {
    await _orc.onMessage((data, from) {
      try {
        final env = MessageEnvelope.decode(data);
        if (env.type == DockerMsgType.ready && !ready.isCompleted) {
          ready.complete();
        } else if (env.type == DockerMsgType.ack && env.seq != null) {
          _pump.onAck(env.seq!);
        } else if (env.type == DockerMsgType.endOfTests &&
            !_ended.isCompleted) {
          _ended.complete();
        }
      } on Object catch (e) {
        print('[$tag] handler ignored malformed frame: $e');
      }
    });
  }

  Future<String> _runScenario() {
    final breaks = ReconnectBreaks(_orc, _peer, _pump, tag: tag);
    switch (scenario) {
      case NatReconnectScenario.gracefulReconnect:
        return breaks.graceful();
      case NatReconnectScenario.flap:
        return breaks.flap();
      case NatReconnectScenario.flapStorm:
        return breaks.flapStorm();
      case NatReconnectScenario.longOutage:
        return breaks.longOutage();
      case NatReconnectScenario.peerRestart:
        return breaks.peerRestart(_ended);
    }
  }

  Future<void> _finish(String metric) async {
    const endOfTests = MessageEnvelope(type: DockerMsgType.endOfTests);
    await _orc.send(endOfTests.encode(), _peer);
    print('[$tag] RECONNECT METRICS: $metric');
    await logOwnSignal(tag);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _orc.destroy(force: true);
  }
}
