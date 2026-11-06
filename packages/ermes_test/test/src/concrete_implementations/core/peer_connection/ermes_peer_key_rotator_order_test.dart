import 'dart:async';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  testErmesPeerKeyRotatorOrder();
}

/// Decodes a sent [frame] as the receiver would, decrypting it with [rx].
/// Returns the frame's key digest and the carried message.
(Digest, MessageType) _openFrame(ErmesPeerCipher rx, Uint8List frame) {
  final root = uint8ArrayToObject<MessageRoot>(frame);
  final digest = root.digest ?? fail('frame is not encrypted');
  final plain = rx.decrypt(DataEncrypted(digest, root.messageSerialized));
  return (digest, uint8ArrayToObject<InternalMessage>(plain).message);
}

/// Extracts the [ServiceMessageNewKey] carried by [message].
ServiceMessageNewKey _newKeyOf(MessageType message) {
  final service = message.asService();
  if (service is! ServiceMessageNewKey) {
    fail('expected a newkey service message, got $message');
  }
  return service;
}

/// RFC §7.4: the `newkey` frame is encrypted under the outbound key current
/// before the rotation; the new key is used only afterwards.
void testErmesPeerKeyRotatorOrder() {
  group('ErmesPeerKeyRotator key ordering (RFC 7.4)', () {
    late TestErmesRepository repository;
    late ErmesService service;
    late ErmesPeerCipher sender;
    late ErmesPeerCipher receiver;
    late ISymmetricCipher k0;
    var counter = 0;
    String peer() => 'rotator-order-peer-$counter';

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      counter++;
      repository =
          await TestErmesRepository.create(open: true, peerId: peer());
      service = ErmesServiceFactory.createService(
        100, 1024, repository, IdHandlerServiceFactory.createDefault(),
        null, null, null, null, null,
      );
      k0 = generateSymmetric('A' * 64, SymmetricAlgorithm.aes);
      sender = ErmesPeerCipher()..addEncryptCipher(k0);
      receiver = ErmesPeerCipher()..addDecryptCipher(k0);
      ErmesPeerCipherHandler().set(peer(), sender);
    });

    tearDown(() {
      service.close();
      repository.cleanUp();
      ErmesPeerCipherHandler().remove(peer());
    });

    ErmesPeerKeyRotator rotator() => ErmesPeerKeyRotator(
          service: service, remotePeerId: peer(),
          intervalMessages: 1000, intervalSeconds: 3600);

    Future<Uint8List> sendData() async {
      final before = repository.sentData.length;
      await service.ermesSendRepo.sendMessageType([
        MessageType.data(
          MessageData(id: 900 + before, data: Uint8List.fromList([1, 2, 3])),
        ),
      ]);
      return repository.sentData.last;
    }

    test('newkey frame uses the old key, next data frame the new one',
        () async {
      final r = rotator();
      await r.rotate();
      final (digest, message) = _openFrame(receiver, repository.sentData.last);
      expect(digest, equals(k0.keyId));
      final k1 = generateSymmetric(_newKeyOf(message).key,
          SymmetricAlgorithm.aes);
      expect(sender.currentEncryptKeyId, equals(k1.keyId));
      receiver.addDecryptCipher(k1);
      final (dataDigest, _) = _openFrame(receiver, await sendData());
      expect(dataDigest, equals(k1.keyId));
      r.dispose();
    });

    test('receiver decrypts every newkey frame across several rotations',
        () async {
      final r = rotator();
      var expected = k0.keyId;
      for (var i = 0; i < 5; i++) {
        await r.rotate();
        final (digest, message) =
            _openFrame(receiver, repository.sentData.last);
        expect(digest, equals(expected), reason: 'rotation $i');
        final next = generateSymmetric(_newKeyOf(message).key,
            SymmetricAlgorithm.aes);
        receiver.addDecryptCipher(next);
        expected = next.keyId;
        expect(_openFrame(receiver, await sendData()).$1, equals(expected));
      }
      r.dispose();
    });

    test('superseded outbound key is dropped after rotation', () async {
      final r = rotator();
      await r.rotate();
      expect(() => sender.setCurrentEncryptCipher(k0.keyId),
          throwsA(isA<CipherException>()));
      r.dispose();
    });

    test('overlapping rotations send a single newkey frame', () async {
      final r = rotator();
      await Future.wait<void>([r.rotate(), r.rotate()]);
      expect(repository.sentData, hasLength(1));
      r.dispose();
    });

    test('a frame for an unannounced key is not decryptable', () async {
      final r = rotator();
      await r.rotate();
      final frame = await sendData();
      expect(() => _openFrame(receiver, frame),
          throwsA(isA<CipherException>()));
      r.dispose();
    });

    test('does nothing after dispose', () async {
      final r = rotator()..dispose();
      await r.rotate();
      expect(repository.sentData, isEmpty);
      expect(sender.currentEncryptKeyId, equals(k0.keyId));
    });
  });
}
