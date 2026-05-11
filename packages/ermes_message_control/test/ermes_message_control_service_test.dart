import 'dart:async';

import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesMessageControlService', () {
    late ErmesMessageControlRepository repo;
    late ErmesMessageControlService service;

    setUp(() {
      repo = ErmesMessageControlRepository();
      service = ErmesMessageControlService.createWithRepository(repo);
    });

    test('should start with no last received ID', () {
      expect(service.getLastReceivedId(), isNull);
    });

    test('should delegate idArrived to repository', () {
      service.idArrived(1);
      expect(service.getLastReceivedId(), equals(1));
    });

    test('should return missing IDs', () async {
      service
        ..idArrived(1)
        ..idArrived(5);

      final missing = await service.idsToRequest();
      expect(missing, equals([2, 3, 4]));
    });

    test('should return number of missing IDs', () async {
      service
        ..idArrived(1)
        ..idArrived(5);

      expect(service.numberOfMissingIds(), equals(3));
    });

    test('should clear missing IDs', () async {
      service
        ..idArrived(1)
        ..idArrived(5);

      await service.clear();
      expect(service.numberOfMissingIds(), equals(0));
    });

    test('should register callback for missing IDs', () async {
      final completer = Completer<List<int>>();
      service
        ..setCallbackIdsToRequest(
          (ids) async => completer.complete(ids.toList()),
        )
        ..idArrived(1)
        ..idArrived(5);

      final missing = await completer.future;
      expect(missing, containsAll([2, 3, 4]));
    });

    test('should add ID request listener', () async {
      final completer = Completer<List<int>>();
      service
        ..addIdsToRequestListener(
          (ids) async => completer.complete(ids.toList()),
        )
        ..idArrived(1)
        ..idArrived(5);

      final missing = await completer.future;
      expect(missing, containsAll([2, 3, 4]));
    });

    test('should remove ID request listener', () async {
      var callCount = 0;
      Future<void> listener(List<int> ids) async => callCount++;

      service
        ..addIdsToRequestListener(listener)
        ..removeIdsToRequestListener(listener)
        ..idArrived(1)
        ..idArrived(5);

      await Future<void>.delayed(Duration.zero);
      expect(callCount, equals(0));
    });

    test('should clear all ID request listeners', () async {
      var callCount = 0;
      Future<void> listener1(List<int> ids) async => callCount++;
      Future<void> listener2(List<int> ids) async => callCount++;

      service
        ..addIdsToRequestListener(listener1)
        ..addIdsToRequestListener(listener2)
        ..clearIdsToRequestListeners()
        ..idArrived(1)
        ..idArrived(5);

      await Future<void>.delayed(Duration.zero);
      expect(callCount, equals(0));
    });

    test('should destroy and reset all state', () async {
      service
        ..idArrived(1)
        ..idArrived(5);

      await service.destroy();
      expect(service.getLastReceivedId(), isNull);
      expect(service.numberOfMissingIds(), equals(0));
    });

    test('should not auto-save before frequency threshold', () async {
      final repo = ErmesMessageControlRepository();
      final opts = ErmesMessageControlServiceOpts(frequencyIdSaveState: 3);
      final svc = ErmesMessageControlService.createWithRepository(repo, opts)
        ..idArrived(1)
        ..idArrived(5);

      // threshold is 3, only 1 gap change occurred -> no save
      // (saveState is a no-op anyway, but we verify no crash)
      expect(svc.numberOfMissingIds(), equals(3));
    });

    test('should delegate saveState to repository', () async {
      await service.saveState();
      // no-op, should not throw
    });
  });
}
