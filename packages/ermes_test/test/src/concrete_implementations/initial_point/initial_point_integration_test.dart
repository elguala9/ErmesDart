// ignore_for_file: cascade_invocations, lines_longer_than_80_chars
// This file can run standalone (dart test) or be imported by an aggregator.
import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_cipher/src/initial_point_ermes_cipher.dart';
import 'package:ermes_id_handler/src/initial_point_ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:ermes_message_control/src/initial_point_message_control.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../src/helpers/ganache_manager.dart';

/// Integration tests for all initialPoint functions.
///
/// Each group:
///   1. Calls the corresponding initialPoint in setUpAll
///   2. Verifies the singletons are registered and accessible
///   3. Verifies the services/repositories work correctly after initialization

void testInitialPointStorage() {
  group('initialPointErmesStorage', () {
    setUpAll(initialPointErmesStorage);

    group('Singleton registration', () {
      test('registers ErmesStorageAndCachingMessagesHandlerBaseMessageRoot',
          () {
        final handler = SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>();
        expect(handler, isNotNull);
      });

      test('registers ErmesStorageAndCachingMessagesHandlerBaseMessageType',
          () {
        final handler = SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageType>();
        expect(handler, isNotNull);
      });

      test('getter for MessageRoot returns same instance as singleton', () {
        final viaGetter =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        final viaSingleton = SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>();
        expect(identical(viaGetter, viaSingleton), isTrue);
      });

      test('getter for MessageType returns same instance as singleton', () {
        final viaGetter =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType();
        final viaSingleton = SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageType>();
        expect(identical(viaGetter, viaSingleton), isTrue);
      });
    });

    group('Functional tests after initialPointErmesStorage', () {
      test('MessageRoot handler forPeer() creates instance per peer', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        const peerId = 'peer-storage-001';

        final instance1 = handler.forPeer(peerId);
        final instance2 = handler.forPeer(peerId);

        expect(instance1, isNotNull);
        // Same peer → same cached instance
        expect(identical(instance1, instance2), isTrue);
      });

      test('MessageRoot handler returns different instances for different peers',
          () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();

        final instanceA = handler.forPeer('peer-storage-A');
        final instanceB = handler.forPeer('peer-storage-B');

        expect(identical(instanceA, instanceB), isFalse);
      });

      test('MessageType handler forPeer() creates instance per peer', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType();

        final instance = handler.forPeer('peer-storage-002');
        expect(instance, isNotNull);
      });

      test('MessageRoot and MessageType handlers are independent singletons',
          () {
        final rootHandler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        final typeHandler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType();

        expect(identical(rootHandler, typeHandler), isFalse);
      });

      test('get() returns null for unregistered connection ID', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        // IdConnectionType is String
        expect(handler.get('nonexistent-conn-id'), isNull);
      });
    });
  });
}

void testInitialPointMessageControl() {
  group('initalPointMessageControl', () {
    setUpAll(initalPointMessageControl);

    group('Singleton registration', () {
      test('registers IErmesMessageControlRepository', () {
        final repo =
            SingletonDIAccess.get<IErmesMessageControlRepository>();
        expect(repo, isNotNull);
        expect(repo, isA<IErmesMessageControlRepository>());
      });

      test('registers IErmesMessageControlService', () {
        final service =
            SingletonDIAccess.get<IErmesMessageControlService>();
        expect(service, isNotNull);
        expect(service, isA<IErmesMessageControlService>());
      });

      test('getIErmesMessageControlService() returns registered singleton', () {
        final viaGetter = getIErmesMessageControlService();
        final viaSingleton =
            SingletonDIAccess.get<IErmesMessageControlService>();
        expect(identical(viaGetter, viaSingleton), isTrue);
      });
    });

    group('Functional tests after initalPointMessageControl', () {
      // Use fresh instances per test to avoid shared singleton state
      late ErmesMessageControlRepository repo;
      late ErmesMessageControlService service;

      setUp(() {
        repo = ErmesMessageControlFactory.createRepository();
        service = ErmesMessageControlService.createWithRepository(repo);
      });

      test('initial state has zero missing IDs', () {
        expect(service.numberOfMissingIds(), equals(0));
      });

      test('sequential IDs create no gaps', () {
        service.idArrived(0);
        service.idArrived(1);
        service.idArrived(2);
        expect(service.numberOfMissingIds(), equals(0));
      });

      test('gap in IDs detects missing entries', () {
        service.idArrived(0);
        service.idArrived(3); // 1 and 2 are missing
        expect(service.numberOfMissingIds(), greaterThan(0));
      });

      test('idsToRequest() returns the missing IDs after a gap', () async {
        service.idArrived(0);
        service.idArrived(4); // 1, 2, 3 are missing
        final missing = await service.idsToRequest();
        expect(missing, isNotEmpty);
        expect(missing, containsAll([1, 2, 3]));
      });

      test('singleton service is reachable and callable after init', () {
        final singletonService =
            SingletonDIAccess.get<IErmesMessageControlService>();
        expect(singletonService.numberOfMissingIds(), isA<int>());
      });
    });
  });
}

