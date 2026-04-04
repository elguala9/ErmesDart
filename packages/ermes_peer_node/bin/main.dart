import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signaling_contract_sdk/signaling_contract_sdk.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

// Import storage initialization
import 'package:ermes_storage/src/initial/initial_point_messages.dart';

Future<void> main() async {
  // Load environment variables
  final myPrivateKey = _getEnv('MY_PRIVATE_KEY');
  final myAddress = _getEnv('MY_ADDRESS');
  final remoteAddress = _getEnv('REMOTE_ADDRESS');
  final ganacheUrl = _getEnv('GANACHE_URL', 'http://localhost:9545');
  final contractAddress = _getEnv('CONTRACT_ADDRESS', '0x5FbDB2315678afecb367f032d93F642f64180aa3');
  final stunServer = _getEnv('STUN_SERVER', 'localhost');
  final stunPort = int.parse(_getEnv('STUN_PORT', '19302'));
  final isInitiator = _getEnv('IS_INITIATOR', 'false').toLowerCase() == 'true';
  final messageCount = int.parse(_getEnv('MESSAGE_COUNT', '5'));
  final peerName = _getEnv('PEER_NAME', 'Peer');

  print('[$peerName] Starting peer node...');
  print('[$peerName] My address: $myAddress');
  print('[$peerName] Remote address: $remoteAddress');
  print('[$peerName] STUN server: $stunServer:$stunPort');
  print('[$peerName] Ganache URL: $ganacheUrl');

  try {
    // Initialize storage singleton (required by OrcErmes)
    print('[$peerName] Initializing storage singleton...');
    initialPointErmesStorage();
    print('[$peerName] Storage singleton initialized');

    // Step 1: Connect to Ganache via Web3Client
    print('[$peerName] Connecting to Ganache at $ganacheUrl...');
    final client = Web3Client(ganacheUrl, http.Client());

    // Step 2: Connect to the SignalingContract
    print('[$peerName] Connecting to SignalingContract at $contractAddress...');
    final credentials = EthPrivateKey.fromHex(myPrivateKey);
    final contract = await SignalingContract.connectWithClient(
      client: client,
      contractAddress: EthereumAddress.fromHex(contractAddress),
      credentials: credentials,
    );
    print('[$peerName] Connected to contract');

    // Step 3: Create OrcErmes with ForTesting factory (handles STUN initialization properly)
    print('[$peerName] Creating OrcErmes with ForTesting factory...');
    final orc = await OrcErmesAdvancedFactory.createForTesting(
      contract: contract,
      accountId: myAddress,
      enableEncryption: true,
    );
    print('[$peerName] OrcErmes created');

    // Step 4: Get the STUN handler to perform STUN request
    print('[$peerName] Accessing STUN handler for STUN request...');
    // Wait for STUN server to be ready
    await Future<void>.delayed(const Duration(seconds: 2));

    // The ForTesting factory initializes the singleton, so we can now access it
    final stunHandler = StunShspHandlerSingleton.instance;

    // Retry logic for STUN request with exponential backoff
    dynamic stunResponse;
    int stunAttempts = 0;
    int delayMs = 500;
    while (stunResponse == null && stunAttempts < 10) {
      try {
        stunResponse = await stunHandler.performStunRequest();
      } catch (e) {
        stunAttempts++;
        print('[$peerName] STUN attempt $stunAttempts failed: $e');
        if (stunAttempts < 10) {
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          delayMs = (delayMs * 1.5).toInt();
        }
      }
    }

    // Fallback to container hostname if STUN fails (for Docker testing)
    // Resolve container hostname to IP address
    if (stunResponse == null) {
      print('[$peerName] STUN failed, using container hostname fallback');
      final peerHostname = myAddress == '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
          ? 'peer-alice'  // Alice's container hostname
          : 'peer-bob';   // Bob's container hostname

      try {
        final addresses = await InternetAddress.lookup(peerHostname);
        if (addresses.isNotEmpty) {
          final ipAddress = addresses.first.address;
          stunResponse = _FallbackStunResponse(ipAddress, 9000);
          print('[$peerName] Resolved $peerHostname to $ipAddress');
        } else {
          throw Exception('Failed to resolve $peerHostname: no addresses found');
        }
      } catch (e) {
        print('[$peerName] Hostname resolution failed, using 127.0.0.1 fallback: $e');
        stunResponse = _FallbackStunResponse('127.0.0.1', 9000);
      }
    }
    print('[$peerName] Using address: ${stunResponse.publicIp}:${stunResponse.publicPort}');

    // Step 5: Create and post local signal to blockchain
    print('[$peerName] Creating and posting signal to blockchain...');
    final signalingServer = ErmesSignalingServer(
      contract: contract,
      accountId: myAddress,
    );

    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final mySignal = SignalErmes(
      publicKey: '',
      ipv4: stunResponse.publicIp,
      ipv4Port: stunResponse.publicPort.toString(),
      ipv6: '',
      ipv6Port: '',
      epochTimestampStartConversation: now,
      epochTimestampExpireConversation: now + 600,
    );

    await signalingServer.setSignal(mySignal);
    print('[$peerName] Signal posted: ${stunResponse.publicIp}:${stunResponse.publicPort}');

    // Step 6: Wait for remote peer's signal (polling with retry)
    print('[$peerName] Waiting for remote peer signal...');
    SignalErmes? remoteSignal;
    int attempts = 0;
    int maxAttempts = 60; // Increased from 30 to 60 for better resilience
    while (remoteSignal == null || remoteSignal.isExpired()) {
      attempts++;
      if (attempts > maxAttempts) {
        throw Exception('[$peerName] Timeout waiting for remote peer signal after $maxAttempts attempts');
      }
      try {
        remoteSignal = await signalingServer.getSignal(remoteAddress);
        if (remoteSignal == null || remoteSignal.isExpired()) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        // Retry on any error (gzip format issues, missing data, etc.)
        // Give blockchain time to propagate or stabilize state
        print('[$peerName] Attempt $attempts/$maxAttempts failed: $e');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    print('[$peerName] Remote signal received: ${remoteSignal.ipv4}:${remoteSignal.ipv4Port}');

    // Step 7: Open connection to remote peer
    print('[$peerName] Opening connection to $remoteAddress...');
    await orc.openConnection(remoteAddress);
    print('[$peerName] Connection opened!');

    // Step 8: Register message handler
    print('[$peerName] Registering message handler...');
    final receivedMessages = <String>[];
    orc.onMessage((data, from) {
      final message = String.fromCharCodes(data);
      print('[$peerName] Message from $from: $message');
      receivedMessages.add(message);
    });

    // Step 9: Send messages if initiator
    if (isInitiator) {
      print('[$peerName] Sending $messageCount messages to $remoteAddress...');
      for (int i = 0; i < messageCount; i++) {
        final msg = '[$peerName] Message $i: ${DateTime.now()}';
        final data = Uint8List.fromList(msg.codeUnits);
        await orc.send(data, remoteAddress);
        print('[$peerName] Sent message $i');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    // Step 10: Keep alive for 30 seconds to receive messages
    print('[$peerName] Waiting for messages (30 seconds)...');
    await Future<void>.delayed(const Duration(seconds: 30));

    print('[$peerName] Received ${receivedMessages.length} messages');
    print('[$peerName] Cleaning up...');

    await orc.destroy();
    await client.dispose();

    print('[$peerName] Done!');
  } catch (e, st) {
    print('[$peerName] Error: $e');
    print('[$peerName] Stack trace: $st');
    exit(1);
  }

  exit(0);
}

String _getEnv(String key, [String? defaultValue]) {
  final value = Platform.environment[key] ?? '';
  if (value.isEmpty && defaultValue == null) {
    throw Exception('Environment variable $key is required');
  }
  return value.isEmpty ? (defaultValue ?? '') : value;
}

/// Fallback STUN response for Docker testing
class _FallbackStunResponse {
  final String publicIp;
  final int publicPort;

  _FallbackStunResponse(this.publicIp, this.publicPort);
}
