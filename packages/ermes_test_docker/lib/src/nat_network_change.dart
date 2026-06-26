import 'dart:io';

import 'nat_test_protocol.dart';

/// True when this process should run the sustained network-change variant
/// (selected with `NAT_SCENARIO=network-change`) instead of the default
/// one-shot burst. Wired into compose for both peers; harmless elsewhere.
bool isNetworkChangeScenario() =>
    Platform.environment['NAT_SCENARIO'] ==
    NatTestProtocol.networkChangeScenario;

/// Outcome of a single network-change run, measured on the initiator: how long
/// the exchange was interrupted and how many heartbeats never made it across.
class ReconnectMetrics {
  const ReconnectMetrics({
    required this.outage,
    required this.messagesLost,
    required this.messagesSent,
  });

  /// Time from the last acknowledged heartbeat before the break to the first
  /// acknowledged heartbeat after the core re-rendezvoused.
  final Duration outage;

  /// Heartbeats sent during the outage that were never acknowledged.
  final int messagesLost;

  /// Total heartbeats sent across the whole run.
  final int messagesSent;

  /// One-line, greppable summary for the test log.
  String describe() =>
      'reconnectTimeMs=${outage.inMilliseconds} '
      'messagesLost=$messagesLost/$messagesSent';
}
