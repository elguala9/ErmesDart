import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

/// Tests that [MissingMessagesController.handleAcknowledge] records the
/// counterpart's trailing ids from `ackCurrentId` (RFC section 9.2).
void testErmesServiceAckCurrent() {
  group('MissingMessagesController ackCurrentId', () {
    late TestErmesRepository repository;
    late IIdHandlerService idHandler;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      repository = await TestErmesRepository.create(open: true);
      idHandler = IdHandlerServiceFactory.createDefault();
    });

    tearDown(() => repository.cleanUp());

    MissingMessagesController controller(IErmesMessageControlService? c) =>
        MissingMessagesController(
          controlService: c,
          sendRepo: ErmesSendRepo(repository, idHandler),
          idHandler: idHandler,
          threshold: null,
        );

    test('trailing loss is recorded and requested on next check', () async {
      final (_, control) = ErmesMessageControlFactory.createBoth();
      control
        ..idArrived(1)
        ..idArrived(2)
        ..idArrived(3);
      final missing = controller(control)
        ..handleAcknowledge(
          const ServiceMessageAcknowledge(id: 6, ackCurrentId: 5),
        );
      expect(await control.idsToRequest(), equals([4, 5]));
      final before = repository.sentData.length;
      await missing.handleMissingMessages();
      expect(repository.sentData.length, greaterThan(before));
    });

    test('ackCurrentId not above contiguous id records nothing', () async {
      final (_, control) = ErmesMessageControlFactory.createBoth();
      control
        ..idArrived(1)
        ..idArrived(2);
      controller(control).handleAcknowledge(
        const ServiceMessageAcknowledge(id: 3, ackCurrentId: 2),
      );
      expect(await control.idsToRequest(), isEmpty);
    });

    test('without a control service ackCurrentId is ignored', () {
      expect(
        () => controller(null).handleAcknowledge(
          const ServiceMessageAcknowledge(id: 3, ackCurrentId: 9),
        ),
        returnsNormally,
      );
    });
  });
}

void main() {
  testErmesServiceAckCurrent();
}
