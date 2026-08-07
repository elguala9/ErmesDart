import 'dart:io';

import '../bootstrap/nat_test_protocol.dart';

/// Raw `NAT_SCENARIO` value selecting the test variant, or null when the
/// environment leaves it unset (the default one-shot plaintext burst).
String? currentScenario() => Platform.environment['NAT_SCENARIO'];

/// True when this process should run the sustained network-change variant
/// (selected with `NAT_SCENARIO=network-change`) instead of the default
/// one-shot burst. Wired into compose for both peers; harmless elsewhere.
bool isNetworkChangeScenario() =>
    currentScenario() == NatTestProtocol.networkChangeScenario;

/// True for `NAT_SCENARIO=encrypted`: ECDH handshake + encrypted burst.
bool isEncryptedScenario() =>
    currentScenario() == NatTestProtocol.encryptedScenario;

/// True for `NAT_SCENARIO=rekey`: encrypted heartbeat with a mid-session
/// symmetric-key rotation.
bool isRekeyScenario() => currentScenario() == NatTestProtocol.rekeyScenario;

/// True for `NAT_SCENARIO=signal-cipher`: encryption bootstrapped purely from
/// the ECDH public key carried in the signal (no in-band cipher handshake).
bool isSignalCipherScenario() =>
    currentScenario() == NatTestProtocol.signalCipherScenario;

/// Outcome of a single network-change run, measured on the initiator: how long
/// the exchange was interrupted and how many heartbeats never made it across.
class ReconnectMetrics {
  /// Creates the metrics from the measured [outage], [messagesLost], and
  /// [messagesSent].
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
