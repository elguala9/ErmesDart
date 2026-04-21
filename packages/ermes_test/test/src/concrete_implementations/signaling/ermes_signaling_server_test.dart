import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../src/helpers/ganache_manager.dart';

/// Integration tests for ErmesSignalingServer with real SignalingContract.
///
/// These tests deploy a real SignalingContract on a local Ganache instance
/// and test the complete workflow between two peers (Alice and Bob).
///
/// Requirements:
/// - Ganache running at http://localhost:9545
/// - Run with: docker compose -f docker-compose-evm.yml up -d

const String ganacheRpcUrl = 'http://localhost:9545';
// Contract address is read from deployer logs at runtime (set in main())
late String signallingContractAddress;

// Use the SAME mnemonic and accounts as Ganache/hardhat config
// This ensures the accounts have funds when Ganache starts
const String ganacheMnemonic =
    'test test test test test test test test test test test junk';

// Hardhat/Ganache generate these keys from the mnemonic
// Account 0 (Alice): 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
// Account 1 (Bob): 0x70997970C51812e339D9B73b0245601d6f00dDB4
// But we need the private keys to sign transactions

// These are the private keys for the first 2 accounts derived from the
// mnemonic above
const String alicePrivateKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const String bobPrivateKey =
    '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';

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

void main() async {
  // Resolve contract address from deployer logs before group definition
  signallingContractAddress = await GanacheManager.getContractAddress();

  // Check Ganache availability BEFORE group definition
  // so skip: evaluates correctly
  ganacheAvailable = await GanacheManager.isAvailable();

  late SignalingContract aliceContract;
  late SignalingContract bobContract;
  late ErmesSignalingServer aliceServer;
  late ErmesSignalingServer bobServer;
  late String aliceAddress;
  late String bobAddress;

  // Unique run ID prevents txHash collisions with previous test runs on the
  // same Ganache instance (same nonce + same data = same txHash = no-op).
  final runId = DateTime.now().millisecondsSinceEpoch;

  setUpAll(() async {
    if (!ganacheAvailable) {
      return;
    }

    final aliceCreds = EthPrivateKey.fromHex(alicePrivateKey);
    final bobCreds = EthPrivateKey.fromHex(bobPrivateKey);

    aliceAddress = aliceCreds.address.toString();
    bobAddress = bobCreds.address.toString();

    // Use connectWithClient() to properly fetch chainId from the network.
    // SignalingContract.connect() sets chainId: null which causes a null
    // check error in web3dart when signing transactions.
    final contractAddr = EthereumAddress.fromHex(signallingContractAddress);

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

    aliceServer = ErmesSignalingServer(
      contract: aliceContract,
      accountId: aliceAddress,
    );
    bobServer = ErmesSignalingServer(
      contract: bobContract,
      accountId: bobAddress,
    );
  });

  tearDownAll(() async {
    if (!ganacheAvailable) {
      return;
    }
    await aliceServer.destroy();
    await bobServer.destroy();
  });

  group(
    'ErmesSignalingServer Integration Tests',
    () {

    group('Connection Management', () {
      test('isConnected() returns true after creation', () async {
        expect(await aliceServer.isConnected(), isTrue);
      });

      test('getIdAccount() returns Alice address', () async {
        expect(await aliceServer.getIdAccount(), equals(aliceAddress));
      });

      test('getIdAccount() returns Bob address', () async {
        expect(await bobServer.getIdAccount(), equals(bobAddress));
      });

      test('destroy() disconnects and isConnected() returns false', () async {
        final serverToDestroy = ErmesSignalingServer(
          contract: aliceContract,
          accountId: aliceAddress,
        );

        expect(await serverToDestroy.isConnected(), isTrue);
        await serverToDestroy.destroy();
        expect(await serverToDestroy.isConnected(), isFalse);
      });
    });

    group('Signal Write (setSignal)', () {
      test('Alice can write her signal without to parameter', () async {
        final signal = _TestSignalErmes(
          publicKey: 'alice-key-$runId',
          ipv6: '::1',
          ipv6Port: '5000',
          ipv4: '127.0.0.1',
          ipv4Port: '5001',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 10,
          epochTimestampExpireConversation: 2000,
        );

        // Await the transaction to ensure it's mined before subsequent tests
        await aliceServer.setSignal(signal);
      });

      test('Alice can write signal with to parameter (local callback only)',
          () async {
        final signal = _TestSignalErmes(
          publicKey: 'alice-key-2-$runId',
          ipv6: '::1',
          ipv6Port: '5002',
          ipv4: '127.0.0.1',
          ipv4Port: '5003',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 10,
          epochTimestampExpireConversation: 2000,
        );

        // Await the transaction to ensure it's mined before subsequent tests
        await aliceServer.setSignal(signal, bobAddress);
      });

      test('onSignal callback is invoked after setSignal', () async {
        var callbackInvoked = false;
        late ISignalErmes receivedSignal;

        final signal = _TestSignalErmes(
          publicKey: 'alice-callback-test-$runId',
          ipv6: '::1',
          ipv6Port: '5004',
          ipv4: '127.0.0.1',
          ipv4Port: '5005',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 10,
          epochTimestampExpireConversation: 2000,
        );

        aliceServer.onSignal((data) {
          callbackInvoked = true;
          receivedSignal = data;
        });

        await aliceServer.setSignal(signal);

        expect(callbackInvoked, isTrue);
        expect(receivedSignal.publicKey, equals('alice-callback-test-$runId'));
      });

      test('onSignal(cb, from) callback is invoked when to = from', () async {
        var callbackInvoked = false;
        late ISignalErmes receivedSignal;

        final signal = _TestSignalErmes(
          publicKey: 'alice-specific-callback-$runId',
          ipv6: '::1',
          ipv6Port: '5006',
          ipv4: '127.0.0.1',
          ipv4Port: '5007',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 10,
          epochTimestampExpireConversation: 2000,
        );

        aliceServer.onSignal((data) {
          callbackInvoked = true;
          receivedSignal = data;
        }, bobAddress);

        await aliceServer.setSignal(signal, bobAddress);

        expect(callbackInvoked, isTrue);
        expect(
          receivedSignal.publicKey,
          equals('alice-specific-callback-$runId'),
        );
      });
    });

    group('Signal Read (getSignal)', () {
      test('Bob can read Alice signal after Alice writes', () async {
        // Alice already wrote her signal in the 'Signal Write' group.
        // Reading it from Bob's perspective verifies cross-peer reads.
        final readSignal = await bobServer.getSignal(aliceAddress);

        // The last signal Alice wrote (in 'Signal Write' group) had
        // publicKey 'alice-specific-callback-$runId'
        expect(readSignal.publicKey, isNotEmpty);
        expect(readSignal.ipv6, isNotEmpty);
        expect(readSignal.ipv4, isNotEmpty);
      });

      test('Reading non-existent signal throws error', () async {
        const nonExistentAddress = '0x1234567890123456789012345678901234567890';

        await expectLater(
          aliceServer.getSignal(nonExistentAddress),
          throwsA(isA<StateError>()),
        );
      });

      test('Invalid Ethereum address throws ArgumentError', () async {
        const invalidAddress = 'not-an-ethereum-address';

        await expectLater(
          aliceServer.getSignal(invalidAddress),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Bidirectional Exchange', () {
      test('Both peers write and read each other signals', () async {
        final aliceSignal = _TestSignalErmes(
          publicKey: 'alice-bidirectional-$runId',
          ipv6: '2001:db8::a',
          ipv6Port: '5200',
          ipv4: '192.168.2.1',
          ipv4Port: '5201',
          epochTimestampStartConversation: 2000,
          secondsIntervalWindow: 15,
          epochTimestampExpireConversation: 10000,
        );

        final bobSignal = _TestSignalErmes(
          publicKey: 'bob-bidirectional-$runId',
          ipv6: '2001:db8::b',
          ipv6Port: '5300',
          ipv4: '192.168.3.1',
          ipv4Port: '5301',
          epochTimestampStartConversation: 2000,
          secondsIntervalWindow: 15,
          epochTimestampExpireConversation: 10000,
        );

        // Both write their signals (sequentially to avoid nonce conflicts)
        await aliceServer.setSignal(aliceSignal);
        await bobServer.setSignal(bobSignal);

        // Both read the other's signal
        final aliceReads = await aliceServer.getSignal(bobAddress);
        final bobReads = await bobServer.getSignal(aliceAddress);

        // Verify Alice reads Bob's signal correctly
        expect(aliceReads.publicKey, equals(bobSignal.publicKey));
        expect(aliceReads.ipv6, equals(bobSignal.ipv6));
        expect(aliceReads.ipv4, equals(bobSignal.ipv4));
        expect(aliceReads.toString(), equals(bobSignal.toString()));

        // Verify Bob reads Alice's signal correctly
        expect(bobReads.publicKey, equals(aliceSignal.publicKey));
        expect(bobReads.ipv6, equals(aliceSignal.ipv6));
        expect(bobReads.ipv4, equals(aliceSignal.ipv4));
        expect(bobReads.toString(), equals(aliceSignal.toString()));
      });
    });

    group('Event Callbacks', () {
      test('onSignal() is called with correct signal after setSignal',
          () async {
        var callbackCalled = false;
        late ISignalErmes capturedSignal;

        final testServer = ErmesSignalingServer(
          contract: aliceContract,
          accountId: aliceAddress,
        )..onSignal((data) {
          callbackCalled = true;
          capturedSignal = data;
        });

        final signal = _TestSignalErmes(
          publicKey: 'callback-test-signal-$runId',
          ipv6: '::2',
          ipv6Port: '5600',
          ipv4: '127.0.0.2',
          ipv4Port: '5601',
          epochTimestampStartConversation: 4000,
          secondsIntervalWindow: 25,
          epochTimestampExpireConversation: 12000,
        );

        await testServer.setSignal(signal);

        expect(callbackCalled, isTrue);
        expect(capturedSignal.publicKey, equals('callback-test-signal-$runId'));

        await testServer.destroy();
      });

      test('onError() is called when error occurs', () async {
        var errorCalled = false;
        late Object capturedError;

        final testServer = ErmesSignalingServer(
          contract: aliceContract,
          accountId: aliceAddress,
        )..onError((err) {
          errorCalled = true;
          capturedError = err;
        });

        // Try to read from invalid address (triggers error)
        await expectLater(
          testServer.getSignal('invalid-address'),
          throwsA(isA<ArgumentError>()),
        );

        expect(errorCalled, isTrue);
        expect(capturedError, isA<ArgumentError>());

        await testServer.destroy();
      });

      test('removeAllListeners() removes all callbacks', () async {
        var signalCallbackCalled = false;
        var errorCallbackCalled = false;

        final testServer = ErmesSignalingServer(
          contract: aliceContract,
          accountId: aliceAddress,
        )..onSignal((data) {
          signalCallbackCalled = true;
        })..onError((err) {
          errorCallbackCalled = true;
        });

        await testServer.removeAllListeners();

        // Try to trigger callbacks
        final signal = _TestSignalErmes(
          publicKey: 'after-remove-$runId',
          ipv6: '::3',
          ipv6Port: '5700',
          ipv4: '127.0.0.3',
          ipv4Port: '5701',
          epochTimestampStartConversation: 5000,
          secondsIntervalWindow: 30,
          epochTimestampExpireConversation: 13000,
        );

        await testServer.setSignal(signal);

        expect(signalCallbackCalled, isFalse);
        expect(errorCallbackCalled, isFalse);

        await testServer.destroy();
      });

      test('onClose() is called after destroy()', () async {
        var closeCalled = false;

        final testServer = ErmesSignalingServer(
          contract: aliceContract,
          accountId: aliceAddress,
        )..onClose(() {
          closeCalled = true;
        });

        await testServer.destroy();

        expect(closeCalled, isTrue);
      });
    });
  },
  skip: !ganacheAvailable ? 'Ganache not available at $ganacheRpcUrl' : null,
  );
}
