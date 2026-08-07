import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void testIdHandlerFactory() {
  group('IdHandlerFactory', () {
    group('createRepository()', () {
      test('should create repository with default values', () {
        const input = IdHandlerRepositoryInput();
        final repository = IdHandlerFactory.createRepository(input);

        expect(repository.getCurrent(), equals(0));
        expect(repository.getNewId(), equals(0));
      });

      test('should create repository with custom max', () {
        const input = IdHandlerRepositoryInput(max: 100);
        final repository = IdHandlerFactory.createRepository(input)
          ..setCounter(99);
        expect(repository.getNewId(), equals(99));
        expect(repository.getNewId(), equals(100));
        expect(repository.getNewId(), equals(0));
      });

      test('should create repository with custom start', () {
        const input = IdHandlerRepositoryInput(start: 50);
        final repository = IdHandlerFactory.createRepository(input);

        expect(repository.getCurrent(), equals(50));
      });

      test('should create multiple independent repositories', () {
        const input1 = IdHandlerRepositoryInput(start: 0);
        const input2 = IdHandlerRepositoryInput(start: 100);

        final repo1 = IdHandlerFactory.createRepository(input1);
        final repo2 = IdHandlerFactory.createRepository(input2);

        expect(repo1.getNewId(), equals(0));
        expect(repo2.getNewId(), equals(100));
        expect(repo1.getNewId(), equals(1));
        expect(repo2.getNewId(), equals(101));
      });

      test('should propagate an invalid start as ArgumentError', () {
        const input = IdHandlerRepositoryInput(max: 10, start: 11);
        expect(
          () => IdHandlerFactory.createRepository(input),
          throwsArgumentError,
        );
      });
    });

    group('createService()', () {
      test('should create service with factory', () {
        const repoInput = IdHandlerRepositoryInput(start: 10);

        final service = IdHandlerFactory.createService(
          IdHandlerServiceInput(
            repo: IdHandlerFactory.createRepository(repoInput),
          ),
        );

        expect(service.getCurrent(), equals(10));
        expect(service.getNewId(), equals(10));
      });

      test('should build its own repository from inputForRepo when given',
          () {
        final service = IdHandlerFactory.createService(
          IdHandlerServiceInput(
            repo: IdHandlerFactory.createRepository(
              const IdHandlerRepositoryInput(),
            ),
          ),
          const IdHandlerRepositoryInput(start: 42),
        );

        // inputForRepo takes precedence over input.repo.
        expect(service.getCurrent(), equals(42));
      });

      test('should use the service input storage when supplied', () {
        final repo = IdHandlerFactory.createRepository(
          const IdHandlerRepositoryInput(),
        );
        final storage = IdHandlerStorageFactory.createDefault();

        final service = IdHandlerFactory.createService(
          IdHandlerServiceInput(repo: repo, storage: storage),
        );

        expect(service.getNewId, returnsNormally);
      });
    });
  });
}

void main() {
  testIdHandlerFactory();
}
