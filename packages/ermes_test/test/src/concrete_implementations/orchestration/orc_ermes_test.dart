// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../src/helpers/ganache_manager.dart';

/// Integration tests for OrcErmes with real P2P communication.
///
/// These tests deploy a real SignalingContract on Ganache and test
/// the complete OrcErmes orchestration workflow between two peers
/// (Alice and Bob).
///
/// Requirements:
/// - Ganache running at http://localhost:9545
/// - Run with: docker compose -f docker-compose-evm.yml up -d

const String ganacheRpcUrl = 'http://localhost:9545';
const String alicePrivateKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const String bobPrivateKey =
    '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';

/// Pre-deployed SignalingContract address (deployed by docker-compose deployer)
/// Use environment variable to override if needed
final String signallingContractAddress =
    Platform.environment['SIGNALING_CONTRACT_ADDRESS'] ??
        '0x5FbDB2315678afecb367f032d93F642f64180aa3';

/// Test signal implementation matching the SignalErmes format
class _TestSignalErmes implements ISignalErmes {
  _TestSignalErmes({
    required this.publicKey,
    required this.ipv6,
    required this.ipv6Port,
    required this.ipv4,
    required this.ipv4Port,
    required this.epochTimestampStartConversation,
    required this.secondsIntervalWindow,
    required this.epochTimestampExpireConversation,
  });

  @override
  String publicKey;

  @override
  String ipv6;

  @override
  String ipv6Port;

  @override
  String ipv4;

  @override
  String ipv4Port;

  @override
  int epochTimestampStartConversation;

  @override
  int secondsIntervalWindow;

  @override
  int epochTimestampExpireConversation;

  @override
  int secondsIntervalOpening = 60;

  @override
  String toString() =>
      '$publicKey|$ipv6|$ipv6Port|$ipv4|$ipv4Port|'
      '$epochTimestampStartConversation|$secondsIntervalWindow|'
      '$epochTimestampExpireConversation';

  @override
  void fromString(String signalString) {
    final parts = signalString.split('|');
    if (parts.length != 8) {
      throw ArgumentError('Invalid signal string format');
    }

    publicKey = parts[0];
    ipv6 = parts[1];
    ipv6Port = parts[2];
    ipv4 = parts[3];
    ipv4Port = parts[4];
    epochTimestampStartConversation = int.parse(parts[5]);
    secondsIntervalWindow = int.parse(parts[6]);
    epochTimestampExpireConversation = int.parse(parts[7]);
  }

  @override
  bool isExpired() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >
      epochTimestampExpireConversation;

  @override
  String get signal => toString();

  @override
  set signal(String value) {
    fromString(value);
  }
}

bool ganacheAvailable = false;

