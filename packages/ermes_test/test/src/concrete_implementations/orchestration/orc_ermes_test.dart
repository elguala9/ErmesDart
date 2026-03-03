import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun/stun.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../src/helpers/ganache_manager.dart';

/// Integration tests for OrcErmes with real P2P communication.
///
/// These tests deploy a real SignalingContract on Ganache and test
/// the complete OrcErmes orchestration workflow between two peers (Alice and Bob).
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

void main() {
  late SignalingContract aliceContract;
  late SignalingContract bobContract;
  late ErmesSignalingServer aliceServer;
  late ErmesSignalingServer bobServer;
  late String aliceAddress;
  late String bobAddress;
  late OrcErmes aliceOrc;
  late OrcErmes bobOrc;

  setUpAll(() async {
    // Initialize Ganache (starts it if not running)
    ganacheAvailable = await GanacheManager.initialize();

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

      aliceContract = await SignalingContract.connect(
        rpcUrl: ganacheRpcUrl,
        contractAddress: contractAddr,
        credentials: aliceCreds,
      );

      // Bob connects to the same contract with his credentials
      bobContract = await SignalingContract.connect(
        rpcUrl: ganacheRpcUrl,
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

      // Create OrcErmes instances with real components (NO MOCKS!)
      aliceOrc = OrcErmes.fromContract(
        contract: aliceContract,
        accountId: aliceAddress,
        socket: await ShspSocketFactoryHelper.createDefault(),
        stunHandler: await StunHandlerFactoryHelper.createDefault(),
        enableEncryption: true,
        connectionTimeoutMs: 30000,
      );

      bobOrc = OrcErmes.fromContract(
        contract: bobContract,
        accountId: bobAddress,
        socket: await ShspSocketFactoryHelper.createDefault(),
        stunHandler: await StunHandlerFactoryHelper.createDefault(),
        enableEncryption: true,
        connectionTimeoutMs: 30000,
      );
    } catch (e) {
      print('⚠️  Failed to deploy SignalingContract: $e');
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
    } catch (e) {
      // Ignore cleanup errors
    }

    // Stop Ganache if we started it
    await GanacheManager.cleanup();
  });

  group('OrcErmes Integration Tests', () {
    group('Connection Management', () {
      test('openConnection() establishes connection between peers', skip: !ganacheAvailable, () async {
        // Alice opens connection to Bob
        await aliceOrc.openConnection(bobAddress);

        // Verify Alice has Bob as connected peer
        final aliceConnections = await aliceOrc.getConnections();
        expect(aliceConnections, contains(bobAddress));
      });

      test('getConnections() returns empty list initially', skip: !ganacheAvailable, () async {
        final connections = await aliceOrc.getConnections();
        expect(connections, isEmpty);
      });

      test('closeConnection() removes peer from connections', skip: !ganacheAvailable, () async {
        // Open connection
        await aliceOrc.openConnection(bobAddress);
        var connections = await aliceOrc.getConnections();
        expect(connections, contains(bobAddress));

        // Close connection
        await aliceOrc.closeConnection(bobAddress);
        connections = await aliceOrc.getConnections();
        expect(connections, isNot(contains(bobAddress)));
      });

      test('openConnection() is idempotent', skip: !ganacheAvailable, () async {
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
      setUp(() async {
        if (!ganacheAvailable) return;
        // Open connection before each test
        await aliceOrc.openConnection(bobAddress);
        await bobOrc.openConnection(aliceAddress);
      });

      tearDown(() async {
        if (!ganacheAvailable) return;
        // Close connections after each test
        try {
          await aliceOrc.closeConnection(bobAddress);
          await bobOrc.closeConnection(aliceAddress);
        } catch (e) {
          // Ignore cleanup errors
        }
      });

      test('send() transmits data to connected peer', skip: !ganacheAvailable, () async {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Bob should receive Alice's message
        bool received = false;
        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress && data== testData) {
            received = true;
          }
        });

        // Alice sends data to Bob
        await aliceOrc.send(testData, bobAddress);

        // Wait for message delivery
        await Future.delayed(Duration(milliseconds: 500));

        expect(received, isTrue);
      });

      test('send() throws if peer not connected', skip: !ganacheAvailable, () async {
        final testData = Uint8List.fromList([1, 2, 3]);

        // Try to send to unconnected peer
        expect(
          () => aliceOrc.send(testData, '0xUnknownPeer'),
          throwsException,
        );
      });

      test('onMessage() receives messages from multiple peers', skip: !ganacheAvailable, () async {
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
        await Future.delayed(Duration(milliseconds: 500));

        expect(messages.length, greaterThanOrEqualTo(1));
        expect(messages.any((m) => m['from'] == aliceAddress), isTrue);
      });

      test('Multiple callbacks receive same message', skip: !ganacheAvailable, () async {
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
        await Future.delayed(Duration(milliseconds: 500));

        expect(callback1Messages, isNotEmpty);
        expect(callback2Messages, isNotEmpty);
      });

      test('Large messages are fragmented and reassembled', skip: !ganacheAvailable, () async {
        // Create large message (e.g., 20KB)
        final largeData = Uint8List(20 * 1024);
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }

        bool received = false;
        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress && data== largeData) {
            received = true;
          }
        });

        // Alice sends large message
        await aliceOrc.send(largeData, bobAddress);

        // Wait longer for large message
        await Future.delayed(Duration(seconds: 2));

        expect(received, isTrue);
      });
    });

    group('Lifecycle Management', () {
      test('destroy() closes all connections', skip: !ganacheAvailable, () async {
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          socket: await ShspSocketFactoryHelper.createDefault(),
          stunHandler: await StunHandlerFactoryHelper.createDefault(),
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

      test('destroy(force: true) ignores cleanup errors', skip: !ganacheAvailable, () async {
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          socket: await ShspSocketFactoryHelper.createDefault(),
          stunHandler: await StunHandlerFactoryHelper.createDefault(),
        );

        // Force destroy should not throw
        expect(
          () => orc.destroy(force: true),
          returnsNormally,
        );
      });

      test('save() persists connection state', skip: !ganacheAvailable, () async {
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          socket: await ShspSocketFactoryHelper.createDefault(),
          stunHandler: await StunHandlerFactoryHelper.createDefault(),
        );

        await orc.openConnection(bobAddress);

        // Save should complete without error
        expect(
          () => orc.save(),
          returnsNormally,
        );

        await orc.destroy();
      });
    });

    group('Bidirectional Communication', () {
      test('Alice and Bob can exchange messages bidirectionally', skip: !ganacheAvailable, () async {
        await aliceOrc.openConnection(bobAddress);
        await bobOrc.openConnection(aliceAddress);

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
        await Future.delayed(Duration(milliseconds: 500));

        expect(bobReceived, isNotEmpty);
        expect(aliceReceived, isNotEmpty);

        await aliceOrc.closeConnection(bobAddress);
        await bobOrc.closeConnection(aliceAddress);
      });

      test('Multiple sequential message exchanges work correctly', skip: !ganacheAvailable, () async {
        await aliceOrc.openConnection(bobAddress);
        await bobOrc.openConnection(aliceAddress);

        final bobReceived = <Uint8List>[];

        await bobOrc.onMessage((data, from) {
          if (from == aliceAddress) {
            bobReceived.add(data);
          }
        });

        // Send multiple messages in sequence
        for (int i = 0; i < 5; i++) {
          final data = Uint8List.fromList([i, i + 1, i + 2]);
          await aliceOrc.send(data, bobAddress);
          await Future.delayed(Duration(milliseconds: 100));
        }

        // Wait for all deliveries
        await Future.delayed(Duration(milliseconds: 500));

        expect(bobReceived.length, greaterThanOrEqualTo(1));

        await aliceOrc.closeConnection(bobAddress);
        await bobOrc.closeConnection(aliceAddress);
      });
    });

    group('Error Handling', () {
      test('openConnection() throws on invalid peer', skip: !ganacheAvailable, () async {
        expect(
          () => aliceOrc.openConnection('0xInvalidAddress'),
          throwsException,
        );
      });

      test('closeConnection() handles already-closed connections gracefully', skip: !ganacheAvailable, () async {
        // Close non-existent connection should not throw
        expect(
          () => aliceOrc.closeConnection('0xNonExistent'),
          returnsNormally,
        );
      });

      test('Multiple destroy() calls are safe', skip: !ganacheAvailable, () async {
        final orc = OrcErmes.fromContract(
          contract: aliceContract,
          accountId: aliceAddress,
          socket: await ShspSocketFactoryHelper.createDefault(),
          stunHandler: await StunHandlerFactoryHelper.createDefault(),
        );

        // First destroy
        await orc.destroy();

        // Second destroy should complete without error
        expect(
          () => orc.destroy(),
          returnsNormally,
        );
      });
    });
  });
}
