import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// Tests the RFC section 10.2 eviction of the outbound retransmission
/// mapping: acknowledged ids are evicted, entries older than the 3600 s
/// retention window are evicted, and evicted ids are answered with `gone`.
void testErmesRetentionEviction() {
  group('Retransmission mapping retention', () {
    late TestErmesRepository repository;
    late IIdHandlerService idHandler;
    late ErmesSendRepo sendRepo;
    late DateTime now;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      repository = await TestErmesRepository.create(open: true);
      idHandler = IdHandlerServiceFactory.createDefault();
      sendRepo = ErmesSendRepo(repository, idHandler);
      await sendRepo.storageRoot.clear();
      now = DateTime(2026, 11, 20, 12);
      sendRepo.retention = ErmesRetransmissionRetention(
        storage: sendRepo.storageRoot,
        clock: () => now,
      );
    });

    tearDown(() => repository.cleanUp());

    Future<List<IdType>> sendData(int count) async {
      final ids = <IdType>[];
      for (var i = 0; i < count; i++) {
        await sendRepo.send(Uint8List.fromList([i, i + 1, i + 2]));
        ids.add(idHandler.getCurrent() - 1);
      }
      return ids;
    }

    MissingMessagesController controller() => MissingMessagesController(
          controlService: null,
          sendRepo: sendRepo,
          idHandler: idHandler,
          threshold: 0,
        );

    test('default window is 3600 seconds', () {
      expect(ermesRetransmissionRetention, const Duration(seconds: 3600));
      expect(sendRepo.retention.window, ermesRetransmissionRetention);
    });

    test('stored roots carry a timestamp', () async {
      final ids = await sendData(1);
      final root = await sendRepo.storageRoot.retrieve(ids.first);
      expect(root?.storedAtMs, now.millisecondsSinceEpoch);
    });

    test('ack evicts ids up to ackLastReceivedId only', () async {
      final ids = await sendData(4);
      await sendRepo.retention.evictAcknowledged(ids[1]);
      expect(await sendRepo.storageRoot.retrieve(ids[0]), isNull);
      expect(await sendRepo.storageRoot.retrieve(ids[1]), isNull);
      expect(await sendRepo.storageRoot.retrieve(ids[2]), isNotNull);
      expect(await sendRepo.storageRoot.retrieve(ids[3]), isNotNull);
    });

    test('handleAcknowledge evicts acknowledged ids', () async {
      final ids = await sendData(3);
      controller().handleAcknowledge(
        ServiceMessageAcknowledge(id: 99, ackLastReceivedId: ids[1]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await sendRepo.storageRoot.retrieve(ids[0]), isNull);
      expect(await sendRepo.storageRoot.retrieve(ids[1]), isNull);
      expect(await sendRepo.storageRoot.retrieve(ids[2]), isNotNull);
    });

    test('acked id is not resent and is answered with gone', () async {
      final ids = await sendData(2);
      await sendRepo.retention.evictAcknowledged(ids[0]);
      expect(await sendRepo.sendAgain(ids[0]), isFalse);
      final before = repository.sentData.length;
      await controller().sendMissingMessages([ids[0]]);
      expect(repository.sentData.length, before + 1);
    });

    test('entry younger than the window is kept', () async {
      final ids = await sendData(1);
      now = now.add(const Duration(seconds: 3599));
      expect(await sendRepo.sendAgain(ids.first), isTrue);
    });

    test('entry older than the window is evicted', () async {
      final ids = await sendData(1);
      now = now.add(const Duration(seconds: 3601));
      expect(await sendRepo.sendAgain(ids.first), isFalse);
      expect(await sendRepo.storageRoot.retrieve(ids.first), isNull);
    });

    test('evictExpired removes only expired entries', () async {
      final old = await sendData(1);
      now = now.add(const Duration(seconds: 3000));
      final fresh = await sendData(1);
      now = now.add(const Duration(seconds: 1000));
      await sendRepo.retention.evictExpired();
      expect(await sendRepo.storageRoot.retrieve(old.first), isNull);
      expect(await sendRepo.storageRoot.retrieve(fresh.first), isNotNull);
    });

    test('unstamped legacy entry is treated as expired', () async {
      final ids = await sendData(1);
      final root = await sendRepo.storageRoot.retrieve(ids.first);
      await sendRepo.storageRoot.store(MessageRootStorage(
        id: root!.id,
        messageSerialized: root.messageSerialized,
        integrityCheckValue: root.integrityCheckValue,
        digest: root.digest,
      ));
      expect(await sendRepo.sendAgain(ids.first), isFalse);
    });

    test('storedAt survives a JSON round trip', () {
      final root = MessageRootStorage(
        id: 7,
        messageSerialized: Uint8List.fromList([1, 2, 3]),
        integrityCheckValue: 'icv',
        storedAtMs: 1234,
      );
      final back = MessageRootStorage.fromJson(root.toJson());
      expect(back.storedAtMs, 1234);
    });
  });
}

void main() => testErmesRetentionEviction();
