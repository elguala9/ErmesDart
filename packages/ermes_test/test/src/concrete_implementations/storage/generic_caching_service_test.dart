import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('GenericCachingService', () {
    group('delegates to repository correctly', () {
      late GenericCachingRepository<String, String> repo;
      late GenericCachingService<String, String> service;

      setUp(() {
        repo = GenericCachingRepository<String, String>(5);
        service = GenericCachingService<String, String>(repo);
      });

      tearDown(() async => service.destroy());

      test('store and retrieve', () async {
        await service.store('k', 'v');
        expect(await service.retrieve('k'), equals('v'));
      });

      test('numberOfElements reflects repository state', () async {
        await service.store('a', '1');
        await service.store('b', '2');
        expect(service.numberOfElements(), equals(2));
        expect(service.numberOfElements(), equals(repo.numberOfElements()));
      });

      test('delete removes entry', () async {
        await service.store('x', 'data');
        expect(await service.delete('x'), isTrue);
        expect(await service.retrieve('x'), isNull);
      });

      test('listOfIds returns all keys', () async {
        await service.store('p', '1');
        await service.store('q', '2');
        final ids = await service.listOfIds();
        expect(ids.toSet(), equals({'p', 'q'}));
      });

      test('clear empties the cache', () async {
        await service.store('a', '1');
        await service.clear();
        expect(service.numberOfElements(), equals(0));
      });

      test('destroy clears all data', () async {
        await service.store('a', '1');
        await service.store('b', '2');
        await service.destroy();
        expect(service.numberOfElements(), equals(0));
      });
    });

    group('with custom repository', () {
      test('accepts IGenericCachingRepository interface', () {
        final IGenericCachingRepository<int, double> customRepo =
            GenericCachingRepository<int, double>(20);
        final svc = GenericCachingService<int, double>(customRepo);
        expect(svc, isA<IGenericCachingService<int, double>>());
      });

      test('multiple service instances share independent repositories',
          () async {
        final repo1 = GenericCachingRepository<String, int>(10);
        final repo2 = GenericCachingRepository<String, int>(10);
        final svc1 = GenericCachingService<String, int>(repo1);
        final svc2 = GenericCachingService<String, int>(repo2);

        await svc1.store('key', 1);
        expect(await svc1.retrieve('key'), equals(1));
        expect(await svc2.retrieve('key'), isNull);

        await repo1.destroy();
        await repo2.destroy();
      });
    });
  });
}
