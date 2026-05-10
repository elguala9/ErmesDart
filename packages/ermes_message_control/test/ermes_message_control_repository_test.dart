import 'dart:async';

import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesMessageControlRepository', () {
    late ErmesMessageControlRepository repo;

    setUp(() {
      repo = ErmesMessageControlRepository();
    });

    test('should start with no last received ID', () {
      expect(repo.getLastReceivedId(), isNull);
    });

    test('should track sequential IDs', () {
      repo.idArrived(1);
      expect(repo.getLastReceivedId(), equals(1));

      repo.idArrived(2);
      expect(repo.getLastReceivedId(), equals(2));
    });

    test('should detect missing IDs after initial gap', () async {
      final completer = Completer<List<int>>();
      repo.setCallbackIdsToRequest((ids) async => completer.complete(ids.toList()));

      repo.idArrived(5);

      final missing = await completer.future;
      expect(repo.getLastReceivedId(), equals(5));
      expect(missing, containsAll([1, 2, 3, 4]));
    });

    test('should detect sequence gap', () async {
      final completer = Completer<List<int>>();
      repo.setCallbackIdsToRequest((ids) async => completer.complete(ids.toList()));

      repo.idArrived(1);
      repo.idArrived(5);

      final missing = await completer.future;
      expect(missing, containsAll([2, 3, 4]));
    });

    test('should handle out-of-order IDs', () async {
      final completer = Completer<List<int>>();
      repo.setCallbackIdsToRequest((ids) async => completer.complete(ids.toList()));

      repo.idArrived(1);
      repo.idArrived(5);
      await completer.future;
      repo.idArrived(3);

      expect(repo.numberOfMissingIds(), equals(2));
    });

    test('should return missing IDs sorted', () async {
      repo.idArrived(1);
      repo.idArrived(10);

      final missing = await repo.idsToRequest();
      expect(missing, equals([2, 3, 4, 5, 6, 7, 8, 9]));
    });

    test('should clear missing IDs', () async {
      repo.idArrived(1);
      repo.idArrived(10);

      await repo.clear();
      expect(repo.numberOfMissingIds(), equals(0));
    });

    test('should destroy and reset all state', () async {
      repo.idArrived(1);
      repo.idArrived(5);

      await repo.destroy();
      expect(repo.getLastReceivedId(), isNull);
      expect(repo.numberOfMissingIds(), equals(0));
    });

    test('saveState should not throw', () async {
      repo.idArrived(1);
      await repo.saveState();
    });

    test('loadState should not throw', () async {
      await repo.loadState();
    });

    test('lastId getter should return last received ID', () {
      expect(repo.lastId, isNull);

      repo.idArrived(5);
      expect(repo.lastId, equals(5));

      repo.idArrived(7);
      expect(repo.lastId, equals(7));
    });

    test('isMissing should detect missing IDs', () async {
      repo.idArrived(1);
      repo.idArrived(5);

      expect(repo.isMissing(2), isTrue);
      expect(repo.isMissing(3), isTrue);
      expect(repo.isMissing(4), isTrue);
      expect(repo.isMissing(1), isFalse);
      expect(repo.isMissing(5), isFalse);
      expect(repo.isMissing(99), isFalse);
    });

    test('getMissingIds should return sorted list', () async {
      repo.idArrived(1);
      repo.idArrived(5);

      final missing = repo.getMissingIds();
      expect(missing, equals([2, 3, 4]));
    });
  });
}
