import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('MessageControl - getLastReceivedId()', () {
    test(
      'ErmesMessageControlRepository.getLastReceivedId() returns '
      'null initially',
      () {
        final repo = ErmesMessageControlRepository();

        final lastId = repo.getLastReceivedId();

        expect(lastId, isNull);
      },
    );

    test(
      'ErmesMessageControlRepository.getLastReceivedId() returns '
      'stored ID',
      () {
        final repo = ErmesMessageControlRepository()..idArrived(5);
        final lastId = repo.getLastReceivedId();

        expect(lastId, equals(5));
      },
    );

    test(
      'ErmesMessageControlRepository.getLastReceivedId() updates '
      'with new ID',
      () {
        final repo = ErmesMessageControlRepository()
          ..idArrived(5)
          ..idArrived(6);
        final lastId = repo.getLastReceivedId();

        expect(lastId, equals(6));
      },
    );

    test('ErmesMessageControlService.getLastReceivedId() works', () {
      final repo = ErmesMessageControlRepository();
      final opts = ErmesMessageControlServiceOpts();
      final service =
          ErmesMessageControlService.createWithRepository(repo, opts)
            ..idArrived(10);
      final lastId = service.getLastReceivedId();

      expect(lastId, equals(10));
    });

    test('idArrived triggers getLastReceivedId update', () {
      final repo = ErmesMessageControlRepository();

      expect(repo.getLastReceivedId(), isNull);

      repo.idArrived(1);
      expect(repo.getLastReceivedId(), equals(1));

      repo.idArrived(2);
      expect(repo.getLastReceivedId(), equals(2));

      repo.idArrived(3);
      expect(repo.getLastReceivedId(), equals(3));
    });
  });

  group('MessageControl - gap detection', () {
    test('no missing ids on contiguous sequence', () async {
      final repo = ErmesMessageControlRepository()
        ..idArrived(1)
        ..idArrived(2)
        ..idArrived(3);

      expect(repo.numberOfMissingIds(), equals(0));
      expect(await repo.idsToRequest(), isEmpty);
    });

    test('detects single gap', () async {
      final repo = ErmesMessageControlRepository()
        ..idArrived(1)
        ..idArrived(3);

      expect(repo.numberOfMissingIds(), equals(1));
      expect(await repo.idsToRequest(), equals(<IdType>[2]));
    });

    test('detects multi-element gap', () async {
      final repo = ErmesMessageControlRepository()
        ..idArrived(1)
        ..idArrived(5);

      expect(repo.numberOfMissingIds(), equals(3));
      expect(await repo.idsToRequest(), equals(<IdType>[2, 3, 4]));
    });

    test('first id > 1 fills the leading gap', () async {
      final repo = ErmesMessageControlRepository()..idArrived(4);

      expect(repo.numberOfMissingIds(), equals(3));
      expect(await repo.idsToRequest(), equals(<IdType>[1, 2, 3]));
    });

    test(
      'late delivery of a previously missing id removes it from the gap set',
      () async {
        final repo = ErmesMessageControlRepository()
          ..idArrived(1)
          ..idArrived(4)
          ..idArrived(2);

        expect(await repo.idsToRequest(), equals(<IdType>[3]));

        repo.idArrived(3);
        expect(await repo.idsToRequest(), isEmpty);
        expect(repo.numberOfMissingIds(), equals(0));
      },
    );

    test('double-delivery of an already-cleared id throws', () {
      final repo = ErmesMessageControlRepository()
        ..idArrived(1)
        ..idArrived(5)
        ..idArrived(2);

      // 2 was missing, then cleared. Replaying it should now throw.
      expect(
        () => repo.idArrived(2),
        throwsA(isA<MessageControlException>()),
      );
    });

    test('callback fires with sorted missing ids when a new gap appears',
        () async {
      final calls = <List<IdType>>[];
      final repo = ErmesMessageControlRepository()
        ..setCallbackIdsToRequest((ids) async => calls.add(ids))
        ..idArrived(1)
        ..idArrived(4);
      expect(repo.getLastReceivedId(), equals(4));

      expect(calls, isNotEmpty);
      expect(calls.last, equals(<IdType>[2, 3]));
    });

    test('clear() empties the missing-id set', () async {
      final repo = ErmesMessageControlRepository()
        ..idArrived(1)
        ..idArrived(5);

      expect(repo.numberOfMissingIds(), equals(3));

      await repo.clear();

      expect(repo.numberOfMissingIds(), equals(0));
      expect(await repo.idsToRequest(), isEmpty);
    });
  });
}
