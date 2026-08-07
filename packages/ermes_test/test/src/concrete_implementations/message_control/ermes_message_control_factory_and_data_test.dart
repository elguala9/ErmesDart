import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:test/test.dart';

void testMessageControlData() {
  group('MessageControlData', () {
    test('should create with timestamp and missingIds', () {
      final data = MessageControlData(timestamp: 12345, missingIds: [2, 3, 4]);
      expect(data.timestamp, equals(12345));
      expect(data.missingIds, equals([2, 3, 4]));
    });

    test('should create with null missingIds', () {
      final data = MessageControlData(timestamp: 12345);
      expect(data.missingIds, isNull);
    });

    test('toMap should return correct map', () {
      final data = MessageControlData(timestamp: 12345, missingIds: [2, 3, 4]);
      final map = data.toMap();
      expect(map['timestamp'], equals(12345));
      expect(map['missing_ids'], equals([2, 3, 4]));
    });

    test('toMap should handle null missingIds', () {
      final data = MessageControlData(timestamp: 12345);
      final map = data.toMap();
      expect(map['timestamp'], equals(12345));
      expect(map['missing_ids'], isNull);
    });

    test('should create with an empty missingIds list', () {
      final data = MessageControlData(timestamp: 0, missingIds: const []);
      expect(data.missingIds, isEmpty);
      expect(data.toMap()['missing_ids'], isEmpty);
    });
  });
}

void testErmesMessageControlFactory() {
  group('ErmesMessageControlFactory', () {
    test('createRepository should create a valid repository', () {
      final repo = ErmesMessageControlFactory.createRepository();
      expect(repo, isNotNull);
      expect(repo.getLastReceivedId(), isNull);
    });

    test('createService should create service with given repository', () {
      final repo = ErmesMessageControlFactory.createRepository();
      final service = ErmesMessageControlFactory.createService(repo);
      expect(service, isNotNull);
      expect(service.getLastReceivedId(), isNull);
    });

    test('createService should use custom frequencyIdSaveState', () {
      final repo = ErmesMessageControlFactory.createRepository();
      final service = ErmesMessageControlFactory.createService(repo, 5);
      expect(service, isNotNull);
    });

    test('createBoth should create repository and service', () {
      final (repo, service) = ErmesMessageControlFactory.createBoth();
      expect(repo, isNotNull);
      expect(service, isNotNull);
      expect(service.getLastReceivedId(), isNull);
    });

    test('createBoth should wire service to repository', () {
      final (repo, service) = ErmesMessageControlFactory.createBoth();
      service
        ..idArrived(1)
        ..idArrived(5);

      expect(repo.getLastReceivedId(), equals(5));
      expect(repo.numberOfMissingIds(), equals(3));
      expect(service.numberOfMissingIds(), equals(3));
    });

    test('createService returns independent services for two repositories',
        () {
      final repoA = ErmesMessageControlFactory.createRepository();
      final repoB = ErmesMessageControlFactory.createRepository();
      final serviceA = ErmesMessageControlFactory.createService(repoA)
        ..idArrived(1);
      ErmesMessageControlFactory.createService(repoB).idArrived(9);

      expect(serviceA.getLastReceivedId(), equals(1));
      expect(repoB.getLastReceivedId(), equals(9));
    });

    test('createService with frequencyIdSaveState of 0 still tracks IDs',
        () {
      final repo = ErmesMessageControlFactory.createRepository();
      final service = ErmesMessageControlFactory.createService(repo, 0)
        ..idArrived(1)
        ..idArrived(3);

      expect(service.numberOfMissingIds(), equals(1));
    });
  });
}

void main() {
  testMessageControlData();
  testErmesMessageControlFactory();
}
