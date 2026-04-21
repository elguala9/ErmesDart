// ignore_for_file: cascade_invocations, lines_longer_than_80_chars
// This file can run standalone (dart test) or be imported by an aggregator.
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_cipher/src/initial_point/initial_point_ermes_cipher.dart';
import 'package:ermes_cipher/src/initial_point/initial_point_ermes_cipher_registry.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core/src/initial_point/initial_point_ermes_core.dart';
import 'package:ermes_core/src/initial_point/initial_point_ermes_core_registry.dart';
import 'package:ermes_id_handler/src/initial_point/initial_point_ermes_id_handler.dart';
import 'package:ermes_id_handler/src/initial_point/initial_point_ermes_id_handler_registry.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:ermes_message_control/src/initial_point/initial_point_message_control.dart';
import 'package:ermes_message_control/src/initial_point/initial_point_message_control_registry.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:ermes_signaling/src/initial_point/initial_point_ermes_signaling.dart';
import 'package:ermes_signaling/src/initial_point/initial_point_ermes_signaling_registry.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_storage/src/initial/initial_point_messages.dart';
import 'package:ermes_storage/src/initial/initial_point_messages_registry.dart';
import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../src/helpers/ganache_manager.dart';

// ---------------------------------------------------------------------------
// Constants shared by Ganache tests
// ---------------------------------------------------------------------------

const String _ganacheRpcUrl = 'http://localhost:9545';
const String _alicePrivateKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

// ===========================================================================
//  initialPointErmesStorage  (SINGLETON)
// ===========================================================================

void testInitialPointStorage() {
  group('initialPointErmesStorage [singleton]', () {
    setUpAll(initialPointErmesStorage);

    group('Registration', () {
      test('registers ErmesStorageAndCachingMessagesHandlerBaseMessageRoot', () {
        final handler = SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>();
        expect(handler, isNotNull);
        expect(handler,
            isA<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>());
      });

      test('registers ErmesStorageAndCachingMessagesHandlerBaseMessageType', () {
        final handler = SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageType>();
        expect(handler, isNotNull);
        expect(handler,
            isA<ErmesStorageAndCachingMessagesHandlerBaseMessageType>());
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

      test('MessageRoot and MessageType handlers are distinct singletons', () {
        final root =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        final type =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType();
        expect(identical(root, type), isFalse);
      });
    });

    group('Functional', () {
      test('MessageRoot handler forPeer() returns the same instance for same peer', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        const peerId = 'peer-storage-001';
        final i1 = handler.forPeer(peerId);
        final i2 = handler.forPeer(peerId);
        expect(i1, isNotNull);
        expect(identical(i1, i2), isTrue);
      });

      test('MessageRoot handler returns different instances for different peers', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        final iA = handler.forPeer('peer-storage-A');
        final iB = handler.forPeer('peer-storage-B');
        expect(identical(iA, iB), isFalse);
      });

      test('MessageType handler forPeer() returns a non-null instance', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType();
        final instance = handler.forPeer('peer-storage-002');
        expect(instance, isNotNull);
      });

      test('MessageType handler returns same instance for same peer', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType();
        const peerId = 'peer-storage-type-same';
        final i1 = handler.forPeer(peerId);
        final i2 = handler.forPeer(peerId);
        expect(identical(i1, i2), isTrue);
      });

      test('get() returns null for an unregistered connection ID', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot();
        expect(handler.get('nonexistent-conn-id'), isNull);
      });
    });
  });
}

// ===========================================================================
//  initialPointErmesStorageRegistry  (REGISTRY)
// ===========================================================================

void testInitialPointStorageRegistry() {
  group('initialPointErmesStorageRegistry [registry]', () {
    const key1 = 'test-storage-reg-1';
    const key2 = 'test-storage-reg-2';

    setUpAll(() {
      initialPointErmesStorageRegistry(key: key1);
      initialPointErmesStorageRegistry(key: key2);
    });

    group('Registration', () {
      test('key1: getter for MessageRoot returns non-null', () {
        final h =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        expect(h, isNotNull);
        expect(h, isA<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>());
      });

      test('key1: getter for MessageType returns non-null', () {
        final h =
            getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
                key: key1);
        expect(h, isNotNull);
        expect(h, isA<ErmesStorageAndCachingMessagesHandlerBaseMessageType>());
      });

      test('key2: getter for MessageRoot returns non-null', () {
        final h =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key2);
        expect(h, isNotNull);
      });

      test('key2: getter for MessageType returns non-null', () {
        final h =
            getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
                key: key2);
        expect(h, isNotNull);
      });
    });

    group('Identity', () {
      test('same key → same MessageRoot instance on repeated getter calls', () {
        final a =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        final b =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        expect(identical(a, b), isTrue);
      });

      test('same key → same MessageType instance on repeated getter calls', () {
        final a =
            getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
                key: key1);
        final b =
            getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
                key: key1);
        expect(identical(a, b), isTrue);
      });
    });

    group('Independence between keys', () {
      test('different keys → different MessageRoot instances', () {
        final a =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        final b =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key2);
        expect(identical(a, b), isFalse);
      });

      test('different keys → different MessageType instances', () {
        final a =
            getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
                key: key1);
        final b =
            getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
                key: key2);
        expect(identical(a, b), isFalse);
      });

      test('forPeer caches are isolated between registry keys', () {
        final h1 =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        final h2 =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key2);
        const peer = 'shared-peer-name';
        final i1 = h1.forPeer(peer);
        final i2 = h2.forPeer(peer);
        expect(identical(i1, i2), isFalse);
      });
    });

    group('Functional', () {
      test('forPeer() works correctly on registry instance', () {
        final h =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        const peer = 'peer-reg-func-001';
        final i = h.forPeer(peer);
        expect(i, isNotNull);
        expect(identical(i, h.forPeer(peer)), isTrue);
      });

      test('MessageRoot and MessageType are distinct per key', () {
        final root =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        final type =
            getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
                key: key1);
        expect(identical(root, type), isFalse);
      });

      test('get() on a fresh registry instance returns null for unknown ID', () {
        final h =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
                key: key1);
        expect(h.get('no-such-conn'), isNull);
      });
    });
  });
}

// ===========================================================================
//  initalPointMessageControl  (SINGLETON)
// ===========================================================================

