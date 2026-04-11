import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signaling_contract_sdk/signaling_contract_sdk.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

// Import storage initialization
import 'package:ermes_storage/src/initial/initial_point_messages.dart';

// ============================================================================
// CONFIG DATA CLASSES
// ============================================================================

class NetworkConfig {
  final String ganacheUrl;
  final String contractAddress;
  final String stunServer;
  final int stunPort;
  final int ganacheRetryCount;
  final int ganacheRetryDelaySeconds;
  final int postConnectionDelaySeconds;
  final int messageIntervalMs;
  final int keepaliveSeconds;

  NetworkConfig.fromJson(Map<String, dynamic> json)
      : ganacheUrl = json['ganache_url'] as String,
        contractAddress = json['contract_address'] as String,
        stunServer = json['stun_server'] as String,
        stunPort = json['stun_port'] as int,
        ganacheRetryCount = (json['ganache_retry_count'] as int?) ?? 30,
        ganacheRetryDelaySeconds = (json['ganache_retry_delay_seconds'] as int?) ?? 2,
        postConnectionDelaySeconds = (json['post_connection_delay_seconds'] as int?) ?? 2,
        messageIntervalMs = (json['message_interval_ms'] as int?) ?? 500,
        keepaliveSeconds = (json['keepalive_seconds'] as int?) ?? 60;
}

class PeerConfig {
  final String name;
  final String address; // lowercase
  final String privateKey;
  final int shspPort;

  PeerConfig.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        address = (json['address'] as String).toLowerCase(),
        privateKey = json['private_key'] as String,
        shspPort = json['shsp_port'] as int;
}

class MessageScenario {
  final String id;
  final String from; // lowercase
  final String to; // lowercase
  final String content;
  final int sequence;

  MessageScenario.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        from = (json['from'] as String).toLowerCase(),
        to = (json['to'] as String).toLowerCase(),
        content = json['content'] as String,
        sequence = json['sequence'] as int;

  Map<String, dynamic> toWireJson({int? sentAtMs}) => {
        'id': id,
        'from': from,
        'to': to,
        'content': content,
        'sequence': sequence,
        if (sentAtMs != null) 'sent_at_ms': sentAtMs,
      };
}

class TestConfig {
  final NetworkConfig network;
  final List<PeerConfig> peers;
  final List<MessageScenario> scenarios;

  TestConfig({
    required this.network,
    required this.peers,
    required this.scenarios,
  });

  TestConfig.fromJson(Map<String, dynamic> json)
      : network = NetworkConfig.fromJson(json['network'] as Map<String, dynamic>),
        peers = (json['peers'] as List<dynamic>)
            .map((p) => PeerConfig.fromJson(p as Map<String, dynamic>))
            .toList(),
        scenarios = (json['scenarios'] as List<dynamic>)
            .map((s) => MessageScenario.fromJson(s as Map<String, dynamic>))
            .toList();
}

// ============================================================================
// HELPERS
// ============================================================================

TestConfig loadConfig(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw Exception('Config file not found: $path');
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return TestConfig.fromJson(json);
}

String _getEnv(String key, [String? defaultValue]) {
  final value = Platform.environment[key] ?? '';
  if (value.isEmpty && defaultValue == null) {
    throw Exception('Environment variable $key is required');
  }
  return value.isEmpty ? (defaultValue ?? '') : value;
}

Future<Web3Client> _connectToGanache(NetworkConfig net, String peerName) async {
  Web3Client? client;
  int attempts = 0;
  while (client == null && attempts < net.ganacheRetryCount) {
    try {
      final c = Web3Client(net.ganacheUrl, http.Client());
      await c.getChainId();
      client = c;
      print('[$peerName] Connected to Ganache');
    } catch (e) {
      attempts++;
      print('[$peerName] Ganache attempt $attempts/${net.ganacheRetryCount} failed: $e');
      if (attempts < net.ganacheRetryCount) {
        await Future<void>.delayed(Duration(seconds: net.ganacheRetryDelaySeconds));
      }
    }
  }
  if (client == null) {
    throw Exception('[$peerName] Failed to connect to Ganache after ${net.ganacheRetryCount} attempts');
  }
  return client;
}

// ============================================================================
// LATENCY STATS
// ============================================================================

class LatencyStats {
  final int count;
  final double minMs;
  final double maxMs;
  final double avgMs;
  final double p95Ms;

  LatencyStats({
    required this.count,
    required this.minMs,
    required this.maxMs,
    required this.avgMs,
    required this.p95Ms,
  });

