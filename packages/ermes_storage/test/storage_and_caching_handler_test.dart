import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesStorageAndCachingMessagesHandlerBase', () {
    late ErmesStorageAndCachingMessagesHandlerBase<MessageRootStorage> handler;

    setUp(() {
      handler = ErmesStorageAndCachingMessagesHandlerBase<MessageRootStorage>();
    });

    test('should return null for unknown connection', () {
      final instance = handler.get('unknown_connection');
      expect(instance, isNull);
    });

    test('should create and return peer storage instance', () {
      final peerInstance = handler.forPeer('peer_1');
      expect(peerInstance, isNotNull);
      expect(peerInstance.peerId, equals('peer_1'));
      expect(peerInstance.messageRoot, isNotNull);
      expect(peerInstance.messageType, isNotNull);
    });

    test('should return same instance for same peer', () {
      final instance1 = handler.forPeer('peer_1');
      final instance2 = handler.forPeer('peer_1');
      expect(identical(instance1, instance2), isTrue);
    });

    test('should create different instances for different peers', () {
      final instance1 = handler.forPeer('peer_a');
      final instance2 = handler.forPeer('peer_b');
      expect(identical(instance1, instance2), isFalse);
    });
  });

  group('ErmesStorageAndCachingMessagesHandler', () {
    test('should be a singleton', () {
      final instance1 = ErmesStorageAndCachingMessagesHandler.instance;
      final instance2 = ErmesStorageAndCachingMessagesHandler.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should provide forPeer functionality', () {
      final handler = ErmesStorageAndCachingMessagesHandler.instance;
      final peerInstance = handler.forPeer('test_peer');
      expect(peerInstance.peerId, equals('test_peer'));
    });
  });

  group('PeerStorageInstance', () {
    test('should create instance with peerId', () {
      final instance = PeerStorageInstance('peer_42');
      expect(instance.peerId, equals('peer_42'));
      expect(instance.messageRoot, isNotNull);
      expect(instance.messageType, isNotNull);
    });

    test('should isolate data between different peer instances', () async {
      final instanceA = PeerStorageInstance('peer_a');
      final instanceB = PeerStorageInstance('peer_b');

      await instanceA.messageRoot.store(MessageRootStorage(
        id: 1,
        messageSerialized: Uint8List.fromList([1]),
        integrityCheckValue: 'a',
      ));

      expect((await instanceA.messageRoot.retrieve(1))!.integrityCheckValue,
          equals('a'));
      expect(await instanceB.messageRoot.retrieve(1), isNull);
    });
  });
}