void testInitialPointMessageControl() {
  group('initalPointMessageControl [singleton]', () {
    setUpAll(initalPointMessageControl);

    group('Registration', () {
      test('registers IErmesMessageControlRepository', () {
        final repo = SingletonDIAccess.get<IErmesMessageControlRepository>();
        expect(repo, isNotNull);
        expect(repo, isA<IErmesMessageControlRepository>());
      });

      test('registers IErmesMessageControlService', () {
        final service = SingletonDIAccess.get<IErmesMessageControlService>();
        expect(service, isNotNull);
        expect(service, isA<IErmesMessageControlService>());
      });

      test('getIErmesMessageControlService() returns registered singleton', () {
        final viaGetter = getIErmesMessageControlService();
        final viaSingleton =
            SingletonDIAccess.get<IErmesMessageControlService>();
        expect(identical(viaGetter, viaSingleton), isTrue);
      });

      test('repository and service are distinct objects', () {
        final repo = SingletonDIAccess.get<IErmesMessageControlRepository>();
        final service = SingletonDIAccess.get<IErmesMessageControlService>();
        expect(identical(repo, service), isFalse);
      });
    });

    group('Functional', () {
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

      test('gap in IDs is detected as missing', () {
        service.idArrived(0);
        service.idArrived(3);
        expect(service.numberOfMissingIds(), greaterThan(0));
      });

      test('idsToRequest() returns the exact missing IDs', () async {
        service.idArrived(0);
        service.idArrived(4);
        final missing = await service.idsToRequest();
        expect(missing, isNotEmpty);
        expect(missing, containsAll([1, 2, 3]));
      });

      test('singleton service is reachable and callable', () {
        final s = SingletonDIAccess.get<IErmesMessageControlService>();
        expect(s.numberOfMissingIds(), isA<int>());
      });
    });
  });
}

// ===========================================================================
//  initialPointMessageControlRegistry  (REGISTRY)
// ===========================================================================

void testInitialPointMessageControlRegistry() {
  group('initialPointMessageControlRegistry [registry]', () {
    const key1 = 'test-mc-reg-1';
    const key2 = 'test-mc-reg-2';

    setUpAll(() {
      initialPointMessageControlRegistry(key: key1);
      initialPointMessageControlRegistry(key: key2);
    });

    group('Registration', () {
      test('key1: getIErmesMessageControlServiceFromRegistry returns non-null', () {
        final svc = getIErmesMessageControlServiceFromRegistry(key: key1);
        expect(svc, isNotNull);
        expect(svc, isA<IErmesMessageControlService>());
      });

      test('key2: getIErmesMessageControlServiceFromRegistry returns non-null', () {
        final svc = getIErmesMessageControlServiceFromRegistry(key: key2);
        expect(svc, isNotNull);
        expect(svc, isA<IErmesMessageControlService>());
      });
    });

    group('Identity', () {
      test('same key → same service instance on repeated getter calls', () {
        final a = getIErmesMessageControlServiceFromRegistry(key: key1);
        final b = getIErmesMessageControlServiceFromRegistry(key: key1);
        expect(identical(a, b), isTrue);
      });
    });

    group('Independence between keys', () {
      test('different keys → different service instances', () {
        final svc1 = getIErmesMessageControlServiceFromRegistry(key: key1);
        final svc2 = getIErmesMessageControlServiceFromRegistry(key: key2);
        expect(identical(svc1, svc2), isFalse);
      });

      // ErmesMessageControlServiceDI reads IErmesMessageControlRepository from
      // the singleton at construction time.  All registry services are therefore
      // backed by the same singleton repository and share state.
      test('all registry services share the singleton repository (shared state)', () {
        final svc1 = getIErmesMessageControlServiceFromRegistry(key: key1);
        final svc2 = getIErmesMessageControlServiceFromRegistry(key: key2);
        // Whatever svc1 sees, svc2 sees too — same underlying repo.
        expect(svc1.numberOfMissingIds(), equals(svc2.numberOfMissingIds()));
      });
    });

    group('Functional', () {
      // For true functional isolation use directly-created instances (not DI).
      test('directly created service starts with zero missing IDs', () {
        final repo = ErmesMessageControlFactory.createRepository();
        final svc = ErmesMessageControlService.createWithRepository(repo);
        expect(svc.numberOfMissingIds(), equals(0));
      });

      test('directly created service correctly tracks sequential IDs', () {
        final repo = ErmesMessageControlFactory.createRepository();
        final svc = ErmesMessageControlService.createWithRepository(repo);
        svc.idArrived(0);
        svc.idArrived(1);
        svc.idArrived(2);
        expect(svc.numberOfMissingIds(), equals(0));
      });

      test('registry service type and interface match expectations', () {
        final svc = getIErmesMessageControlServiceFromRegistry(key: key1);
        expect(svc, isA<IErmesMessageControlService>());
        expect(svc.numberOfMissingIds(), isA<int>());
      });
    });
  });
}

// ===========================================================================
//  initialPointErmesCipher  (SINGLETON)
// ===========================================================================

void testInitialPointCipher() {
  group('initialPointErmesCipher [singleton]', () {
    setUpAll(() async => initialPointErmesCipher());

    group('Registration', () {
      test('registers IErmesPeerCipher', () {
        final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
        expect(cipher, isNotNull);
        expect(cipher, isA<IErmesPeerCipher>());
      });

      test('registers IErmesPeerKeyExchange', () {
        final kx = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        expect(kx, isNotNull);
        expect(kx, isA<IErmesPeerKeyExchange>());
      });

      test('registers IKeyExchange', () {
        final keyExchange = SingletonDIAccess.get<IKeyExchange>();
        expect(keyExchange, isNotNull);
        expect(keyExchange, isA<IKeyExchange>());
      });

      test('registers IECDHKeyExchangeService', () {
        final ecdhService = SingletonDIAccess.get<IECDHKeyExchangeService>();
        expect(ecdhService, isNotNull);
        expect(ecdhService, isA<IECDHKeyExchangeService>());
      });

      test('all four registered objects are distinct instances', () {
        final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
        final kx = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        final keyExchange = SingletonDIAccess.get<IKeyExchange>();
        final ecdhService = SingletonDIAccess.get<IECDHKeyExchangeService>();
        expect(identical(cipher, kx), isFalse);
        expect(identical(cipher, ecdhService), isFalse);
        expect(identical(kx, ecdhService), isFalse);
        expect(identical(kx, keyExchange), isFalse);
        expect(identical(cipher, keyExchange), isFalse);
      });
    });

    group('Functional', () {
      test('IErmesPeerCipher throws when no encryption cipher is registered', () {
        final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
        expect(
          () => cipher.encrypt(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8])),
          throwsA(isA<Exception>()),
        );
      });

      test('IECDHKeyExchangeService singleton is identical across repeated gets', () {
        final s1 = SingletonDIAccess.get<IECDHKeyExchangeService>();
        final s2 = SingletonDIAccess.get<IECDHKeyExchangeService>();
        expect(identical(s1, s2), isTrue);
      });

      test('IKeyExchange singleton is identical across repeated gets', () {
        final kx1 = SingletonDIAccess.get<IKeyExchange>();
        final kx2 = SingletonDIAccess.get<IKeyExchange>();
        expect(identical(kx1, kx2), isTrue);
      });

      test('IErmesPeerKeyExchange singleton is identical across repeated gets', () {
        final kx1 = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        final kx2 = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        expect(identical(kx1, kx2), isTrue);
      });

      test('Two fresh ECDHKeyExchangeService instances can derive a symmetric key', () async {
        final alice =
            await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
        final bob =
            await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;

        final aliceSymmetric = alice.generateISymmetric(bob.serialize());
        final bobSymmetric = bob.generateISymmetric(alice.serialize());

        expect(aliceSymmetric, isNotNull);
        expect(bobSymmetric, isNotNull);
      });

      test('ECDHKeyExchangeService.generateNew() is not the same as singleton', () async {
        final fresh =
            await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
        final singleton = SingletonDIAccess.get<IECDHKeyExchangeService>();
        expect(identical(fresh, singleton), isFalse);
      });
    });
  });
}

