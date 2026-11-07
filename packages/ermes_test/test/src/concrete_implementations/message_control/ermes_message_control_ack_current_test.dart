import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:test/test.dart';

/// Tests for recording trailing lost ids from the counterpart's
/// `ackCurrentId` (RFC section 9.2).
void testErmesMessageControlAckCurrent() {
  group('ErmesMessageControlRepository counterpartCurrentId', () {
    late ErmesMessageControlRepository repo;

    setUp(() {
      repo = ErmesMessageControlRepository()
        ..idArrived(1)
        ..idArrived(2)
        ..idArrived(3);
    });

    test('trailing loss 4, 5 is recorded as missing', () async {
      repo.counterpartCurrentId(5);
      expect(await repo.idsToRequest(), equals([4, 5]));
      expect(repo.getLastReceivedId(), equals(3));
      expect(repo.lastId, equals(5));
    });

    test('notifies the missing-ids callback', () {
      List<int>? notified;
      repo
        ..setCallbackIdsToRequest((ids) async => notified = ids)
        ..counterpartCurrentId(5);
      expect(notified, equals([4, 5]));
    });

    test('value equal to or below contiguous id is a no-op', () {
      var calls = 0;
      repo
        ..setCallbackIdsToRequest((ids) async => calls++)
        ..counterpartCurrentId(3)
        ..counterpartCurrentId(1);
      expect(repo.numberOfMissingIds(), equals(0));
      expect(repo.lastId, equals(3));
      expect(calls, equals(0));
    });

    test('value below highest seen adds nothing new', () {
      repo
        ..idArrived(6)
        ..counterpartCurrentId(5);
      expect(repo.getMissingIds(), equals([4, 5]));
      expect(repo.lastId, equals(6));
    });

    test('later real arrivals fill the gap without a new one', () {
      var calls = 0;
      repo
        ..counterpartCurrentId(5)
        ..setCallbackIdsToRequest((ids) async => calls++)
        ..idArrived(4)
        ..idArrived(5);
      expect(repo.numberOfMissingIds(), equals(0));
      expect(repo.getLastReceivedId(), equals(5));
      expect(calls, equals(0));
      repo.idArrived(6);
      expect(repo.getLastReceivedId(), equals(6));
    });

    test('before any arrival records 1..id as missing', () async {
      final fresh = ErmesMessageControlRepository()..counterpartCurrentId(2);
      expect(await fresh.idsToRequest(), equals([1, 2]));
      expect(fresh.getLastReceivedId(), equals(0));
    });

    test('service delegates to the repository', () async {
      final (_, service) = ErmesMessageControlFactory.createBoth();
      service
        ..idArrived(1)
        ..counterpartCurrentId(3);
      expect(await service.idsToRequest(), equals([2, 3]));
    });
  });
}

void main() {
  testErmesMessageControlAckCurrent();
}
