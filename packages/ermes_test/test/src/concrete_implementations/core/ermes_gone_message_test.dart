// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

/// RFC section 7.2 / 7.3 / 10.2: unavailable retransmissions are answered
/// with `gone`, and a `gone` discards the whole refId group.
void testErmesGoneMessage() {
  group('ServiceMessageGone serialization', () {
    test('round-trips with reason gone', () {
      const msg = ServiceMessageGone(id: 7, arrayId: [3, 4]);
      final json = msg.toJson();
      expect(json['reason'], equals('gone'));
      final parsed = ServiceMessage.fromJson(json);
      expect(parsed, isA<ServiceMessageGone>());
      expect(parsed, equals(msg));
    });

    test('is not parsed as an array request', () {
      final parsed = ServiceMessage.fromJson(
        <String, dynamic>{'id': 1, 'reason': 'gone', 'arrayId': [9]},
      );
      expect(parsed, isNot(isA<ServiceMessageArrayRequest>()));
    });

    test('unknown reason without arrayId still throws', () {
      expect(
        () => ServiceMessage.fromJson(<String, dynamic>{'id': 1, 'reason': 'zz'}),
        throwsArgumentError,
      );
    });
  });

  group('IErmesMessageControlService.idGone', () {
    test('stops requesting a gone id', () async {
      final control = ErmesMessageControlFactory.createBoth().$2
        ..idArrived(1)
        ..idArrived(4)
        ..idGone(2);
      expect(await control.idsToRequest(), equals(<int>[3]));
    });

    test('ignores an id that is not missing', () {
      final control = ErmesMessageControlFactory.createBoth().$2..idArrived(1);
      expect(() => control.idGone(42), returnsNormally);
      expect(control.numberOfMissingIds(), equals(0));
    });
  });

  test('chunkArrayBuffer reserves a contiguous id block', () {
    final idHandler = IdHandlerServiceFactory.createDefault()..getNewId();
    final chunks =
        chunkArrayBuffer(idHandler, Uint8List(25), 'ref', 10);
    final first = chunks.first.id;
    for (final c in chunks) {
      expect(c.id, equals(first + c.index));
    }
  });

  _testChunkGroups();
  _testServiceGone();
}

void _testChunkGroups() {
  group('ErmesChunkGroups', () {
    ChunkMessage c(int id, int index) =>
        ChunkMessage(data: Uint8List(1), index: index, roof: 3, id: id, refId: 'r');

    test('discardGone returns every member id of the hit group', () {
      final groups = ErmesChunkGroups()..add(c(10, 0));
      expect(groups.discardGone([12]), equals(<int>[10, 11, 12]));
      expect(groups.isPending('r'), isFalse);
    });

    test('late chunks of a discarded group are ignored', () {
      final groups = ErmesChunkGroups()
        ..add(c(10, 0))
        ..discardGone([11]);
      expect(groups.add(c(11, 1)), isNull);
      expect(groups.isPending('r'), isFalse);
    });

    test('a gone outside the range discards nothing', () {
      final groups = ErmesChunkGroups()..add(c(10, 0));
      expect(groups.discardGone([13, 9]), isEmpty);
      expect(groups.isPending('r'), isTrue);
    });

    test('a complete group is no longer pending', () {
      final groups = ErmesChunkGroups()..add(c(10, 0))..add(c(11, 1));
      expect(groups.add(c(12, 2)), isNotNull);
      expect(groups.discardGone([11]), isEmpty);
    });
  });
}

void _testServiceGone() {
  group('ErmesService gone handling', () {
    late TestErmesRepository repo;
    late IErmesMessageControlService control;
    late ErmesService service;
    late List<ServiceMessage> sent;
    var counter = 0;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      counter++;
      repo = await TestErmesRepository.create(peerId: 'gone-peer-$counter');
      control = ErmesMessageControlFactory.createBoth().$2;
      service = ErmesServiceFactory.createService(100, 1024, repo,
          IdHandlerServiceFactory.createDefault(), null, null, control, null, null);
      sent = [];
      service.ermesSendRepo.addOnMessageSendingListener((m) {
        final s = m.asService();
        if (s != null) {
          sent.add(s);
        }
      });
    });

    tearDown(() {
      service.close();
      repo.cleanUp();
    });

    List<ServiceMessageGone> gones() =>
        sent.whereType<ServiceMessageGone>().toList();

    test('sendAgain reports an absent id', () async {
      expect(await service.ermesSendRepo.sendAgain(99999), isFalse);
    });

    test('array request for an absent id is answered with gone', () async {
      _receive(repo, const MessageType.service(
          ServiceMessageArrayRequest(id: 1, arrayId: [99999])));
      await _settle();
      expect(gones(), hasLength(1));
      expect(gones().single.arrayId, equals(<int>[99999]));
    });

    test('mixed request resends present ids and lists absent ones in one gone', () async {
      var present = -1;
      service.ermesSendRepo.addOnMessageSentListener((m) => present = m.id);
      await service.send(Uint8List.fromList([1]));
      final before = repo.sentData.length;
      _receive(repo, MessageType.service(ServiceMessageArrayRequest(
          id: 1, arrayId: [present, 88888, 99999])));
      await _settle();
      expect(gones().single.arrayId, equals(<int>[88888, 99999]));
      expect(repo.sentData.length - before, equals(2),
          reason: 'one resend plus one gone');
    });

    test('a received gone is never answered', () async {
      final before = repo.sentData.length;
      _receive(repo, const MessageType.service(
          ServiceMessageGone(id: 1, arrayId: [5])));
      await _settle();
      expect(repo.sentData.length, equals(before));
    });

    test('gone for one chunk id discards the whole refId group', () async {
      _receive(repo, _chunk(1, 0, 'grp'));
      _receive(repo, _chunk(3, 2, 'grp'));
      await _settle();
      expect(service.ermesReadRepo.hasPendingGroup('grp'), isTrue);
      expect(await control.idsToRequest(), equals(<int>[2]));

      _receive(repo, const MessageType.service(
          ServiceMessageGone(id: 4, arrayId: [2])));
      await _settle();

      expect(service.ermesReadRepo.hasPendingGroup('grp'), isFalse);
      expect(await control.idsToRequest(), isEmpty);
    });

    test('gone outside any group keeps pending groups', () async {
      _receive(repo, _chunk(1, 0, 'keep'));
      await _settle();
      service.ermesReadRepo.handleGone([50]);
      expect(service.ermesReadRepo.hasPendingGroup('keep'), isTrue);
    });
  });
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

MessageType _chunk(int id, int index, String refId) => MessageType.chunk(
      ChunkMessage(
        data: Uint8List.fromList([index]),
        index: index,
        roof: 3,
        id: id,
        refId: refId,
      ),
    );

void _receive(TestErmesRepository repo, MessageType message) {
  final internal = InternalMessage(message: message, type: message.getType());
  final serialized = objectToUint8Array(internal);
  final root = MessageRoot(
    messageSerialized: serialized,
    integrityCheckValue: calculateHashSync(serialized),
  );
  repo.simulateDataReceived(objectToUint8Array(root));
}

void main() {
  testErmesGoneMessage();
}