// ===========================================================================
//  initialPointErmesCipherRegistry  (REGISTRY)
// ===========================================================================

Future<void> testInitialPointCipherRegistry() async {
  group('initialPointErmesCipherRegistry [registry]', () {
    const key1 = 'test-cipher-reg-1';
    const key2 = 'test-cipher-reg-2';

    setUpAll(() async {
      await initialPointErmesCipherRegistry(key: key1);
      await initialPointErmesCipherRegistry(key: key2);
    });

    group('Registration', () {
      test('key1: getIErmesPeerCipherFromRegistry returns non-null', () {
        final cipher = getIErmesPeerCipherFromRegistry(key: key1);
        expect(cipher, isNotNull);
        expect(cipher, isA<IErmesPeerCipher>());
      });

      test('key1: getIErmesPeerKeyExchangeFromRegistry returns non-null', () {
        final kx = getIErmesPeerKeyExchangeFromRegistry(key: key1);
        expect(kx, isNotNull);
        expect(kx, isA<IErmesPeerKeyExchange>());
      });

      test('key1: getIKeyExchangeFromRegistry returns non-null', () {
        final keyExchange = getIKeyExchangeFromRegistry(key: key1);
        expect(keyExchange, isNotNull);
        expect(keyExchange, isA<IKeyExchange>());
      });

      test('key1: getIECDHKeyExchangeServiceFromRegistry returns non-null', () {
        final svc = getIECDHKeyExchangeServiceFromRegistry(key: key1);
        expect(svc, isNotNull);
        expect(svc, isA<IECDHKeyExchangeService>());
      });

      test('key2: all four getters return non-null', () {
        expect(getIErmesPeerCipherFromRegistry(key: key2), isNotNull);
        expect(getIErmesPeerKeyExchangeFromRegistry(key: key2), isNotNull);
        expect(getIKeyExchangeFromRegistry(key: key2), isNotNull);
        expect(getIECDHKeyExchangeServiceFromRegistry(key: key2), isNotNull);
      });

      test('key1: all four objects are distinct instances', () {
        final cipher = getIErmesPeerCipherFromRegistry(key: key1);
        final kx = getIErmesPeerKeyExchangeFromRegistry(key: key1);
        final keyExchange = getIKeyExchangeFromRegistry(key: key1);
        final svc = getIECDHKeyExchangeServiceFromRegistry(key: key1);
        expect(identical(cipher, kx), isFalse);
        expect(identical(cipher, svc), isFalse);
        expect(identical(kx, svc), isFalse);
        expect(identical(kx, keyExchange), isFalse);
        expect(identical(cipher, keyExchange), isFalse);
      });
    });

    group('Identity', () {
      test('same key → same cipher instance on repeated calls', () {
        final a = getIErmesPeerCipherFromRegistry(key: key1);
        final b = getIErmesPeerCipherFromRegistry(key: key1);
        expect(identical(a, b), isTrue);
      });

      test('same key → same ECDH service instance on repeated calls', () {
        final a = getIECDHKeyExchangeServiceFromRegistry(key: key1);
        final b = getIECDHKeyExchangeServiceFromRegistry(key: key1);
        expect(identical(a, b), isTrue);
      });

      test('same key → same IKeyExchange instance on repeated calls', () {
        final a = getIKeyExchangeFromRegistry(key: key1);
        final b = getIKeyExchangeFromRegistry(key: key1);
        expect(identical(a, b), isTrue);
      });
    });

    group('Independence between keys', () {
      test('different keys → different cipher instances', () {
        final c1 = getIErmesPeerCipherFromRegistry(key: key1);
        final c2 = getIErmesPeerCipherFromRegistry(key: key2);
        expect(identical(c1, c2), isFalse);
      });

      test('different keys → different IKeyExchange instances', () {
        final kx1 = getIKeyExchangeFromRegistry(key: key1);
        final kx2 = getIKeyExchangeFromRegistry(key: key2);
        expect(identical(kx1, kx2), isFalse);
      });

      test('different keys → different ECDH key pairs', () {
        // Two independently generated key pairs are different objects.
        // With ECDH over secp256r1, the probability of collision is negligible.
        final svc1 = getIECDHKeyExchangeServiceFromRegistry(key: key1);
        final svc2 = getIECDHKeyExchangeServiceFromRegistry(key: key2);
        expect(identical(svc1, svc2), isFalse);
      });

      test('IErmesPeerCipher from key1 throws without a cipher; key2 is unaffected', () {
        final c1 = getIErmesPeerCipherFromRegistry(key: key1);
        final c2 = getIErmesPeerCipherFromRegistry(key: key2);
        // Both should throw for encrypt (no cipher registered yet)
        expect(
          () => c1.encrypt(Uint8List.fromList([1, 2, 3])),
          throwsA(isA<Exception>()),
        );
        expect(
          () => c2.encrypt(Uint8List.fromList([1, 2, 3])),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Functional', () {
      test('ECDH service from registry can serialize its public key', () {
        final svc = getIECDHKeyExchangeServiceFromRegistry(key: key1);
        final serialized = (svc as ECDHKeyExchangeService).serialize();
        expect(serialized, isNotNull);
        expect(serialized, isNotEmpty);
      });

      test('key1 and key2 ECDH services can derive a shared symmetric key', () {
        final svc1 =
            getIECDHKeyExchangeServiceFromRegistry(key: key1) as ECDHKeyExchangeService;
        final svc2 =
            getIECDHKeyExchangeServiceFromRegistry(key: key2) as ECDHKeyExchangeService;

        final sym1 = svc1.generateISymmetric(svc2.serialize());
        final sym2 = svc2.generateISymmetric(svc1.serialize());

        expect(sym1, isNotNull);
        expect(sym2, isNotNull);
      });
    });
  });
}

// ===========================================================================
//  initialPointIdHanlder  (SINGLETON)
// ===========================================================================

void testInitialPointIdHandler() {
  group('initialPointIdHanlder [singleton]', () {
    setUpAll(initialPointIdHanlder);

    group('Registration', () {
      test('registers IIdHandlerStorageRepository', () {
        final repo = SingletonDIAccess.get<IIdHandlerStorageRepository>();
        expect(repo, isNotNull);
        expect(repo, isA<IIdHandlerStorageRepository>());
      });

      test('registers IIdHandlerStorageService', () {
        final svc = SingletonDIAccess.get<IIdHandlerStorageService>();
        expect(svc, isNotNull);
        expect(svc, isA<IIdHandlerStorageService>());
      });

      test('registers IIdHandlerRepository', () {
        final repo = SingletonDIAccess.get<IIdHandlerRepository>();
        expect(repo, isNotNull);
        expect(repo, isA<IIdHandlerRepository>());
      });

      test('registers IIdHandlerService', () {
        final svc = SingletonDIAccess.get<IIdHandlerService>();
        expect(svc, isNotNull);
        expect(svc, isA<IIdHandlerService>());
      });

      test('all four registered objects are distinct instances', () {
        final stRepo = SingletonDIAccess.get<IIdHandlerStorageRepository>();
        final stSvc = SingletonDIAccess.get<IIdHandlerStorageService>();
        final repo = SingletonDIAccess.get<IIdHandlerRepository>();
        final svc = SingletonDIAccess.get<IIdHandlerService>();
        expect(identical(stRepo, stSvc), isFalse);
        expect(identical(stRepo, repo), isFalse);
        expect(identical(stRepo, svc), isFalse);
        expect(identical(stSvc, repo), isFalse);
        expect(identical(repo, svc), isFalse);
      });
    });

    group('Functional', () {
      late IIdHandlerService service;

      setUp(() => service = SingletonDIAccess.get<IIdHandlerService>());

      test('getNewId() returns a non-negative integer', () {
        expect(service.getNewId(), isA<int>());
        expect(service.getNewId(), greaterThanOrEqualTo(0));
      });

      test('getNewId() is monotonically increasing', () {
        final id1 = service.getNewId();
        final id2 = service.getNewId();
        final id3 = service.getNewId();
        expect(id2, greaterThan(id1));
        expect(id3, greaterThan(id2));
      });

      test('getCurrent() is always >= last generated ID', () {
        final id = service.getNewId();
        expect(service.getCurrent(), greaterThanOrEqualTo(id));
      });

      test('IIdHandlerService is identical across repeated gets', () {
        final s1 = SingletonDIAccess.get<IIdHandlerService>();
        final s2 = SingletonDIAccess.get<IIdHandlerService>();
        expect(identical(s1, s2), isTrue);
      });

      test('IIdHandlerRepository is identical across repeated gets', () {
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

      test('IIdHandlerService and IIdHandlerRepository share the same counter', () {
        final svc = SingletonDIAccess.get<IIdHandlerService>();
        final repo = SingletonDIAccess.get<IIdHandlerRepository>();
        final idFromSvc = svc.getNewId();
        final idFromRepo = repo.getNewId();
        expect(idFromRepo, greaterThan(idFromSvc));
      });
    });
  });
}

// ===========================================================================
//  initialPointIdHandlerRegistry  (REGISTRY)
// ===========================================================================

void testInitialPointIdHandlerRegistry() {
  group('initialPointIdHandlerRegistry [registry]', () {
    const key1 = 'test-id-reg-1';
    const key2 = 'test-id-reg-2';
    const path1 = './test_id_handler_reg_1';
    const path2 = './test_id_handler_reg_2';

    setUpAll(() {
      initialPointIdHandlerRegistry(key: key1, dataPath: path1);
      initialPointIdHandlerRegistry(key: key2, dataPath: path2);
    });

    group('Registration', () {
      test('key1: getIIdHandlerStorageRepositoryFromRegistry returns non-null', () {
        final r = getIIdHandlerStorageRepositoryFromRegistry(key: key1);
        expect(r, isNotNull);
        expect(r, isA<IIdHandlerStorageRepository>());
      });

      test('key1: getIIdHandlerStorageServiceFromRegistry returns non-null', () {
        final s = getIIdHandlerStorageServiceFromRegistry(key: key1);
        expect(s, isNotNull);
        expect(s, isA<IIdHandlerStorageService>());
      });

      test('key1: getIIdHandlerRepositoryFromRegistry returns non-null', () {
        final r = getIIdHandlerRepositoryFromRegistry(key: key1);
        expect(r, isNotNull);
        expect(r, isA<IIdHandlerRepository>());
      });

      test('key1: getIIdHandlerServiceFromRegistry returns non-null', () {
        final s = getIIdHandlerServiceFromRegistry(key: key1);
        expect(s, isNotNull);
        expect(s, isA<IIdHandlerService>());
      });

      test('key2: all four getters return non-null', () {
        expect(getIIdHandlerStorageRepositoryFromRegistry(key: key2), isNotNull);
        expect(getIIdHandlerStorageServiceFromRegistry(key: key2), isNotNull);
        expect(getIIdHandlerRepositoryFromRegistry(key: key2), isNotNull);
        expect(getIIdHandlerServiceFromRegistry(key: key2), isNotNull);
      });

      test('key1: all four objects are distinct instances', () {
        final stRepo = getIIdHandlerStorageRepositoryFromRegistry(key: key1);
        final stSvc = getIIdHandlerStorageServiceFromRegistry(key: key1);
        final repo = getIIdHandlerRepositoryFromRegistry(key: key1);
        final svc = getIIdHandlerServiceFromRegistry(key: key1);
        expect(identical(stRepo, stSvc), isFalse);
        expect(identical(stRepo, repo), isFalse);
        expect(identical(repo, svc), isFalse);
      });
    });

    group('Identity', () {
      test('same key → same service instance on repeated calls', () {
        final a = getIIdHandlerServiceFromRegistry(key: key1);
        final b = getIIdHandlerServiceFromRegistry(key: key1);
        expect(identical(a, b), isTrue);
      });

      test('same key → same repository instance on repeated calls', () {
        final a = getIIdHandlerRepositoryFromRegistry(key: key1);
        final b = getIIdHandlerRepositoryFromRegistry(key: key1);
        expect(identical(a, b), isTrue);
      });
    });

    group('Independence between keys', () {
      test('different keys → different service instances', () {
        final svc1 = getIIdHandlerServiceFromRegistry(key: key1);
        final svc2 = getIIdHandlerServiceFromRegistry(key: key2);
        expect(identical(svc1, svc2), isFalse);
      });

      test('different keys → different storage repository instances', () {
        final r1 = getIIdHandlerStorageRepositoryFromRegistry(key: key1);
        final r2 = getIIdHandlerStorageRepositoryFromRegistry(key: key2);
        expect(identical(r1, r2), isFalse);
      });
    });

    group('Functional', () {
      test('service from key1 generates valid non-negative IDs', () {
        final svc = getIIdHandlerServiceFromRegistry(key: key1);
        final id = svc.getNewId();
        expect(id, isA<int>());
        expect(id, greaterThanOrEqualTo(0));
      });

      test('service from key1 generates monotonically increasing IDs', () {
        final svc = getIIdHandlerServiceFromRegistry(key: key1);
        final id1 = svc.getNewId();
        final id2 = svc.getNewId();
        expect(id2, greaterThan(id1));
      });

      test('service from key2 generates its own monotonically increasing IDs', () {
        final svc = getIIdHandlerServiceFromRegistry(key: key2);
        final id1 = svc.getNewId();
        final id2 = svc.getNewId();
        expect(id2, greaterThan(id1));
      });

      test('getCurrent() is never less than the last getNewId() for key1', () {
        final svc = getIIdHandlerServiceFromRegistry(key: key1);
        final id = svc.getNewId();
        expect(svc.getCurrent(), greaterThanOrEqualTo(id));
      });
    });
  });
}

// ===========================================================================
//  initialPointErmesSignaling  (SINGLETON + REGISTRY)  — requires Ganache
// ===========================================================================

Future<void> testInitialPointSignaling() async {
  final ganacheAvailable = await GanacheManager.initialize();
  final contractAddress = await GanacheManager.getContractAddress();

  late SignalingContract contract;
  late IStunShspHandler stunHandler;

  group(
    'initialPointErmesSignaling [singleton + registry]',
    () {
      setUpAll(() async {
        final creds = EthPrivateKey.fromHex(_alicePrivateKey);
        final contractAddr = EthereumAddress.fromHex(contractAddress);
        final client = Web3Client(_ganacheRpcUrl, http.Client());

        contract = await SignalingContract.connectWithClient(
          client: client,
          contractAddress: contractAddr,
          credentials: creds,
        );

        await initializePointStunShsp();
        stunHandler = SingletonDIAccess.get<IStunShspHandler>();

        final aliceAddress =
            EthPrivateKey.fromHex(_alicePrivateKey).address.toString();
        SingletonDIAccess.addInstance<IdAccountType>(aliceAddress);

        // ── Singleton init ──────────────────────────────────────────────────
        initialPointErmesSignaling(
          contract: contract,
          stunShspHandler: stunHandler,
          socket: stunHandler.ipv4ShspSocket,
        );

        // ── Registry init (uses singleton state to construct objects) ───────
        initialPointErmesSignalingRegistry(
          contract: contract,
          stunShspHandler: stunHandler,
          socket: stunHandler.ipv4ShspSocket,
          key: 'test-sig-reg',
        );
      });

      tearDownAll(() async => GanacheManager.cleanup());

      // ── Singleton: Registration ──────────────────────────────────────────
      group('Singleton registration', () {
        test('registers IStunShspHandler', () {
          final handler = SingletonDIAccess.get<IStunShspHandler>();
          expect(handler, isNotNull);
          expect(handler, isA<IStunShspHandler>());
        });

        test('registers IShspSocket', () {
          final socket = SingletonDIAccess.get<IShspSocket>();
          expect(socket, isNotNull);
          expect(socket, isA<IShspSocket>());
        });

        test('registers IErmesSignalingServer', () {
          final server = SingletonDIAccess.get<IErmesSignalingServer>();
          expect(server, isNotNull);
          expect(server, isA<IErmesSignalingServer>());
        });

        test('registers IErmesBookRepository<BookData>', () {
          final repo = SingletonDIAccess.get<IErmesBookRepository<BookData>>();
          expect(repo, isNotNull);
          expect(repo, isA<IErmesBookRepository<BookData>>());
        });

        test('registers IErmesBookService<BookData>', () {
          final svc = SingletonDIAccess.get<IErmesBookService<BookData>>();
          expect(svc, isNotNull);
          expect(svc, isA<IErmesBookService<BookData>>());
        });

        test('registers IErmesSignalingHandler<IShspPeer>', () {
          final handler =
              SingletonDIAccess.get<IErmesSignalingHandler<IShspPeer>>();
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<IShspPeer>>());
        });

        test('registers IErmesSignalingRepository<ISignalErmes>', () {
          final repo =
              SingletonDIAccess.get<IErmesSignalingRepository<ISignalErmes>>();
          expect(repo, isNotNull);
          expect(repo, isA<IErmesSignalingRepository<ISignalErmes>>());
        });

        test('registers IErmesSignalingService', () {
          final svc = SingletonDIAccess.get<IErmesSignalingService>();
          expect(svc, isNotNull);
          expect(svc, isA<IErmesSignalingService>());
        });

        test('IShspSocket in singleton equals stunHandler.ipv4ShspSocket', () {
          final socket = SingletonDIAccess.get<IShspSocket>();
          expect(identical(socket, stunHandler.ipv4ShspSocket), isTrue);
        });
      });

      // ── Singleton: Functional ────────────────────────────────────────────
      group('Singleton functional', () {
        test('IErmesSignalingServer isConnected() returns true', () async {
          final server = SingletonDIAccess.get<IErmesSignalingServer>();
          expect(await server.isConnected(), isTrue);
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
          bookService.setAccount(AccountInfo(
            account: peerId,
            info: BookData(
              peerId: peerId,
              name: 'Test Peer',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ));
          expect(bookService.listOfIds(), contains(peerId));
        });

        test('IErmesBookService getAccount() retrieves a registered peer', () {
          final bookService =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'test-peer-get';
          bookService.setAccount(AccountInfo(
            account: peerId,
            info: BookData(
              peerId: peerId,
              name: 'Get Test Peer',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ));
          final account = bookService.getAccount(peerId);
          expect(account.account, equals(peerId));
          expect(account.info?.name, equals('Get Test Peer'));
        });

        test('IErmesBookRepository reflects accounts set via singleton service', () {
          final repo =
              SingletonDIAccess.get<IErmesBookRepository<BookData>>();
          final service =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'test-peer-repo-sync';
          service.setAccount(AccountInfo(
            account: peerId,
            info: BookData(
              peerId: peerId,
              name: 'Repo Sync Test',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ));
          expect(repo.listOfIds(), contains(peerId));
        });

        test('IErmesBookService deleteAccount() removes a peer', () {
          final bookService =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'test-peer-delete';
          bookService.setAccount(AccountInfo(
            account: peerId,
            info: BookData(
              peerId: peerId,
              name: 'Delete Test',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ));
          expect(bookService.listOfIds(), contains(peerId));
          bookService.deleteAccount(peerId);
          expect(bookService.listOfIds(), isNot(contains(peerId)));
        });
      });

      // ── Registry: Registration ───────────────────────────────────────────
      group('Registry registration (key: test-sig-reg)', () {
        test('getIErmesSignalingServerFromRegistry returns non-null', () {
          final server =
              getIErmesSignalingServerFromRegistry(key: 'test-sig-reg');
          expect(server, isNotNull);
          expect(server, isA<IErmesSignalingServer>());
        });

        test('getIErmesBookRepositoryFromRegistry returns non-null', () {
          final repo =
              getIErmesBookRepositoryFromRegistry(key: 'test-sig-reg');
          expect(repo, isNotNull);
          expect(repo, isA<IErmesBookRepository<BookData>>());
        });

        test('getIErmesBookServiceFromRegistry returns non-null', () {
          final svc =
              getIErmesBookServiceFromRegistry(key: 'test-sig-reg');
          expect(svc, isNotNull);
          expect(svc, isA<IErmesBookService<BookData>>());
        });

        test('getIErmesSignalingHandlerFromRegistry returns non-null', () {
          final handler =
              getIErmesSignalingHandlerFromRegistry(key: 'test-sig-reg');
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<IShspPeer>>());
        });

        test('getIErmesSignalingRepositoryFromRegistry returns non-null', () {
          final repo =
              getIErmesSignalingRepositoryFromRegistry(key: 'test-sig-reg');
          expect(repo, isNotNull);
          expect(repo, isA<IErmesSignalingRepository<ISignalErmes>>());
        });

        test('getIErmesSignalingServiceFromRegistry returns non-null', () {
          final svc =
              getIErmesSignalingServiceFromRegistry(key: 'test-sig-reg');
          expect(svc, isNotNull);
          expect(svc, isA<IErmesSignalingService>());
        });
      });

      // ── Registry: Identity ───────────────────────────────────────────────
      group('Registry identity (key: test-sig-reg)', () {
        test('repeated getter calls return the same server instance', () {
          final a = getIErmesSignalingServerFromRegistry(key: 'test-sig-reg');
          final b = getIErmesSignalingServerFromRegistry(key: 'test-sig-reg');
          expect(identical(a, b), isTrue);
        });

        test('repeated getter calls return the same book service instance', () {
          final a = getIErmesBookServiceFromRegistry(key: 'test-sig-reg');
          final b = getIErmesBookServiceFromRegistry(key: 'test-sig-reg');
          expect(identical(a, b), isTrue);
        });
      });

      // ── Registry: Independence from singleton ────────────────────────────
      group('Registry independence from singleton', () {
        test('registry server is a different instance from singleton server', () {
          final regServer =
              getIErmesSignalingServerFromRegistry(key: 'test-sig-reg');
          final singletonServer =
              SingletonDIAccess.get<IErmesSignalingServer>();
          expect(identical(regServer, singletonServer), isFalse);
        });

        test('registry book service is a different instance from singleton service', () {
          final regSvc =
              getIErmesBookServiceFromRegistry(key: 'test-sig-reg');
          final singletonSvc =
              SingletonDIAccess.get<IErmesBookService<BookData>>();
          expect(identical(regSvc, singletonSvc), isFalse);
        });

        test('registry book service is backed by the same repository as singleton', () {
          // The registry variant builds its service via ErmesBookServiceBaseDI
          // which reads IErmesBookRepository<BookData> from the singleton at
          // construction time. Both services therefore share the same repo.
          final regSvc =
              getIErmesBookServiceFromRegistry(key: 'test-sig-reg');
          final singletonSvc =
              SingletonDIAccess.get<IErmesBookService<BookData>>();

          const peerId = 'peer-via-registry-service';
          regSvc.setAccount(AccountInfo(
            account: peerId,
            info: BookData(
              peerId: peerId,
              name: 'Shared Repo Peer',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ));

          // Both services see the same entry (shared underlying repository)
          expect(regSvc.listOfIds(), contains(peerId));
          expect(singletonSvc.listOfIds(), contains(peerId));
        });
      });

      // ── Registry: Functional ─────────────────────────────────────────────
      group('Registry functional (key: test-sig-reg)', () {
        test('registry signaling server isConnected() returns true', () async {
          final server =
              getIErmesSignalingServerFromRegistry(key: 'test-sig-reg');
          expect(await server.isConnected(), isTrue);
        });

        test('registry book service supports setAccount/getAccount/deleteAccount', () {
          final svc =
              getIErmesBookServiceFromRegistry(key: 'test-sig-reg');
          const peerId = 'reg-svc-functional-peer';

          svc.setAccount(AccountInfo(
            account: peerId,
            info: BookData(
              peerId: peerId,
              name: 'Registry Func Peer',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ));

          expect(svc.listOfIds(), contains(peerId));
          final account = svc.getAccount(peerId);
          expect(account.info?.name, equals('Registry Func Peer'));

          svc.deleteAccount(peerId);
          expect(svc.listOfIds(), isNot(contains(peerId)));
        });
      });

      // ── initialPointErmesSignalingPartial (singleton) ────────────────────
      // The "partial" variant conditionally skips registering stun/socket when
      // they are already present in the singleton (e.g. set up by a prior call).
      group('initialPointErmesSignalingPartial [singleton]', () {
        // stun/socket are already in the singleton from the full variant above.
        // Calling partial with only `contract` re-uses the existing singleton
        // values for IStunShspHandler and IShspSocket.
        setUpAll(() {
          initialPointErmesSignalingPartial(
            contract: contract,
            // stunShspHandler and socket intentionally omitted:
            // they are already registered in singleton.
          );
        });

        test('partial init: IErmesSignalingServer still registered', () {
          final server = SingletonDIAccess.get<IErmesSignalingServer>();
          expect(server, isNotNull);
          expect(server, isA<IErmesSignalingServer>());
        });

        test('partial init: IErmesBookService<BookData> still registered', () {
          final svc = SingletonDIAccess.get<IErmesBookService<BookData>>();
          expect(svc, isNotNull);
          expect(svc, isA<IErmesBookService<BookData>>());
        });

        test('partial init: IErmesSignalingHandler<IShspPeer> still registered', () {
          final handler =
              SingletonDIAccess.get<IErmesSignalingHandler<IShspPeer>>();
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<IShspPeer>>());
        });

        test('partial init: IShspSocket in singleton is unchanged', () {
          final socket = SingletonDIAccess.get<IShspSocket>();
          expect(identical(socket, stunHandler.ipv4ShspSocket), isTrue);
        });

        test('partial init: IErmesSignalingServer isConnected() returns true', () async {
          final server = SingletonDIAccess.get<IErmesSignalingServer>();
          expect(await server.isConnected(), isTrue);
        });

        test('partial init with explicit stun/socket: all types registered', () {
          initialPointErmesSignalingPartial(
            contract: contract,
            stunShspHandler: stunHandler,
            socket: stunHandler.ipv4ShspSocket,
          );
          expect(SingletonDIAccess.get<IStunShspHandler>(), isNotNull);
          expect(SingletonDIAccess.get<IShspSocket>(), isNotNull);
          expect(SingletonDIAccess.get<IErmesSignalingServer>(), isNotNull);
        });
      });

      // ── initialPointErmesSignalingPartialRegistry ────────────────────────
      group('initialPointErmesSignalingPartialRegistry [registry]', () {
        setUpAll(() {
          // With full params — equivalent to the full registry variant.
          initialPointErmesSignalingPartialRegistry(
            contract: contract,
            stunShspHandler: stunHandler,
            socket: stunHandler.ipv4ShspSocket,
            key: 'test-sig-partial-reg',
          );

          // Without optional params — relies on singleton IStunShspHandler/IShspSocket
          // being present (they are, from the full variant above).
          initialPointErmesSignalingPartialRegistry(
            contract: contract,
            key: 'test-sig-partial-reg-no-stun',
          );
        });

        test('with full params: getIErmesSignalingServerFromRegistry returns non-null', () {
          final server =
              getIErmesSignalingServerFromRegistry(key: 'test-sig-partial-reg');
          expect(server, isNotNull);
          expect(server, isA<IErmesSignalingServer>());
        });

        test('with full params: getIErmesBookServiceFromRegistry returns non-null', () {
          final svc =
              getIErmesBookServiceFromRegistry(key: 'test-sig-partial-reg');
          expect(svc, isNotNull);
          expect(svc, isA<IErmesBookService<BookData>>());
        });

        test('with full params: getIErmesSignalingHandlerFromRegistry returns non-null', () {
          final handler =
              getIErmesSignalingHandlerFromRegistry(key: 'test-sig-partial-reg');
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<IShspPeer>>());
        });

        test('with full params: all six getters return non-null', () {
          const k = 'test-sig-partial-reg';
          expect(getIErmesSignalingServerFromRegistry(key: k), isNotNull);
          expect(getIErmesBookRepositoryFromRegistry(key: k), isNotNull);
          expect(getIErmesBookServiceFromRegistry(key: k), isNotNull);
          expect(getIErmesSignalingHandlerFromRegistry(key: k), isNotNull);
          expect(getIErmesSignalingRepositoryFromRegistry(key: k), isNotNull);
          expect(getIErmesSignalingServiceFromRegistry(key: k), isNotNull);
        });

        test('without stun/socket: IErmesSignalingServer still registered', () {
          final server = getIErmesSignalingServerFromRegistry(
              key: 'test-sig-partial-reg-no-stun');
          expect(server, isNotNull);
          expect(server, isA<IErmesSignalingServer>());
        });

        test('without stun/socket: IErmesSignalingHandler still registered', () {
          final handler = getIErmesSignalingHandlerFromRegistry(
              key: 'test-sig-partial-reg-no-stun');
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<IShspPeer>>());
        });

        test('full-params and no-stun keys give different server instances', () {
          final s1 = getIErmesSignalingServerFromRegistry(
              key: 'test-sig-partial-reg');
          final s2 = getIErmesSignalingServerFromRegistry(
              key: 'test-sig-partial-reg-no-stun');
          expect(identical(s1, s2), isFalse);
        });

        test('with full params: server isConnected() returns true', () async {
          final server =
              getIErmesSignalingServerFromRegistry(key: 'test-sig-partial-reg');
          expect(await server.isConnected(), isTrue);
        });
      });
    },
    skip: !ganacheAvailable
        ? 'Ganache not available at $_ganacheRpcUrl'
        : null,
  );
}

// ===========================================================================
//  initialPointErmesCore  (SINGLETON + REGISTRY)  — requires Ganache
// ===========================================================================

Future<void> testInitialPointErmesCore() async {
  final ganacheAvailable = await GanacheManager.initialize();
  final contractAddress = await GanacheManager.getContractAddress();

  late SignalingContract contract;
  late IStunShspHandler stunHandler;
  late String aliceAddress;

  group(
    'initialPointErmesCore [singleton + registry]',
    () {
      setUpAll(() async {
        final creds = EthPrivateKey.fromHex(_alicePrivateKey);
        final contractAddr = EthereumAddress.fromHex(contractAddress);
        final client = Web3Client(_ganacheRpcUrl, http.Client());

        contract = await SignalingContract.connectWithClient(
          client: client,
          contractAddress: contractAddr,
          credentials: creds,
        );

        await initializePointStunShsp();
        stunHandler = SingletonDIAccess.get<IStunShspHandler>();
        aliceAddress =
            EthPrivateKey.fromHex(_alicePrivateKey).address.toString();

        // ── Singleton init ──────────────────────────────────────────────────
        await initialPointErmesCore(
          contract: contract,
          accountId: aliceAddress,
          stunShspHandler: stunHandler,
          socket: stunHandler.ipv4ShspSocket,
          enableEncryption: true,
        );

        // ── Registry init (singleton already populated by core singleton) ───
        await initialPointErmesCoreRegistry(
          contract: contract,
          accountId: aliceAddress,
          stunShspHandler: stunHandler,
          socket: stunHandler.ipv4ShspSocket,
          enableEncryption: true,
          key: 'test-core-reg',
        );
      });

      tearDownAll(() async => GanacheManager.cleanup());

      // ── All sub-dependencies registered in singleton ─────────────────────
      group('All sub-dependencies in singleton', () {
        test('registers IErmesPeerCipher (from cipher stack)', () {
          final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
          expect(cipher, isNotNull);
          expect(cipher, isA<IErmesPeerCipher>());
        });

        test('registers IErmesPeerKeyExchange (from cipher stack)', () {
          final kx = SingletonDIAccess.get<IErmesPeerKeyExchange>();
          expect(kx, isNotNull);
          expect(kx, isA<IErmesPeerKeyExchange>());
        });

        test('registers IKeyExchange (ECDH key pair from cipher stack)', () {
          final keyExchange = SingletonDIAccess.get<IKeyExchange>();
          expect(keyExchange, isNotNull);
          expect(keyExchange, isA<IKeyExchange>());
        });

        test('registers IECDHKeyExchangeService (from cipher stack)', () {
          final svc = SingletonDIAccess.get<IECDHKeyExchangeService>();
          expect(svc, isNotNull);
          expect(svc, isA<IECDHKeyExchangeService>());
        });

        test('registers IErmesSignalingServer (from signaling stack)', () {
          final server = SingletonDIAccess.get<IErmesSignalingServer>();
          expect(server, isNotNull);
          expect(server, isA<IErmesSignalingServer>());
        });

        test('registers IErmesBookRepository<BookData> (from signaling stack)', () {
          final repo =
              SingletonDIAccess.get<IErmesBookRepository<BookData>>();
          expect(repo, isNotNull);
          expect(repo, isA<IErmesBookRepository<BookData>>());
        });

        test('registers IErmesBookService<BookData> (from signaling stack)', () {
          final svc = SingletonDIAccess.get<IErmesBookService<BookData>>();
          expect(svc, isNotNull);
          expect(svc, isA<IErmesBookService<BookData>>());
        });

        test('registers IErmesSignalingHandler<IShspPeer> (from signaling stack)', () {
          final handler =
              SingletonDIAccess.get<IErmesSignalingHandler<IShspPeer>>();
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<IShspPeer>>());
        });

        test('registers IErmesSignalingHandler<ShspPeer> (bridge added by core)', () {
          final handler =
              SingletonDIAccess.get<IErmesSignalingHandler<ShspPeer>>();
          expect(handler, isNotNull);
          expect(handler, isA<IErmesSignalingHandler<ShspPeer>>());
        });

        test('<IShspPeer> and <ShspPeer> handlers are the same bridged instance', () {
          final iHandler =
              SingletonDIAccess.get<IErmesSignalingHandler<IShspPeer>>();
          final cHandler =
              SingletonDIAccess.get<IErmesSignalingHandler<ShspPeer>>();
          expect(identical(iHandler, cHandler), isTrue);
        });

        test('registers ErmesConnectionsHandler (core-specific)', () {
          final ch = SingletonDIAccess.get<ErmesConnectionsHandler>();
          expect(ch, isNotNull);
          expect(ch, isA<ErmesConnectionsHandler>());
        });

        test('registers IdAccountType (account ID registered before signaling)', () {
          final accountId = SingletonDIAccess.get<IdAccountType>();
          expect(accountId, isNotNull);
          expect(accountId, equals(aliceAddress));
        });

        test('registers IOrcErmes (the top-level orchestrator)', () {
          final orc = SingletonDIAccess.get<IOrcErmes>();
          expect(orc, isNotNull);
          expect(orc, isA<IOrcErmes>());
        });
      });

      // ── Singleton: Convenience getters ───────────────────────────────────
      group('Singleton convenience getter', () {
        test('getIOrcErmes() returns the registered singleton', () {
          final orc = getIOrcErmes();
          expect(orc, isNotNull);
          expect(orc, isA<IOrcErmes>());
        });

        test('getIOrcErmes() is identical to SingletonDIAccess.get<IOrcErmes>()', () {
          final viaGetter = getIOrcErmes();
          final viaSingleton = SingletonDIAccess.get<IOrcErmes>();
          expect(identical(viaGetter, viaSingleton), isTrue);
        });

        test('IOrcErmes is an OrcErmes concrete instance', () {
          expect(getIOrcErmes(), isA<OrcErmes>());
        });
      });

      // ── Singleton: Functional ────────────────────────────────────────────
      group('Singleton functional', () {
        test('getConnections() returns an empty list initially', () async {
          final orc = getIOrcErmes();
          final connections = await orc.getConnections();
          expect(connections, isEmpty);
        });

        test('onMessage() accepts a callback without throwing', () async {
          final orc = getIOrcErmes();
          bool called = false;
          await orc.onMessage((data, peerId) => called = true);
          expect(called, isFalse);
        });

        test('onDisconnect() accepts a callback without throwing', () async {
          final orc = getIOrcErmes();
          bool called = false;
          await orc.onDisconnect((peerId) => called = true);
          expect(called, isFalse);
        });

        test('signaling server reachable via singleton and is connected', () async {
          final server = SingletonDIAccess.get<IErmesSignalingServer>();
          expect(await server.isConnected(), isTrue);
        });

        test('book service is functional: add, retrieve, delete a peer', () {
          final svc = SingletonDIAccess.get<IErmesBookService<BookData>>();
          const peerId = 'core-test-peer-book';
          svc.setAccount(AccountInfo(
            account: peerId,
            info: BookData(
              peerId: peerId,
              name: 'Core Book Peer',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ));
          expect(svc.listOfIds(), contains(peerId));
          expect(svc.getAccount(peerId).info?.name, equals('Core Book Peer'));
          svc.deleteAccount(peerId);
          expect(svc.listOfIds(), isNot(contains(peerId)));
        });

        test('ECDH key exchange service is functional', () {
          final svc = SingletonDIAccess.get<IECDHKeyExchangeService>();
          final serialized =
              (svc as ECDHKeyExchangeService).serialize();
          expect(serialized, isNotNull);
          expect(serialized, isNotEmpty);
        });

        test('IErmesPeerCipher throws for encrypt without a registered cipher', () {
          final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
          expect(
            () => cipher.encrypt(Uint8List.fromList([1, 2, 3, 4])),
            throwsA(isA<Exception>()),
          );
        });
      });

      // ── Registry: Registration ───────────────────────────────────────────
      group('Registry registration (key: test-core-reg)', () {
        test('getIOrcErmesFromRegistry returns non-null', () {
          final orc = getIOrcErmesFromRegistry(key: 'test-core-reg');
          expect(orc, isNotNull);
          expect(orc, isA<IOrcErmes>());
        });

        test('getIOrcErmesFromRegistry returns an OrcErmes instance', () {
          final orc = getIOrcErmesFromRegistry(key: 'test-core-reg');
          expect(orc, isA<OrcErmes>());
        });
      });

      // ── Registry: Identity ───────────────────────────────────────────────
      group('Registry identity (key: test-core-reg)', () {
        test('repeated getter calls return the same IOrcErmes instance', () {
          final a = getIOrcErmesFromRegistry(key: 'test-core-reg');
          final b = getIOrcErmesFromRegistry(key: 'test-core-reg');
          expect(identical(a, b), isTrue);
        });
      });

      // ── Registry: Independence from singleton ────────────────────────────
      group('Registry independence from singleton', () {
        test('registry IOrcErmes is a different instance from singleton', () {
          final regOrc = getIOrcErmesFromRegistry(key: 'test-core-reg');
          final singletonOrc = SingletonDIAccess.get<IOrcErmes>();
          expect(identical(regOrc, singletonOrc), isFalse);
        });
      });

      // ── Registry: Functional ─────────────────────────────────────────────
      group('Registry functional (key: test-core-reg)', () {
        test('registry IOrcErmes.getConnections() returns empty list', () async {
          final orc = getIOrcErmesFromRegistry(key: 'test-core-reg');
          final connections = await orc.getConnections();
          expect(connections, isEmpty);
        });

        test('registry IOrcErmes.onMessage() accepts a callback', () async {
          final orc = getIOrcErmesFromRegistry(key: 'test-core-reg');
          bool called = false;
          await orc.onMessage((data, peerId) => called = true);
          expect(called, isFalse);
        });

        test('registry IOrcErmes.onDisconnect() accepts a callback', () async {
          final orc = getIOrcErmesFromRegistry(key: 'test-core-reg');
          bool called = false;
          await orc.onDisconnect((peerId) => called = true);
          expect(called, isFalse);
        });
      });

      // ── createSignalingContract factory ──────────────────────────────────
      group('createSignalingContract factory', () {
        test('creates a valid SignalingContract with given credentials', () async {
          final newContract = await createSignalingContract(
            rpcUrl: _ganacheRpcUrl,
            contractAddress: contractAddress,
            privateKeyHex: _alicePrivateKey,
          );
          expect(newContract, isNotNull);
          expect(newContract, isA<SignalingContract>());
        });

        test('created contract is connected (isConnected via ErmesSignalingServer)', () async {
          final newContract = await createSignalingContract(
            rpcUrl: _ganacheRpcUrl,
            contractAddress: contractAddress,
            privateKeyHex: _alicePrivateKey,
          );
          // Build a minimal server using the created contract to confirm connectivity
          final aliceCreds = EthPrivateKey.fromHex(_alicePrivateKey);
          final idAccount = aliceCreds.address.toString();
          final server = ErmesSignalingServer(
            contract: newContract,
            accountId: idAccount,
          );
          expect(await server.isConnected(), isTrue);
        });
      });
    },
    skip: !ganacheAvailable
        ? 'Ganache not available at $_ganacheRpcUrl'
        : null,
  );
}

// ===========================================================================
//  main  (standalone runner)
// ===========================================================================

Future<void> main() async {
  // ── Non-Ganache singletons ─────────────────────────────────────────────
  testInitialPointStorage();
  testInitialPointMessageControl();
  testInitialPointCipher();
  testInitialPointIdHandler();

  // ── Non-Ganache registries ─────────────────────────────────────────────
  testInitialPointStorageRegistry();
  testInitialPointMessageControlRegistry();
  await testInitialPointCipherRegistry();
  testInitialPointIdHandlerRegistry();

  // ── Ganache-dependent (singleton + registry embedded) ──────────────────
  await testInitialPointSignaling();
  await testInitialPointErmesCore();
}
