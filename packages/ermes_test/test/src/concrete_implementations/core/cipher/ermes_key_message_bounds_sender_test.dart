import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

final _k1Hex = 'B' * 64;

/// The message carried by the last sent frame, decrypted with [rx].
MessageType _lastSent(TestErmesRepository repo, ErmesPeerCipher rx) {
  final root = uint8ArrayToObject<MessageRoot>(repo.sentData.last);
  final digest = root.digest ?? fail('frame is not encrypted');
  final plain = rx.decrypt(DataEncrypted(digest, root.messageSerialized));
  return uint8ArrayToObject<InternalMessage>(plain).message;
}

/// The newkey service message carried by [message].
ServiceMessageNewKey _newKey(MessageType message) {
  final service = message.asService();
  if (service is! ServiceMessageNewKey) {
    fail('expected a newkey service message, got $message');
  }
  return service;
}

/// Sender side of RFC section 7.4 and enforcement on the full read path.
void testKeyMessageBoundsSender() {
  group('sendNewKey fills startMessage / read path enforces it', () {
    late TestErmesRepository repository;
    late ErmesService service;
    late ICipher k0;
    late ErmesPeerCipher rx;
    var counter = 0;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      counter++;
      repository = await TestErmesRepository.create(
        open: true,
        peerId: 'key-bounds-peer-$counter',
      );
      service = ErmesServiceFactory.createService(
        100,
        1024,
        repository,
        IdHandlerServiceFactory.createDefault(),
        null,
        null,
        null,
        null,
        null,
      );
      k0 = generateSymmetric('A' * 64, SymmetricAlgorithm.aes);
      rx = ErmesPeerCipher()..addDecryptCipher(k0);
      ErmesPeerCipherHandler().set(
        repository.cipherKey,
        ErmesPeerCipher()..addEncryptCipher(k0),
      );
    });

    tearDown(() {
      ErmesReceiveStats.active = null;
      service.close();
      repository.cleanUp();
      ErmesPeerCipherHandler().remove(repository.cipherKey);
    });

    test('startMessage is newkey id + 1 and the next frame has it', () async {
      await service.sendNewKey(algorithm: SymmetricAlgorithm.aes, key: _k1Hex);
      final nk = _newKey(_lastSent(repository, rx));
      expect(nk.startMessage, nk.id + 1);
      expect(nk.endMessage, isNull);
      await service.send(Uint8List.fromList([1, 2, 3]));
      expect(_lastSent(repository, rx).id, nk.startMessage);
    });

    test('an explicit startMessage/endMessage is kept', () async {
      await service.sendNewKey(
        algorithm: SymmetricAlgorithm.aes,
        key: _k1Hex,
        startMessage: 500,
        endMessage: 900,
      );
      final nk = _newKey(_lastSent(repository, rx));
      expect([nk.startMessage, nk.endMessage], [500, 900]);
    });

    test('out-of-bounds inbound frame is dropped and counted once', () async {
      final stats = ErmesReceiveStats.active = ErmesReceiveStats();
      final cipher = ErmesPeerCipherHandler().get(repository.cipherKey);
      if (cipher == null) {
        fail('cipher not registered');
      }
      cipher.addDecryptCipher(k0, startMessage: 50);
      await service.ermesSendRepo.sendMessageType([
        MessageType.data(createMessageDataErmes(Uint8List.fromList([9]), 3)),
        MessageType.data(createMessageDataErmes(Uint8List.fromList([8]), 60)),
      ]);
      final sent = repository.sentData;
      sent.sublist(sent.length - 2).forEach(repository.simulateDataReceived);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(stats.dropKeyBounds, 1);
      expect(stats.decodeDropped, 0);
      expect(stats.failed, 0);
      expect(stats.frames, 2);
    });
  });
}

void main() {
  testKeyMessageBoundsSender();
}
