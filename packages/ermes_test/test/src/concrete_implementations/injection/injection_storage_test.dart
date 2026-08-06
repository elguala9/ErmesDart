// This file can run standalone (dart test) or be imported by an aggregator.
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

/// Coverage for [registerErmesStorageHandlers].
///
/// Since singleton_manager 2.x there is one keyed registry rather than a
/// separate global container, so the former "singleton" and "registry" suites
/// collapse into this single keyed one.
void testInjectionStorage() {
  group('registerErmesStorageHandlers', () {
    const key1 = 'test-storage-injection-1';
    const key2 = 'test-storage-injection-2';

    setUpAll(() {
      registerErmesStorageHandlers(key: key1);
      registerErmesStorageHandlers(key: key2);
    });

    group('Registration', () {
      test('registers the MessageRoot handler', () {
        expect(
          getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1),
          isA<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(),
        );
      });

      test('registers the MessageType handler', () {
        expect(
          getErmesStorageAndCachingMessagesHandlerBaseMessageType(key: key1),
          isA<ErmesStorageAndCachingMessagesHandlerBaseMessageType>(),
        );
      });

      test('the accessor and a direct registry lookup agree', () {
        final viaGetter =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1);
        final viaRegistry = RegistryManager.instance.getInstance<
            ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(key: key1);
        expect(identical(viaGetter, viaRegistry), isTrue);
      });

      test('MessageRoot and MessageType are distinct handlers', () {
        final root =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1);
        final type =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType(key: key1);
        expect(identical(root, type), isFalse);
      });
    });

    group('Identity', () {
      test('same key returns the same MessageRoot handler', () {
        expect(
          identical(
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1),
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1),
          ),
          isTrue,
        );
      });

      test('same key returns the same MessageType handler', () {
        expect(
          identical(
            getErmesStorageAndCachingMessagesHandlerBaseMessageType(key: key1),
            getErmesStorageAndCachingMessagesHandlerBaseMessageType(key: key1),
          ),
          isTrue,
        );
      });
    });

    group('Independence between keys', () {
      test('different keys get different MessageRoot handlers', () {
        expect(
          identical(
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1),
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key2),
          ),
          isFalse,
        );
      });

      test('different keys get different MessageType handlers', () {
        expect(
          identical(
            getErmesStorageAndCachingMessagesHandlerBaseMessageType(key: key1),
            getErmesStorageAndCachingMessagesHandlerBaseMessageType(key: key2),
          ),
          isFalse,
        );
      });

      test('forPeer caches are isolated between keys', () {
        const peerId = 'peer-storage-isolation';
        final fromKey1 =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1)
                .forPeer(peerId);
        final fromKey2 =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key2)
                .forPeer(peerId);
        expect(identical(fromKey1, fromKey2), isFalse);
      });
    });

    group('Functional', () {
      test('MessageRoot forPeer returns the same instance for the same peer',
          () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1);
        const peerId = 'peer-storage-001';
        final i1 = handler.forPeer(peerId);
        final i2 = handler.forPeer(peerId);
        expect(i1, isNotNull);
        expect(identical(i1, i2), isTrue);
      });

      test('MessageRoot forPeer returns different instances per peer', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1);
        expect(
          identical(
            handler.forPeer('peer-storage-A'),
            handler.forPeer('peer-storage-B'),
          ),
          isFalse,
        );
      });

      test('MessageType forPeer returns the same instance for the same peer',
          () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageType(key: key1);
        const peerId = 'peer-storage-type-same';
        final i1 = handler.forPeer(peerId);
        expect(i1, isNotNull);
        expect(identical(i1, handler.forPeer(peerId)), isTrue);
      });

      test('get returns null for an unregistered connection ID', () {
        final handler =
            getErmesStorageAndCachingMessagesHandlerBaseMessageRoot(key: key1);
        expect(handler.get('nonexistent-conn-id'), isNull);
      });
    });
  });
}

void main() {
  testInjectionStorage();
}
