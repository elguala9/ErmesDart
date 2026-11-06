// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

/// RFC §9.3/§9.4: periodic, threshold and control-triggered checks must ask
/// the counterpart for missing inbound ids with a [ServiceMessageArrayRequest],
/// never resend our own outbound messages.
void testErmesServiceArrayRequest() {
  group('ErmesService missing-id array request (RFC §9.4)', () {
    late IIdHandlerService idHandler;
    late IErmesMessageControlService control;
    late TestErmesRepository repo;
    late ErmesService service;
    late List<ServiceMessage> sentService;
    var counter = 0;

    setUpAll(registerErmesStorageHandlers);

    Future<void> build({int? threshold, bool open = true}) async {
      counter++;
      idHandler = IdHandlerServiceFactory.createDefault();
      repo = await TestErmesRepository.create(
        open: open, peerId: 'array-req-peer-$counter',
      );
      control = ErmesMessageControlFactory.createBoth().$2;
      service = ErmesServiceFactory.createService(
        100, 1024, repo, idHandler, null, null, control, null, threshold,
      );
      sentService = [];
      service.ermesSendRepo.addOnMessageSendingListener((m) {
        final s = m.asService();
        if (s != null) {
          sentService.add(s);
        }
      });
    }

    tearDown(() {
      service.close();
      repo.cleanUp();
    });

    List<ServiceMessageArrayRequest> arrayRequests() =>
        sentService.whereType<ServiceMessageArrayRequest>().toList();

    Future<void> sendOwnMessages(int n) async {
      for (var i = 0; i < n; i++) {
        await service.send(Uint8List.fromList([i]));
      }
    }

    test('threshold path sends one array request with missing inbound ids', () async {
      await build();
      await sendOwnMessages(3);
      setupMissingIds(control, 2);
      final before = repo.sentData.length;

      await service.checkAndRequestMissingMessages();

      final reqs = arrayRequests();
      expect(reqs, hasLength(1));
      expect(reqs.single.arrayId, unorderedEquals(<int>[1, 2]));
      expect(repo.sentData.length - before, equals(1),
          reason: 'only the array request goes on the wire, no resend');
    });

    test('below threshold sends no array request', () async {
      await build(threshold: 5);
      setupMissingIds(control, 2);

      await service.checkAndRequestMissingMessages();

      expect(arrayRequests(), isEmpty);
    });

    test('no missing ids sends no array request', () async {
      await build();
      await sendOwnMessages(2);
      final before = repo.sentData.length;

      await service.checkAndRequestMissingMessages();

      expect(arrayRequests(), isEmpty);
      expect(repo.sentData.length, equals(before));
    });

    test('periodic timer sends array requests, not resends', () async {
      await build();
      await sendOwnMessages(3);
      setupMissingIds(control, 3);
      final before = repo.sentData.length;

      service.startMissingMessagesCheck(30);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      service.stopMissingMessagesCheck();

      final reqs = arrayRequests();
      expect(reqs, isNotEmpty);
      expect(reqs.first.arrayId, unorderedEquals(<int>[1, 2, 3]));
      expect(repo.sentData.length - before, equals(reqs.length));
    });

    test('received ServiceMessageControl triggers an array request', () async {
      await build();
      setupMissingIds(control, 2);

      _receiveService(repo, const ServiceMessageControl(id: 10));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final reqs = arrayRequests();
      expect(reqs, isNotEmpty);
      expect(reqs.first.arrayId, containsAll(<int>[1, 2]));
    });

    test('closed link sends no array request', () async {
      await build(open: false);
      setupMissingIds(control, 2);

      await service.checkAndRequestMissingMessages();

      expect(arrayRequests(), isEmpty,
          reason: 'a request sent into an outage is lost and opens a new gap');
    });

    test('back-to-back checks are throttled to one array request', () async {
      await build();
      setupMissingIds(control, 2);

      await service.checkAndRequestMissingMessages();
      await service.checkAndRequestMissingMessages();
      await service.checkAndRequestMissingMessages();

      expect(arrayRequests(), hasLength(1));
    });

    test('received array request still resends our outbound ids', () async {
      await build();
      await sendOwnMessages(2);
      final ownIds = List<int>.generate(idHandler.getCurrent() + 1, (i) => i);
      final before = repo.sentData.length;

      _receiveService(repo, ServiceMessageArrayRequest(id: 1, arrayId: ownIds));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(arrayRequests(), isEmpty);
      expect(repo.sentData.length, greaterThan(before));
    });
  });
}

void _receiveService(TestErmesRepository repo, ServiceMessage msg) {
  final internal = InternalMessage(
    message: MessageType.service(msg),
    type: MessageValue.service,
  );
  final serialized = objectToUint8Array(internal);
  final root = MessageRoot(
    messageSerialized: serialized,
    integrityCheckValue: calculateHashSync(serialized),
  );
  repo.simulateDataReceived(objectToUint8Array(root));
}

void main() {
  testErmesServiceArrayRequest();
}