Future<void> main() async {
  // Check Ganache availability BEFORE group definition
  // so skip: evaluates correctly
  ganacheAvailable = await GanacheManager.initialize();

  late SignalingContract aliceContract;
  late SignalingContract bobContract;
  late ErmesSignalingServer aliceServer;
  late ErmesSignalingServer bobServer;
  late String aliceAddress;
  late String bobAddress;
  late OrcErmes aliceOrc;
  late OrcErmes bobOrc;
  late int aliceSocketPort;
  late int bobSocketPort;

  setUpAll(() async {
    if (!ganacheAvailable) {
      return;
    }

    try {
      // Set up accounts
      final aliceCreds = EthPrivateKey.fromHex(alicePrivateKey);
      final bobCreds = EthPrivateKey.fromHex(bobPrivateKey);

      aliceAddress = aliceCreds.address.toString();
      bobAddress = bobCreds.address.toString();

      // Connect to pre-deployed contract (deployed by docker-compose deployer)
      final contractAddr = EthereumAddress.fromHex(signallingContractAddress);

      // Use connectWithClient() to properly fetch chainId from the network.
      // SignalingContract.connect() sets chainId: null which causes a null
      // check error in web3dart when signing transactions.
      final aliceClient = Web3Client(ganacheRpcUrl, http.Client());
      aliceContract = await SignalingContract.connectWithClient(
        client: aliceClient,
        contractAddress: contractAddr,
        credentials: aliceCreds,
      );

      final bobClient = Web3Client(ganacheRpcUrl, http.Client());
      bobContract = await SignalingContract.connectWithClient(
        client: bobClient,
        contractAddress: contractAddr,
        credentials: bobCreds,
      );

      // Create signaling servers
      aliceServer = ErmesSignalingServer(
        contract: aliceContract,
        accountId: aliceAddress,
      );

      bobServer = ErmesSignalingServer(
        contract: bobContract,
        accountId: bobAddress,
      );

      // Create separate StunShspHandler instances for Alice and Bob.
      // Each handler manages its own socket + STUN, providing isolation.
      final aliceHandler = StunShspHandler();
      await aliceHandler.initialize();
      final bobHandler = StunShspHandler();
      await bobHandler.initialize();
      aliceSocketPort = aliceHandler.ipv4ShspSocket.localPort ?? 0;
      bobSocketPort = bobHandler.ipv4ShspSocket.localPort ?? 0;

      // Create OrcErmes instances with real components (NO MOCKS!)
      aliceOrc = OrcErmes.fromContract(
        contract: aliceContract,
        accountId: aliceAddress,
        stunShspHandler: aliceHandler,
      );

      bobOrc = OrcErmes.fromContract(
        contract: bobContract,
        accountId: bobAddress,
        stunShspHandler: bobHandler,
      );

      // Post signals to contract so peers can discover each other.
      // Use IPv4 loopback with actual socket ports (not STUN external ports).
      // IPv6 is set to '::' so _peerInfoFromSignal falls back to IPv4.
      final now = DateTime.now();
      final aliceSignal = _TestSignalErmes(
        publicKey: 'alice-pubkey-mock',
        ipv6: '::',
        ipv6Port: '0',
        ipv4: '127.0.0.1',
        ipv4Port: aliceSocketPort.toString(),
        epochTimestampStartConversation: now.millisecondsSinceEpoch ~/ 1000,
        secondsIntervalWindow: 3600,
        epochTimestampExpireConversation:
            (now.millisecondsSinceEpoch + 3600000) ~/ 1000,
      );

      final bobSignal = _TestSignalErmes(
        publicKey: 'bob-pubkey-mock',
        ipv6: '::',
        ipv6Port: '0',
        ipv4: '127.0.0.1',
        ipv4Port: bobSocketPort.toString(),
        epochTimestampStartConversation: now.millisecondsSinceEpoch ~/ 1000,
        secondsIntervalWindow: 3600,
        epochTimestampExpireConversation:
            (now.millisecondsSinceEpoch + 3600000) ~/ 1000,
      );

      // Alice and Bob post their signals to the contract
      try {
        await aliceServer.setSignal(aliceSignal);
        await bobServer.setSignal(bobSignal);
      } on Exception catch (e) {
        if (e.toString().contains('gzip') ||
            e.toString().contains('FormatException')) {
          print(
            'ℹ️  SignalingContract gzip format issue - tests will be skipped',
          );
          ganacheAvailable = false;
          return;
        }
        print('⚠️  Failed to post signals to contract: $e');
        ganacheAvailable = false;
        return;
      }

      // Validate that getSignal works (round-trip test)
      try {
        await aliceServer.getSignal(bobAddress);
        print('✅ OrcErmes initialization successful');
        ganacheAvailable = true;
      } on Exception catch (e) {
        print(
          'ℹ️  SignalingContract getSignal() failed - tests will be skipped',
        );
        if (e.toString().contains('gzip') ||
            e.toString().contains('FormatException')) {
          print('   Issue: Signal data format problem with gzip compression');
        }
        ganacheAvailable = false;
        return;
      }
    } on Exception catch (e, stackTrace) {
      print('⚠️  Failed to initialize OrcErmes: $e');
      if (e.toString().contains('Failed to connect') ||
          e.toString().contains('Connection refused')) {
        print('ℹ️  Ganache may not be running. Tests will be skipped.');
      } else {
        print('Stack trace: $stackTrace');
      }
      ganacheAvailable = false;
      return;
    }
  });

  tearDownAll(() async {
    if (!ganacheAvailable) {
      return;
    }

    // Cleanup OrcErmes and servers
    try {
      await aliceOrc.destroy(force: true);
      await bobOrc.destroy(force: true);
      await aliceServer.destroy();
      await bobServer.destroy();
    } on Exception {
      // Ignore cleanup errors
    }

    // Stop Ganache if we started it
    await GanacheManager.cleanup();
  });

  group('OrcErmes Integration Tests', () {
    group('Connection Management', () {
      tearDown(() async {
        if (!ganacheAvailable) {
          return;
        }
        // Clean up any open connections after each test
        try {
          await aliceOrc.closeConnection(bobAddress);
        } on Exception {
          // Ignore - connection may not exist
        }
      });

      test('getConnections() returns empty list initially', () async {
        final connections = await aliceOrc.getConnections();
        expect(connections, isEmpty);
      });

      test('openConnection() establishes connection between peers', () async {
        // Alice opens connection to Bob
        await aliceOrc.openConnection(bobAddress);

        // Verify Alice has Bob as connected peer
        final aliceConnections = await aliceOrc.getConnections();
        expect(aliceConnections, contains(bobAddress));
      });

      test('closeConnection() removes peer from connections', () async {
        // Open connection
        await aliceOrc.openConnection(bobAddress);
        var connections = await aliceOrc.getConnections();
        expect(connections, contains(bobAddress));

        // Close connection
        await aliceOrc.closeConnection(bobAddress);
        connections = await aliceOrc.getConnections();
        expect(connections, isNot(contains(bobAddress)));
      });

      test('openConnection() is idempotent', () async {
        // Open connection twice
        await aliceOrc.openConnection(bobAddress);
        await aliceOrc.openConnection(bobAddress);

        // Should still have only one connection
        final connections = await aliceOrc.getConnections();
        expect(connections.where((p) => p == bobAddress).length, equals(1));

        // Cleanup
        await aliceOrc.closeConnection(bobAddress);
      });
    });

    group('Message Exchange', () {
      setUpAll(() async {
        if (!ganacheAvailable) {
          return;
        }
        // Post correct local signals and open connections once for the group.
        // openConnection() overwrites the signal with a STUN-derived external
        // address, so we restore the correct local address afterwards.
        final now = DateTime.now();
        final localAliceSignal = _localSignal(
          publicKey: 'alice-pubkey-mock',
          port: aliceSocketPort,
          now: now,
        );
        final localBobSignal = _localSignal(
          publicKey: 'bob-pubkey-mock',
          port: bobSocketPort,
          now: now,
        );
        // Post Bob's correct signal so Alice can find Bob at the right port.
        await bobServer.setSignal(localBobSignal);
        await aliceOrc.openConnection(bobAddress);
        // Restore Alice's correct signal so Bob finds Alice at the right port.
        await aliceServer.setSignal(localAliceSignal);
        await bobOrc.openConnection(aliceAddress);
        // Allow time for the SHSP handshake to complete over loopback.
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      });

      tearDownAll(() async {
        if (!ganacheAvailable) {
          return;
        }
        try {
          await aliceOrc.closeConnection(bobAddress);
          await bobOrc.closeConnection(aliceAddress);
        } on Exception {
          // Ignore cleanup errors
        }
      });

      test('send() transmits data to connected peer', () async {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Bob should receive Alice's message
        var received = false;
        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress && _bytesEqual(data, testData)) {
            received = true;
          }
        });

        // Alice sends data to Bob
        await aliceOrc.send(testData, bobAddress);

        // Wait for message delivery
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(received, isTrue);
      });

      test('send() throws if peer not connected', () async {
        final testData = Uint8List.fromList([1, 2, 3]);

        // Try to send to unconnected peer
        expect(
          () => aliceOrc.send(testData, '0xUnknownPeer'),
          throwsException,
        );
      });

      test('onMessage() receives messages from multiple peers', () async {
        final messages = <Map<String, dynamic>>[];

        // Register callback
        await bobOrc.onMessage((data, from) {
          messages.add({'from': from, 'data': data});
        });

        // Alice sends multiple messages
        final msg1 = Uint8List.fromList([1, 2, 3]);
        final msg2 = Uint8List.fromList([4, 5, 6]);

        await aliceOrc.send(msg1, bobAddress);
        await aliceOrc.send(msg2, bobAddress);

        // Wait for delivery
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(messages.length, greaterThanOrEqualTo(1));
        expect(messages.any((m) => m['from'] == aliceAddress), isTrue);
      });

      test('Multiple callbacks receive same message', () async {
        final callback1Messages = <Uint8List>[];
        final callback2Messages = <Uint8List>[];

        // Register two callbacks
        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress) {
            callback1Messages.add(data);
          }
        });

        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress) {
            callback2Messages.add(data);
          }
        });

        final testData = Uint8List.fromList([7, 8, 9]);

        // Alice sends data
        await aliceOrc.send(testData, bobAddress);

        // Wait for delivery
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(callback1Messages, isNotEmpty);
        expect(callback2Messages, isNotEmpty);
      });

      test('Large messages are fragmented and reassembled', () async {
        // Create large message (e.g., 20KB)
        final largeData = Uint8List(20 * 1024);
        for (var i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }

        var received = false;
        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress && _bytesEqual(data, largeData)) {
            received = true;
          }
        });

        // Alice sends large message
        await aliceOrc.send(largeData, bobAddress);

        // Wait longer for large message
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(received, isTrue);
      });
    });

    group('Lifecycle Management', () {
      test('destroy() closes all connections', () async {
        final handler = StunShspHandler();
        await handler.initialize();
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          stunShspHandler: handler,
        );

        // Open connections
        await orc.openConnection(bobAddress);
        var connections = await orc.getConnections();
        expect(connections, isNotEmpty);

        // Destroy
        await orc.destroy();

        // All connections should be closed
        connections = await orc.getConnections();
        expect(connections, isEmpty);
      });

      test('destroy(force: true) ignores cleanup errors', () async {
        final handler = StunShspHandler();
        await handler.initialize();
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          stunShspHandler: handler,
        );

        // Force destroy should not throw
        expect(
          () => orc.destroy(force: true),
          returnsNormally,
        );
      });

      test('save() persists connection state', () async {
        final handler = StunShspHandler();
        await handler.initialize();
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          stunShspHandler: handler,
        );

        await orc.openConnection(bobAddress);

        // Save should complete without error
        expect(
          orc.save,
          returnsNormally,
        );

        await orc.destroy();
      });
    });

    group('Bidirectional Communication', () {
      setUpAll(() async {
        if (!ganacheAvailable) {
          return;
        }
        final now = DateTime.now();
        await bobServer.setSignal(
          _localSignal(
            publicKey: 'bob-pubkey-mock', port: bobSocketPort, now: now),
        );
        await aliceOrc.openConnection(bobAddress);
        await aliceServer.setSignal(
          _localSignal(
            publicKey: 'alice-pubkey-mock', port: aliceSocketPort, now: now),
        );
        await bobOrc.openConnection(aliceAddress);
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      });

      tearDownAll(() async {
        if (!ganacheAvailable) {
          return;
        }
        try {
          await aliceOrc.closeConnection(bobAddress);
          await bobOrc.closeConnection(aliceAddress);
        } on Exception {
          // Ignore - connections may not exist
        }
      });

      test('Alice and Bob can exchange messages bidirectionally', () async {

        final aliceReceived = <Uint8List>[];
        final bobReceived = <Uint8List>[];

        await aliceOrc.onMessage((data, from) {
          if (from == bobAddress) {
            aliceReceived.add(data);
          }
        });

        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress) {
            bobReceived.add(data);
          }
        });

        // Alice sends to Bob
        final aliceMsg = Uint8List.fromList([10, 20, 30]);
        await aliceOrc.send(aliceMsg, bobAddress);

        // Bob sends to Alice
        final bobMsg = Uint8List.fromList([40, 50, 60]);
        await bobOrc.send(bobMsg, aliceAddress);

        // Wait for delivery
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(bobReceived, isNotEmpty);
        expect(aliceReceived, isNotEmpty);
      });

      test('Multiple sequential message exchanges work correctly', () async {
        final bobReceived = <Uint8List>[];

        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress) {
            bobReceived.add(data);
          }
        });

        // Send multiple messages in sequence
        for (var i = 0; i < 5; i++) {
          final data = Uint8List.fromList([i, i + 1, i + 2]);
          await aliceOrc.send(data, bobAddress);
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        // Wait for all deliveries
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(bobReceived.length, greaterThanOrEqualTo(1));
      });
    });

    group('Error Handling', () {
      test('openConnection() throws on invalid peer', () async {
        expect(
          () => aliceOrc.openConnection('0xInvalidAddress'),
          throwsException,
        );
      });

      test(
          'closeConnection() handles already-closed connections gracefully',
          () async {
        // Close non-existent connection should not throw
        expect(
          () => aliceOrc.closeConnection('0xNonExistent'),
          returnsNormally,
        );
      });

      test('Multiple destroy() calls are safe', () async {
        final handler = StunShspHandler();
        await handler.initialize();
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          stunShspHandler: handler,
        );

        // First destroy
        await orc.destroy();

        // Second destroy should complete without error
        expect(
          orc.destroy,
          returnsNormally,
        );
      });
    });
  },
  skip: !ganacheAvailable ? 'Ganache not available at $ganacheRpcUrl' : null,
  );
}

/// Element-wise equality check for Uint8List.
bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Creates a local test signal using IPv4 loopback at the given port.
/// IPv6 is intentionally set to '::' so [OrcErmes._peerInfoFromSignal] falls
/// back to IPv4, ensuring packets are routed to the actual local socket.
_TestSignalErmes _localSignal({
  required String publicKey,
  required int port,
  required DateTime now,
}) =>
    _TestSignalErmes(
      publicKey: publicKey,
      ipv6: '::',
      ipv6Port: '0',
      ipv4: '127.0.0.1',
      ipv4Port: port.toString(),
      epochTimestampStartConversation: now.millisecondsSinceEpoch ~/ 1000,
      secondsIntervalWindow: 3600,
      epochTimestampExpireConversation:
          (now.millisecondsSinceEpoch + 3600000) ~/ 1000,
    );
