// ignore_for_file: cascade_invocations, lines_longer_than_80_chars
// This file can run standalone (dart test) or be imported by an aggregator.
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

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
    setUpAll(initialPointErmesCipher);

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

      test('all three registered objects are distinct instances', () {
        final cipher = SingletonDIAccess.get<IErmesPeerCipher>();
        final kx = SingletonDIAccess.get<IErmesPeerKeyExchange>();
        final keyExchange = SingletonDIAccess.get<IKeyExchange>();
        expect(identical(cipher, kx), isFalse);
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

    setUpAll(() {
      initialPointErmesCipherRegistry(key: key1);
      initialPointErmesCipherRegistry(key: key2);
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

      test('key2: all three getters return non-null', () {
        expect(getIErmesPeerCipherFromRegistry(key: key2), isNotNull);
        expect(getIErmesPeerKeyExchangeFromRegistry(key: key2), isNotNull);
        expect(getIKeyExchangeFromRegistry(key: key2), isNotNull);
      });

      test('key1: all three objects are distinct instances', () {
        final cipher = getIErmesPeerCipherFromRegistry(key: key1);
        final kx = getIErmesPeerKeyExchangeFromRegistry(key: key1);
        final keyExchange = getIKeyExchangeFromRegistry(key: key1);
        expect(identical(cipher, kx), isFalse);
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

  });
}

// ===========================================================================
//  initialPointIdHandler  (SINGLETON)
// ===========================================================================

void testInitialPointIdHandler() {
  group('initialPointIdHandler [singleton]', () {
    setUpAll(initialPointIdHandler);

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
//  main  (standalone runner)
// ===========================================================================

void main() {
  testInitialPointStorage();
  testInitialPointMessageControl();
  testInitialPointCipher();
  testInitialPointIdHandler();
  testInitialPointStorageRegistry();
  testInitialPointMessageControlRegistry();
  testInitialPointIdHandlerRegistry();
}
