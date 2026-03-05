import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

/// Integration tests for ErmesSignalingServer with real SignalingContract.
///
/// These tests deploy a real SignalingContract on a local Ganache instance
/// and test the complete workflow between two peers (Alice and Bob).
///
/// Requirements:
/// - Ganache running at http://localhost:9545
/// - Run with: docker compose -f docker-compose-evm.yml up -d

const String ganacheRpcUrl = 'http://localhost:9545';
// Contract already deployed by docker-compose deployer
const String signallingContractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

// Use the SAME mnemonic and accounts as Ganache/hardhat config
// This ensures the accounts have funds when Ganache starts
const String ganacheMnemonic =
    'test test test test test test test test test test test junk';

// Hardhat/Ganache generate these keys from the mnemonic
// Account 0 (Alice): 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
// Account 1 (Bob): 0x70997970C51812e339D9B73b0245601d6f00dDB4
// But we need the private keys to sign transactions

// These are the private keys for the first 2 accounts derived from the mnemonic above
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
  // Check Ganache availability BEFORE group definition so skip: evaluates correctly
  try {
    final client = Web3Client(ganacheRpcUrl, http.Client());
    final chainId = await client.getChainId();
    await client.dispose();
    ganacheAvailable = (chainId == BigInt.from(1337));
  } on Exception {
    ganacheAvailable = false;
  }

  late SignalingContract aliceContract;
  late SignalingContract bobContract;
  late ErmesSignalingServer aliceServer;
  late ErmesSignalingServer bobServer;
  late String aliceAddress;
  late String bobAddress;

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

      // Connect to already-deployed contract (deployed by docker-compose deployer)
      // This avoids the "Invalid signature v value" issue when deploying
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

    await aliceServer.destroy();
    await bobServer.destroy();
  });

  group(
    'ErmesSignalingServer Integration Tests',
    () {
      setUp(() {
        // ganacheAvailable is set by setUpAll
      });

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
          publicKey: 'alice-key',
          ipv6: '::1',
          ipv6Port: '5000',
          ipv4: '127.0.0.1',
          ipv4Port: '5001',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 10,
          epochTimestampExpireConversation: 2000,
        );

        expect(
          () async => await aliceServer.setSignal(signal),
          returnsNormally,
        );
      });

      test('Alice can write signal with to parameter (local callback only)',
          () async {
        final signal = _TestSignalErmes(
          publicKey: 'alice-key-2',
          ipv6: '::1',
          ipv6Port: '5002',
          ipv4: '127.0.0.1',
          ipv4Port: '5003',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 10,
          epochTimestampExpireConversation: 2000,
        );

        expect(
          () async => await aliceServer.setSignal(signal, bobAddress),
          returnsNormally,
        );
      });

      test('onSignal callback is invoked after setSignal', () async {
        var callbackInvoked = false;
        late ISignalErmes receivedSignal;

        final signal = _TestSignalErmes(
          publicKey: 'alice-callback-test',
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
        expect(receivedSignal.publicKey, equals('alice-callback-test'));
      });

      test('onSignal(cb, from) callback is invoked when to = from', () async {
        var callbackInvoked = false;
        late ISignalErmes receivedSignal;

        final signal = _TestSignalErmes(
          publicKey: 'alice-specific-callback',
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
        expect(receivedSignal.publicKey, equals('alice-specific-callback'));
      });
    });

    group('Signal Read (getSignal)', () {
      test('Bob can read Alice signal after Alice writes', () async {
        final signal = _TestSignalErmes(
          publicKey: 'alice-readable-key',
          ipv6: '2001:db8::1',
          ipv6Port: '5100',
          ipv4: '192.168.1.1',
          ipv4Port: '5101',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 10,
          epochTimestampExpireConversation: 9000,
        );

        await aliceServer.setSignal(signal);

        final readSignal = await bobServer.getSignal(aliceAddress);

        expect(readSignal.publicKey, equals('alice-readable-key'));
        expect(readSignal.ipv6, equals('2001:db8::1'));
        expect(readSignal.ipv6Port, equals('5100'));
        expect(readSignal.ipv4, equals('192.168.1.1'));
        expect(readSignal.ipv4Port, equals('5101'));
      });

      test('Reading non-existent signal throws error', () async {
        final nonExistentAddress = '0x1234567890123456789012345678901234567890';

        expect(
          () async => await aliceServer.getSignal(nonExistentAddress),
          throwsA(isA<StateError>()),
        );
      });

      test('Invalid Ethereum address throws ArgumentError', () async {
        const invalidAddress = 'not-an-ethereum-address';

        expect(
          () async => await aliceServer.getSignal(invalidAddress),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Bidirectional Exchange', () {
      test('Alice writes, Bob reads, content is identical', () async {
        final aliceSignal = _TestSignalErmes(
          publicKey: 'alice-bidirectional',
          ipv6: '2001:db8::a',
          ipv6Port: '5200',
          ipv4: '192.168.2.1',
          ipv4Port: '5201',
          epochTimestampStartConversation: 2000,
          secondsIntervalWindow: 15,
          epochTimestampExpireConversation: 10000,
        );

        await aliceServer.setSignal(aliceSignal);
        final readSignal = await bobServer.getSignal(aliceAddress);

        expect(readSignal.publicKey, equals(aliceSignal.publicKey));
        expect(readSignal.ipv6, equals(aliceSignal.ipv6));
        expect(readSignal.ipv4, equals(aliceSignal.ipv4));
        expect(readSignal.toString(), equals(aliceSignal.toString()));
      });

      test('Bob writes, Alice reads, content is identical', () async {
        final bobSignal = _TestSignalErmes(
          publicKey: 'bob-bidirectional',
          ipv6: '2001:db8::b',
          ipv6Port: '5300',
          ipv4: '192.168.3.1',
          ipv4Port: '5301',
          epochTimestampStartConversation: 2000,
          secondsIntervalWindow: 15,
          epochTimestampExpireConversation: 10000,
        );

        await bobServer.setSignal(bobSignal);
        final readSignal = await aliceServer.getSignal(bobAddress);

        expect(readSignal.publicKey, equals(bobSignal.publicKey));
        expect(readSignal.ipv6, equals(bobSignal.ipv6));
        expect(readSignal.ipv4, equals(bobSignal.ipv4));
        expect(readSignal.toString(), equals(bobSignal.toString()));
      });

      test('Complete bidirectional exchange with both peers', () async {
        final aliceSignal = _TestSignalErmes(
          publicKey: 'alice-complete',
          ipv6: '2001:db8::c',
          ipv6Port: '5400',
          ipv4: '192.168.4.1',
          ipv4Port: '5401',
          epochTimestampStartConversation: 3000,
          secondsIntervalWindow: 20,
          epochTimestampExpireConversation: 11000,
        );

        final bobSignal = _TestSignalErmes(
          publicKey: 'bob-complete',
          ipv6: '2001:db8::d',
          ipv6Port: '5500',
          ipv4: '192.168.5.1',
          ipv4Port: '5501',
          epochTimestampStartConversation: 3000,
          secondsIntervalWindow: 20,
          epochTimestampExpireConversation: 11000,
        );

        // Both write their signals
        await aliceServer.setSignal(aliceSignal);
        await bobServer.setSignal(bobSignal);

        // Both read the other's signal
        final aliceReads = await aliceServer.getSignal(bobAddress);
        final bobReads = await bobServer.getSignal(aliceAddress);

        // Verify integrity
        expect(aliceReads.toString(), equals(bobSignal.toString()));
        expect(bobReads.toString(), equals(aliceSignal.toString()));
        expect(aliceReads.publicKey, equals('bob-complete'));
        expect(bobReads.publicKey, equals('alice-complete'));
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
        );

        testServer.onSignal((data) {
          callbackCalled = true;
          capturedSignal = data;
        });

        final signal = _TestSignalErmes(
          publicKey: 'callback-test-signal',
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
        expect(capturedSignal.publicKey, equals('callback-test-signal'));

        await testServer.destroy();
      });

      test('onError() is called when error occurs', () async {
        var errorCalled = false;
        late Object capturedError;

        final testServer = ErmesSignalingServer(
          contract: aliceContract,
          accountId: aliceAddress,
        );

        testServer.onError((err) {
          errorCalled = true;
          capturedError = err;
        });

        // Try to read from invalid address (triggers error)
        try {
          await testServer.getSignal('invalid-address');
        } catch (_) {
          // Expected to throw
        }

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
        );

        testServer
          ..onSignal((data) {
            signalCallbackCalled = true;
          })
          ..onError((err) {
            errorCallbackCalled = true;
          });

        await testServer.removeAllListeners();

        // Try to trigger callbacks
        final signal = _TestSignalErmes(
          publicKey: 'after-remove',
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
        );

        testServer.onClose(() {
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
