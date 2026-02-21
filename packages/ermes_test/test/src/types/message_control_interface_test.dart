import 'package:ermes_core/ermes_core.dart';
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
      final opts = ErmesMessageControlServiceOpts(frequencyIdSaveState: 10);
      final service = ErmesMessageControlService(repo, opts)..idArrived(10);
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
}