void testInitialPointCipher() {
  group('initialPointErmesCipher', () {
    setUpAll(() async => initialPointErmesCipher());

    group('Singleton registration', () {
      test('registers IErmesPeerCipher', () {
        final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
        expect(cipher, isNotNull);
        expect(cipher, isA<IErmesPeerCipher>());
      });

      test('registers IErmesPeerKeyExchange', () {
        final keyExchange = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        expect(keyExchange, isNotNull);
        expect(keyExchange, isA<IErmesPeerKeyExchange>());
      });

      test('registers IECDHKeyExchangeService', () {
        final ecdhService =
            SingletonDIAccess.get<IECDHKeyExchangeService>();
        expect(ecdhService, isNotNull);
        expect(ecdhService, isA<IECDHKeyExchangeService>());
      });

      test('all three singletons are distinct objects', () {
        final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
        final keyExchange = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        final ecdhService =
            SingletonDIAccess.get<IECDHKeyExchangeService>();

        expect(identical(cipher, keyExchange), isFalse);
        expect(identical(cipher, ecdhService), isFalse);
        expect(identical(keyExchange, ecdhService), isFalse);
      });
    });

    group('Functional tests after initialPointErmesCipher', () {
      test('IErmesPeerCipher throws when no encryption cipher is registered',
          () {
        final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
        // Cipher is empty after init — encrypt() should throw
        expect(
          () => cipher.encrypt(
            Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('IECDHKeyExchangeService singleton is consistent across calls', () {
        final s1 = SingletonDIAccess.get<IECDHKeyExchangeService>();
        final s2 = SingletonDIAccess.get<IECDHKeyExchangeService>();
        expect(identical(s1, s2), isTrue);
      });

      test('ECDHKeyExchangeService.generateNew() creates an independent key',
          () async {
        final newService =
            await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
        expect(newService.publicKey, isNotNull);
        expect(newService.publicKey, isNotEmpty);

        final singleton = SingletonDIAccess.get<IECDHKeyExchangeService>();
        expect(identical(newService, singleton), isFalse);
      });

      test('Two ECDH instances can exchange keys and derive symmetric ciphers',
          () async {
        final alice =
            await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
        final bob =
            await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;

        // generateISymmetric expects the serialized form of the peer's key
        final aliceSymmetric = alice.generateISymmetric(bob.serialize());
        final bobSymmetric = bob.generateISymmetric(alice.serialize());

        expect(aliceSymmetric, isNotNull);
        expect(bobSymmetric, isNotNull);
      });

      test('IErmesPeerKeyExchange singleton is identical across calls', () {
        final kx1 = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        final kx2 = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        expect(identical(kx1, kx2), isTrue);
      });
    });
  });
}

void testInitialPointIdHandler() {
  group('initialPointIdHanlder', () {
    // Creates a WorkDb at ./id_handler directory on first call
    setUpAll(initialPointIdHanlder);

    group('Singleton registration', () {
      test('registers IIdHandlerStorageRepository', () {
        final repo =
            SingletonDIAccess.get<IIdHandlerStorageRepository>();
        expect(repo, isNotNull);
        expect(repo, isA<IIdHandlerStorageRepository>());
      });

      test('registers IIdHandlerStorageService', () {
        final service =
            SingletonDIAccess.get<IIdHandlerStorageService>();
        expect(service, isNotNull);
        expect(service, isA<IIdHandlerStorageService>());
      });

      test('registers IIdHandlerRepository', () {
        final repo = SingletonDIAccess.get<IIdHandlerRepository>();
        expect(repo, isNotNull);
        expect(repo, isA<IIdHandlerRepository>());
      });

      test('registers IIdHandlerService', () {
        final service = SingletonDIAccess.get<IIdHandlerService>();
        expect(service, isNotNull);
        expect(service, isA<IIdHandlerService>());
      });

      test('IIdHandlerRepository and IIdHandlerService are distinct', () {
        final repo = SingletonDIAccess.get<IIdHandlerRepository>();
        final service = SingletonDIAccess.get<IIdHandlerService>();
        expect(identical(repo, service), isFalse);
      });
    });

    group('Functional tests after initialPointIdHanlder', () {
      late IIdHandlerService service;

      setUp(() {
        service = SingletonDIAccess.get<IIdHandlerService>();
      });

      test('IIdHandlerService generates valid IDs', () {
        final id = service.getNewId();
        expect(id, isA<int>());
        expect(id, greaterThanOrEqualTo(0));
      });

      test('IIdHandlerService generates monotonically increasing IDs', () {
        final id1 = service.getNewId();
        final id2 = service.getNewId();
        expect(id2, greaterThan(id1));
      });

      test('IIdHandlerService getCurrent() is always >= last generated ID', () {
        final id = service.getNewId();
        expect(service.getCurrent(), greaterThanOrEqualTo(id));
      });

      test('IIdHandlerService singleton is identical across calls', () {
        final s1 = SingletonDIAccess.get<IIdHandlerService>();
        final s2 = SingletonDIAccess.get<IIdHandlerService>();
        expect(identical(s1, s2), isTrue);
      });

      test('IIdHandlerRepository singleton is identical across calls', () {
        final r1 = SingletonDIAccess.get<IIdHandlerRepository>();
        final r2 = SingletonDIAccess.get<IIdHandlerRepository>();
        expect(identical(r1, r2), isTrue);
      });

      test('IIdHandlerRepository.getNewId() generates valid IDs', () {
        final repo = SingletonDIAccess.get<IIdHandlerRepository>();
        final id = repo.getNewId();
        expect(id, isA<int>());
        expect(id, greaterThanOrEqualTo(0));
      });
    });
  });
}

// ---------------------------------------------------------------------------
// initialPointErmesSignaling  (requires Ganache)
// ---------------------------------------------------------------------------

const String _ganacheRpcUrl = 'http://localhost:9545';
const String _alicePrivateKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

Future<void> testInitialPointSignaling() async {
  final ganacheAvailable = await GanacheManager.initialize();
  final _contractAddress = await GanacheManager.getContractAddress();

  late SignalingContract contract;
  late IStunShspHandler stunHandler;

  group(
    'initialPointErmesSignaling',
    () {
      setUpAll(() async {
        final creds = EthPrivateKey.fromHex(_alicePrivateKey);
        final contractAddr = EthereumAddress.fromHex(_contractAddress);
        final client = Web3Client(_ganacheRpcUrl, http.Client());

        contract = await SignalingContract.connectWithClient(
          client: client,
          contractAddress: contractAddr,
          credentials: creds,
        );

        // Use the proper DI initialization to avoid StunShspHandler.initialize()
        // bug in stun_shsp 0.1.1 (late _stunHandler accessed before assignment).
        await initializePointStunShsp();
        stunHandler = SingletonDIAccess.get<IStunShspHandler>();

        // ErmesSignalingServerDI.initializeDI() gets IdAccountType from
        // singleton; register the account ID before calling the initial point.
        final aliceAddress =
            EthPrivateKey.fromHex(_alicePrivateKey).address.toString();
        SingletonDIAccess.addInstance<IdAccountType>(aliceAddress);

        initialPointErmesSignaling(
          contract: contract,
          stunShspHandler: stunHandler,
          socket: stunHandler.ipv4ShspSocket,
        );
      });

      tearDownAll(() async {
        await GanacheManager.cleanup();
      });

      group('Singleton registration', () {
        test('registers IStunShspHandler (required param)', () {
          final handler = SingletonDIAccess.get<IStunShspHandler>();
          expect(handler, isNotNull);
          expect(handler, isA<IStunShspHandler>());
        });

        test('registers IShspSocket (required param)', () {
          final socket = SingletonDIAccess.get<IShspSocket>();
          expect(socket, isNotNull);
          expect(socket, isA<IShspSocket>());
        });

        test('registers IErmesSignalingServer', () {
          final server =
              SingletonDIAccess.get<IErmesSignalingServer>();
          expect(server, isNotNull);
          expect(server, isA<IErmesSignalingServer>());
        });

        test('registers IErmesBookRepository<BookData>', () {
          final repo =
              SingletonDIAccess.get<IErmesBookRepository<BookData>>();
          expect(repo, isNotNull);
          expect(repo, isA<IErmesBookRepository<BookData>>());
        });

        test('registers IErmesBookService<BookData>', () {
          final service =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          expect(service, isNotNull);
          expect(service, isA<IErmesBookService<BookData>>());
        });

        test('registers IErmesSignalingHandler<IShspPeer>', () {
          final handler =
              SingletonDIAccess.get<IErmesSignalingHandler<IShspPeer>>();
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<IShspPeer>>());
        });

        test('registers IErmesSignalingRepository<ISignalErmes>', () {
          final repo = SingletonDIAccess
              .get<IErmesSignalingRepository<ISignalErmes>>();
          expect(repo, isNotNull);
          expect(repo, isA<IErmesSignalingRepository<ISignalErmes>>());
        });

        test('registers IErmesSignalingService', () {
          final service =
              SingletonDIAccess.get<IErmesSignalingService>();
          expect(service, isNotNull);
          expect(service, isA<IErmesSignalingService>());
        });
      });

      group('Functional tests after initialPointErmesSignaling', () {
        test('IErmesSignalingServer isConnected() returns true', () async {
          final server = SingletonDIAccess.get<IErmesSignalingServer>();
          final connected = await server.isConnected();
          expect(connected, isTrue);
        });

        test('IErmesBookService starts with no accounts', () {
          final bookService =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          expect(bookService.numberOfElements(), equals(0));
        });

        test('IErmesBookService setAccount() registers a peer', () {
          final bookService =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'test-peer-signaling-init';

          bookService.setAccount(
            AccountInfo(
              account: peerId,
              info: BookData(
                peerId: peerId,
                name: 'Test Peer',
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );

          expect(bookService.listOfIds(), contains(peerId));
        });

        test('IErmesBookService getAccount() retrieves registered peer', () {
          final bookService =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'test-peer-get';

          bookService.setAccount(
            AccountInfo(
              account: peerId,
              info: BookData(
                peerId: peerId,
                name: 'Get Test Peer',
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );

          final account = bookService.getAccount(peerId);
          expect(account.account, equals(peerId));
          expect(account.info?.name, equals('Get Test Peer'));
        });

        test('IErmesBookRepository reflects accounts set via service', () {
          final repo =
              SingletonDIAccess.get<IErmesBookRepository<BookData>>();
          final service =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'test-peer-repo-sync';

          service.setAccount(
            AccountInfo(
              account: peerId,
              info: BookData(
                peerId: peerId,
                name: 'Repo Sync Test',
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );

          expect(repo.listOfIds(), contains(peerId));
        });

        test('IErmesBookService deleteAccount() removes the peer', () {
          final bookService =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'test-peer-delete';

          bookService.setAccount(
            AccountInfo(
              account: peerId,
              info: BookData(
                peerId: peerId,
                name: 'Delete Test',
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );
          expect(bookService.listOfIds(), contains(peerId));

          bookService.deleteAccount(peerId);
          expect(bookService.listOfIds(), isNot(contains(peerId)));
        });
      });
    },
    skip: !ganacheAvailable
        ? 'Ganache not available at $_ganacheRpcUrl'
        : null,
  );
}


Future<void> main() async {
  testInitialPointStorage();
  testInitialPointMessageControl();
  testInitialPointCipher();
  testInitialPointIdHandler();
  await testInitialPointSignaling();
}
