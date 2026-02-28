
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';


void testIErmesMessageControlRepository(
  String name,
  IErmesMessageControlRepository Function() create,
) {
  group('IErmesMessageControlRepository - $name', () {
    late IErmesMessageControlRepository repo;

    setUp(() {
      repo = create();
    });

    test('idArrived and idsToRequest', () async {
      repo.idArrived(1);
      final list = await repo.idsToRequest();
      expect(list, isA<List<int>>());
    });

    test('clear and destroy', () async {
      await repo.clear();
      await repo.destroy();
    });
  });
}


void testIErmesMessageControlService(
  String name,
  IErmesMessageControlService Function() create,
) {
  group('IErmesMessageControlService - $name', () {
    late IErmesMessageControlService svc;

    setUp(() {
      svc = create();
    });

    test('numberOfMissingIds and setCallbackIdsToRequest', () {
      final n = svc.numberOfMissingIds();
      expect(n, isA<int>());
      svc.setCallbackIdsToRequest((ids) async {});
    });
  });
}
