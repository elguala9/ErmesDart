import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

/// RFC section 9.5: a retransmission resends bit-for-bit the original
/// envelope, and the id is resendable as soon as it is on the wire.
void testErmesSendRepoBitForBit() {
  group('ErmesSendRepo bit-for-bit retransmission', () {
    late TestErmesRepository repository;
    late IIdHandlerService idHandler;
    late ErmesSendRepo sendRepo;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      repository = await TestErmesRepository.create(open: true);
      idHandler = IdHandlerServiceFactory.createDefault();
      sendRepo = ErmesSendRepo(repository, idHandler);
      await sendRepo.storageRoot.clear();
    });

    tearDown(() => repository.cleanUp());

    Future<IdType> sendOne() async {
      await sendRepo.send(Uint8List.fromList([1, 2, 3, 4]));
      return idHandler.getCurrent() - 1;
    }

    bool hasIdKey(Uint8List bytes) {
      final Object? json = jsonDecode(utf8.decode(bytes));
      return json is Map && json.containsKey('id');
    }

    test('sendAgain resends the exact bytes of the first send', () async {
      final id = await sendOne();
      expect(await sendRepo.sendAgain(id), isTrue);
      expect(repository.sentData, hasLength(2));
      expect(repository.sentData[1], orderedEquals(repository.sentData[0]));
      expect(hasIdKey(repository.sentData[1]), isFalse);
    });

    test('every chunk of a fragmented message resends unchanged', () async {
      await sendRepo.send(Uint8List.fromList(List.filled(3000, 7)));
      final first = List<Uint8List>.of(repository.sentData);
      expect(first.length, greaterThan(1));
      final ids = await sendRepo.storageRoot.listOfIds();
      for (final id in ids) {
        await sendRepo.sendAgain(id);
      }
      final resent = repository.sentData.sublist(first.length);
      for (final bytes in resent) {
        expect(first.any((f) => _sameBytes(f, bytes)), isTrue);
      }
    });

    test('an id is resendable as soon as it is on the wire', () async {
      final resent = <Future<bool>>[];
      var armed = true;
      repository.onSend = (_) {
        if (armed) {
          armed = false;
          resent.add(sendRepo.sendAgain(idHandler.getCurrent() - 1));
        }
      };
      await sendOne();
      expect(await resent.single, isTrue);
      expect(repository.sentData, hasLength(2));
      expect(repository.sentData[1], orderedEquals(repository.sentData[0]));
    });

    test('the stored envelope equals the bytes sent', () async {
      final id = await sendOne();
      final root = await sendRepo.storageRoot.retrieve(id);
      expect(root?.envelope, orderedEquals(repository.sentData.single));
    });

    test('legacy entry without envelope resends without the id key', () async {
      final id = await sendOne();
      final stored = await sendRepo.storageRoot.retrieve(id);
      await sendRepo.storageRoot.store(MessageRootStorage(
        id: id,
        messageSerialized: stored!.messageSerialized,
        messageJson: stored.messageJson,
        integrityCheckValue: stored.integrityCheckValue,
        digest: stored.digest,
        storedAtMs: stored.storedAtMs,
      ));
      expect(await sendRepo.sendAgain(id), isTrue);
      expect(hasIdKey(repository.sentData.last), isFalse);
    });

    test('sendAgain of an unknown id sends nothing and returns false',
        () async {
      expect(await sendRepo.sendAgain(424242), isFalse);
      expect(repository.sentData, isEmpty);
    });

    test('envelope survives a JSON round-trip; absent means null', () {
      final root = MessageRootStorage(
        id: 1,
        messageSerialized: Uint8List.fromList([1]),
        integrityCheckValue: 'x',
        digest: Digest(const [1]),
        envelope: Uint8List.fromList([9, 8, 7]),
      );
      final back = MessageRootStorage.fromJson(root.toJson());
      expect(back.envelope, orderedEquals([9, 8, 7]));
      final legacy = Map<String, dynamic>.of(root.toJson())..remove('envelope');
      expect(MessageRootStorage.fromJson(legacy).envelope, isNull);
    });
  });
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void main() => testErmesSendRepoBitForBit();