  static LatencyStats fromSamples(List<int> samples) {
    if (samples.isEmpty) {
      throw ArgumentError('Cannot compute stats from empty samples');
    }

    final sorted = List<int>.from(samples)..sort();
    final minMs = sorted.first.toDouble();
    final maxMs = sorted.last.toDouble();
    final avgMs = samples.fold<int>(0, (a, b) => a + b) / samples.length;

    // 95th percentile
    final p95Index = ((sorted.length - 1) * 0.95).ceil();
    final p95Ms = sorted[p95Index].toDouble();

    return LatencyStats(
      count: samples.length,
      minMs: minMs,
      maxMs: maxMs,
      avgMs: avgMs,
      p95Ms: p95Ms,
    );
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'min_ms': minMs,
        'max_ms': maxMs,
        'avg_ms': avgMs,
        'p95_ms': p95Ms,
      };
}

// ============================================================================
// RESULTS SAVER
// ============================================================================

class TestResult {
  final String peerName;
  final String peerAddress;
  final int expectedMessages;
  final int receivedMessages;
  final List<String> missingMessages;
  final List<String> verificationErrors;
  final LatencyStats? latencyStats;
  final bool success;
  final DateTime timestamp;

  TestResult({
    required this.peerName,
    required this.peerAddress,
    required this.expectedMessages,
    required this.receivedMessages,
    required this.missingMessages,
    required this.verificationErrors,
    required this.success,
    this.latencyStats,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'peer_name': peerName,
        'peer_address': peerAddress,
        'expected_messages': expectedMessages,
        'received_messages': receivedMessages,
        'missing_messages': missingMessages,
        'verification_errors': verificationErrors,
        'success': success,
        'timestamp': timestamp.toIso8601String(),
        if (latencyStats != null) 'latency_stats': latencyStats!.toJson(),
      };
}

Future<void> _saveTestResult(TestResult result) async {
  try {
    final outputDir = Directory('/app/results');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final resultFile = File('/app/results/${result.peerName.toLowerCase()}_result.json');
    await resultFile.writeAsString(jsonEncode(result.toJson()));
    print('[${result.peerName}] Test result saved to ${resultFile.path}');
  } catch (e) {
    print('[${result.peerName}] Warning: Could not save test result: $e');
  }
}

// ============================================================================
// MAIN
// ============================================================================

Future<void> main() async {
  // 1. Identify self via env var
  final myAddress = _getEnv('MY_ADDRESS').toLowerCase();
  final configPath = _getEnv('CONFIG_PATH', '/app/config/test_config.json');

  // 2. Load JSON config
  final config = loadConfig(configPath);
  final net = config.network;

  // 3. Find own PeerConfig entry
  final self = config.peers.firstWhere(
    (p) => p.address == myAddress,
    orElse: () => throw Exception('MY_ADDRESS $myAddress not found in config peers'),
  );
  final peerName = self.name;

  print('[$peerName] Starting — address: $myAddress');

  try {
    // 4. Initialize storage singleton
    initialPointErmesStorage();

    // 5. Connect to Ganache with retry loop
    final client = await _connectToGanache(net, peerName);

    // 6. Connect to SignalingContract
    final credentials = EthPrivateKey.fromHex(self.privateKey);
    final contract = await SignalingContract.connectWithClient(
      client: client,
      contractAddress: EthereumAddress.fromHex(net.contractAddress),
      credentials: credentials,
    );

    // 7. Create OrcErmes
    final orc = await OrcErmesAdvancedFactory.createWithCustomStun(
      contract: contract,
      accountId: myAddress,
      stunServer: net.stunServer,
      stunPort: net.stunPort,
      localShspPort: self.shspPort,
      enableEncryption: true,
    );

    // 8. Compute remote peers (all peers except self)
    final remotePeers = config.peers.where((p) => p.address != myAddress).toList();

    // 9. Build expected-receive set
    final expectedMessages = config.scenarios
        .where((s) => s.to == myAddress)
        .map((s) => s.id)
        .toSet();
    final receivedIds = <String>{};
    final verificationErrors = <String>[];
    final latencySamples = <int>[];

    // 10. Register message handler BEFORE opening connections
    await orc.onMessage((data, fromAddress) {
      try {
        final receivedAtMs = DateTime.now().millisecondsSinceEpoch;
        final jsonStr = utf8.decode(data);
        final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
        final scenario = MessageScenario.fromJson(payload);

        // Verify: 'to' field must match own address
        if (scenario.to != myAddress) {
          verificationErrors.add(
            '[$peerName] MISDIRECTED msg id=${scenario.id}: '
            'to=${scenario.to} but I am $myAddress',
          );
          return;
        }

        // Verify: 'from' field must match the OrcErmes sender address
        final senderAddress = (fromAddress as String).toLowerCase();
        if (scenario.from != senderAddress) {
          verificationErrors.add(
            '[$peerName] SPOOFED msg id=${scenario.id}: '
            'payload.from=${scenario.from} but actual sender=$senderAddress',
          );
          return;
        }

        // Track latency if timestamp is available
        final sentAt = payload['sent_at_ms'] as int?;
        if (sentAt != null) {
          final latency = receivedAtMs - sentAt;
          latencySamples.add(latency);
        }

        print('[$peerName] ✅ RECEIVED id=${scenario.id} '
            'from=${scenario.from} seq=${scenario.sequence}: ${scenario.content}');
        receivedIds.add(scenario.id);
      } catch (e) {
        verificationErrors.add('[$peerName] BAD PAYLOAD from $fromAddress: $e');
      }
    });

    // 11. Open connections to all remote peers (sequentially with stagger to avoid Ganache nonce conflicts)
    print('[$peerName] Opening ${remotePeers.length} connections...');
    for (final remote in remotePeers) {
      print('[$peerName] Connecting to ${remote.name} (${remote.address})...');
      await orc.openConnection(remote.address);
      print('[$peerName] Connected to ${remote.name}');
      if (remotePeers.indexOf(remote) < remotePeers.length - 1) {
        // Add stagger delay between connections to avoid Ganache nonce conflicts
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    // 12. Wait for handshake stabilization
    print('[$peerName] Waiting ${net.postConnectionDelaySeconds}s for handshakes...');
    await Future<void>.delayed(Duration(seconds: net.postConnectionDelaySeconds));

    // 13. Send all outbound scenarios
    final outboundScenarios = config.scenarios.where((s) => s.from == myAddress).toList();

    print('[$peerName] Sending ${outboundScenarios.length} messages...');
    for (final scenario in outboundScenarios) {
      try {
        final sentAtMs = DateTime.now().millisecondsSinceEpoch;
        final payload = utf8.encode(jsonEncode(scenario.toWireJson(sentAtMs: sentAtMs)));
        await orc.send(Uint8List.fromList(payload), scenario.to);
        print('[$peerName] ✅ SENT id=${scenario.id} to=${scenario.to} seq=${scenario.sequence}');
        await Future<void>.delayed(Duration(milliseconds: net.messageIntervalMs));
      } catch (e) {
        print('[$peerName] ERROR sending id=${scenario.id}: $e');
        verificationErrors.add('[$peerName] SEND FAILED id=${scenario.id}: $e');
      }
    }

    // 14. Keep alive until all expected messages received or timeout
    print('[$peerName] Waiting up to ${net.keepaliveSeconds}s for inbound messages...');
    final deadline = DateTime.now().add(Duration(seconds: net.keepaliveSeconds));
    while (DateTime.now().isBefore(deadline)) {
      if (receivedIds.containsAll(expectedMessages)) break;
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    // 15. Verification summary
    final missing = expectedMessages.difference(receivedIds);
    print('[$peerName] === VERIFICATION SUMMARY ===');
    print('[$peerName] Expected: ${expectedMessages.length} messages');
    print('[$peerName] Received: ${receivedIds.length} messages');
    if (missing.isNotEmpty) {
      print('[$peerName] MISSING: $missing');
    }
    if (verificationErrors.isNotEmpty) {
      for (final err in verificationErrors) {
        print(err);
      }
    }

    // 16. Save test results to JSON
    final latencyStats = latencySamples.isNotEmpty ? LatencyStats.fromSamples(latencySamples) : null;
    final testResult = TestResult(
      peerName: peerName,
      peerAddress: myAddress,
      expectedMessages: expectedMessages.length,
      receivedMessages: receivedIds.length,
      missingMessages: missing.toList(),
      verificationErrors: verificationErrors,
      success: missing.isEmpty && verificationErrors.isEmpty,
      latencyStats: latencyStats,
    );
    await _saveTestResult(testResult);

    // 17. Cleanup
    await orc.destroy();
    await client.dispose();

    // 18. Exit code
    final success = missing.isEmpty && verificationErrors.isEmpty;
    print('[$peerName] ${success ? "✅ ALL CHECKS PASSED" : "❌ SOME CHECKS FAILED"}');
    exit(success ? 0 : 1);
  } catch (e, st) {
    print('[$peerName] Fatal error: $e');
    print('[$peerName] Stack trace: $st');
    exit(1);
  }
}
