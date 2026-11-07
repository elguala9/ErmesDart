import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:test/test.dart';

/// Tests for highest-contiguous tracking and stale-id deduplication
/// (RFC section 9.1 and section 9.2).
void testErmesMessageControlContiguous() {
  group('ErmesMessageControlRepository contiguous id', () {
    late ErmesMessageControlRepository repo;

    setUp(() {
      repo = ErmesMessageControlRepository();
    });

    test('1, 2, 5 yields contiguous 2 and highest seen 5', () {
      repo
        ..idArrived(1)
        ..idArrived(2)
        ..idArrived(5);
      expect(repo.getLastReceivedId(), equals(2));
      expect(repo.lastId, equals(5));
    });

    test('filling the gap in order advances contiguous to 5', () {
      repo
        ..idArrived(1)
        ..idArrived(2)
        ..idArrived(5)
        ..idArrived(3);
      expect(repo.getLastReceivedId(), equals(3));
      repo.idArrived(4);
      expect(repo.getLastReceivedId(), equals(5));
    });

    test('filling out of order advances only after the lowest arrives', () {
      repo
        ..idArrived(1)
        ..idArrived(2)
        ..idArrived(5)
        ..idArrived(4);
      expect(repo.getLastReceivedId(), equals(2));
      repo.idArrived(3);
      expect(repo.getLastReceivedId(), equals(5));
    });

    test('stale duplicate id does not throw and changes nothing', () {
      repo
        ..idArrived(1)
        ..idArrived(2)
        ..idArrived(5);
      expect(() => repo.idArrived(1), returnsNormally);
      expect(() => repo.idArrived(5), returnsNormally);
      expect(repo.getMissingIds(), equals([3, 4]));
      expect(repo.getLastReceivedId(), equals(2));
      expect(repo.lastId, equals(5));
    });

    test('duplicate does not notify the missing-ids callback', () {
      var calls = 0;
      repo
        ..setCallbackIdsToRequest((ids) async => calls++)
        ..idArrived(1)
        ..idArrived(3);
      expect(calls, equals(1));
      repo
        ..idArrived(1)
        ..idArrived(3);
      expect(calls, equals(1));
    });

    test('first id 0 yields contiguous 0', () {
      repo.idArrived(0);
      expect(repo.getLastReceivedId(), equals(0));
    });

    test('first id above 1 yields contiguous 0', () {
      repo.idArrived(4);
      expect(repo.getLastReceivedId(), equals(0));
      expect(repo.highestContiguousId, equals(0));
    });

    test('clear() makes contiguous jump to highest seen', () async {
      repo
        ..idArrived(1)
        ..idArrived(6);
      await repo.clear();
      expect(repo.getLastReceivedId(), equals(6));
      expect(repo.numberOfMissingIds(), equals(0));
    });

    test('destroy() resets contiguous and highest seen', () async {
      repo
        ..idArrived(1)
        ..idArrived(6);
      await repo.destroy();
      expect(repo.getLastReceivedId(), isNull);
      expect(repo.lastId, isNull);
    });

    test('service reports contiguous id from the repository', () {
      final (_, service) = ErmesMessageControlFactory.createBoth();
      service
        ..idArrived(1)
        ..idArrived(4);
      expect(service.getLastReceivedId(), equals(1));
    });
  });
}

void main() {
  testErmesMessageControlContiguous();
}
