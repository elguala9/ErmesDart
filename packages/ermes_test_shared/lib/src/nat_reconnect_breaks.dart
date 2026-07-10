// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_heartbeat_pump.dart';
import 'nat_reconnect_protocol.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';

/// In-process implementations of the P1 break/restore sequences, run on the
/// LOCAL peer. Each returns the scenario's greppable metric line.
///
/// The break is produced from Dart (close / pause the local link) rather than
/// with OS firewall rules, so the driver scripts stay portable across Linux
/// and Windows and need no elevated privileges, while still exercising the
/// core's silence-detection and re-rendezvous path.
class ReconnectBreaks {
  /// Creates the break driver bound to [_orc], the remote [_peer] and the
  /// heartbeat [_pump], for the given [scenario], prefixing logs with [tag].
  ReconnectBreaks(
    this._orc,
    this._peer,
    this._pump, {
    required this.scenario,
    required this.tag,
  });

  /// Orchestrator used to close/reopen connections and send frames.
  final IOrcErmes<BookData> _orc;

  /// Identifier of the remote peer.
  final String _peer;

  /// Heartbeat pump driving the steady exchange and measuring loss.
  final HeartbeatPump _pump;

  /// The reconnection scenario being exercised.
  final NatReconnectScenario scenario;

  /// Log prefix identifying this peer in the greppable output.
  final String tag;

  /// Cleanly tears the link down, re-rendezvous, and reports reconnect time
  /// and message loss.
  Future<String> graceful() async {
    const bye = MessageEnvelope(type: DockerMsgType.disconnectNow);
    await _orc.send(bye.encode(), _peer);
    print('[$tag] sent disconnectNow; tearing the connection down.');
    await _orc.closeConnection(_peer);
    await Future<void>.delayed(const Duration(seconds: 2));
    final ms = await _reRendezvousAndResume('graceful');
    return 'graceful-reconnect reconnectTimeMs=$ms '
        'messagesLost=${_pump.lostCount}/${_pump.sentCount}';
  }

  /// Pauses the data path below the silence threshold, then proves the
  /// connection survived without tearing down or re-rendezvousing.
  Future<String> flap() async {
    final before = _pump.ackedCount;
    print('[$tag] flap: pausing data path for '
        '${NatReconnectProtocol.flapPause.inSeconds}s (no teardown).');
    await Future<void>.delayed(NatReconnectProtocol.flapPause);
    final observe = Stopwatch()..start();
    while (observe.elapsed < NatReconnectProtocol.flapObserveAfter) {
      await _pump.sendOne();
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    if (!(await _orc.getConnections()).contains(_peer)) {
      throw StateError('flap tore the connection down (silence over-reacted)');
    }
    if (_pump.ackedCount <= before) {
      throw StateError('flap: exchange did not catch up after the pause');
    }
    final missed = NatReconnectProtocol.flapPause.inMilliseconds ~/
        NatTestProtocol.heartbeatInterval.inMilliseconds;
    return 'flap missedBeats=$missed reconnectTriggered=false';
  }

  /// Repeats break/restore cycles, verifying each reconnect succeeds and no
  /// connections leak, reporting the worst reconnect time.
  Future<String> flapStorm() async {
    final cycles = NatReconnectProtocol.flapCycles();
    var maxMs = 0;
    var ok = 0;
    for (var i = 0; i < cycles; i++) {
      final ms = await _oneFlapCycle(i);
      if (ms > maxMs) {
        maxMs = ms;
      }
      ok++;
    }
    final leaked = (await _orc.getConnections()).length - 1;
    return 'flap-storm cycles=$cycles reconnectsOk=$ok '
        'maxReconnectMs=$maxMs leakedConnections=${leaked < 0 ? 0 : leaked}';
  }

  /// Runs one flap-storm cycle [i]: break, wait, re-rendezvous, and assert no
  /// connection leak; returns the reconnect time in milliseconds.
  Future<int> _oneFlapCycle(int i) async {
    print('[$tag] flap-storm cycle ${i + 1}: breaking the link.');
    await _orc.closeConnection(_peer);
    await Future<void>.delayed(NatReconnectProtocol.flapStormOutage);
    final ms = await _reRendezvousAndResume('cycle ${i + 1}');
    final conns = await _orc.getConnections();
    if (conns.where((c) => c == _peer).length != 1) {
      throw StateError(
        'flap-storm leaked connections after cycle ${i + 1}: $conns',
      );
    }
    return ms;
  }

  /// Breaks the link long enough for the published signal to expire, then
  /// restores and republishes, reporting reconnect time and message loss.
  Future<String> longOutage() async {
    final outage = NatReconnectProtocol.longOutageDuration();
    print('[$tag] long-outage: breaking the link for '
        '${outage.inSeconds}s (signal will expire).');
    await _orc.closeConnection(_peer);
    // Hold our NAT mapping warm across the outage instead of sleeping idle:
    // closeConnection stops all traffic on the shared SHSP socket, so without a
    // periodic STUN keepalive the NAT evicts the mapping during the long
    // silence and the post-outage re-punch starts cold against a dead port.
    // A refresh every few seconds keeps the same external port live so the
    // peer's dial lands on a real mapping when both sides come back.
    await keepNatMappingWarm(outage);
    final ms = await _reRendezvousAndResume('long-outage');
    return 'long-outage outageMs=${outage.inMilliseconds} '
        'reconnectTimeMs=$ms '
        'messagesLost=${_pump.lostCount}/${_pump.sentCount}';
  }

  /// Heartbeats until the survivor signals [ended] (it owns completion for the
  /// peer-restart scenario, since this process is killed and relaunched).
  Future<String> peerRestart(Completer<void> ended) async {
    print('[$tag] peer-restart: heartbeating; the survivor drives completion '
        '(this process may be killed and relaunched by its driver).');
    final sw = Stopwatch()..start();
    final budget =
        NatTestProtocol.breakWaitBudget + NatTestProtocol.reconnectBudget;
    while (!ended.isCompleted) {
      if (sw.elapsed > budget) {
        throw StateError(
          'survivor never ended the exchange within ${budget.inSeconds}s',
        );
      }
      await _pump.sendOne();
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    return 'peer-restart localBeatsSent=${_pump.sentCount} '
        '(rejoinTimeMs measured by the survivor)';
  }

  /// Re-rendezvous and pump until [postReconnectHeartbeats] fresh acks arrive,
  /// returning the milliseconds spent re-establishing the connection.
  Future<int> _reRendezvousAndResume(String label) async {
    // long-outage keeps this side's peer offline past the whole outage, so
    // mirror the survivor's extended budget instead of the plain 5 min one —
    // otherwise the initiator abandons the re-dial long before the peer can
    // possibly return (the asymmetry that left peer-a timing out at 0:05:00).
    final budget = NatReconnectProtocol.reconnectBudgetFor(scenario);
    final sw = Stopwatch()..start();
    await rendezvous(_orc, _peer, tag: tag, budget: budget)
        .timeout(budget + const Duration(seconds: 30));
    final ms = sw.elapsedMilliseconds;
    final baseline = _pump.ackedCount;
    await _pump.pumpUntil(
      () =>
          _pump.ackedCount >=
          baseline + NatReconnectProtocol.postReconnectHeartbeats,
      budget: NatTestProtocol.reconnectBudget,
      what: '$label resume',
    );
    return ms;
  }
}
