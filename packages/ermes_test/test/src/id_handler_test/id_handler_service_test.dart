// ignore_for_file: cascade_invocations

import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

class _RecordingStorageService implements IIdHandlerStorageService {
  final List<IdType> updates = [];
  bool destroyCalled = false;
  bool closeCalled = false;
  bool saveCalled = false;

  @override
  void update(IdType id) => updates.add(id);

  @override
  void save() => saveCalled = true;

  @override
  void close() => closeCalled = true;

  @override
  void destroy() => destroyCalled = true;
}

void testIdHandlerService() {
  group('IdHandlerService', () {
    late IdHandlerService service;
    late IdHandlerRepository repository;

    setUp(() {
      repository = IdHandlerRepository();
      service = IdHandlerService.fromRepo(repo: repository);
    });

    group('fromRepo()', () {
      test('should generate IDs through the underlying repository', () {
        expect(service.getNewId(), equals(0));
        expect(service.getNewId(), equals(1));
        expect(service.getNewId(), equals(2));
      });

      test('should default to an in-memory storage service when none is '
          'given', () {
        expect(() => service.getNewId(), returnsNormally);
      });

      test('should work with a custom repository range', () {
        final customRepo = IdHandlerRepository(max: 10, start: 8);
        final customService = IdHandlerService.fromRepo(repo: customRepo);

        expect(customService.getNewId(), equals(8));
        expect(customService.getNewId(), equals(9));
        expect(customService.getNewId(), equals(10));
        expect(customService.getNewId(), equals(0)); // wraps
      });
    });

    group('getNewId()', () {
      test('should persist every generated ID through storage', () {
        final storage = _RecordingStorageService();
        final svc = IdHandlerService.fromRepo(
          repo: IdHandlerRepository(),
          storage: storage,
        );

        svc.getNewId();
        svc.getNewId();

        expect(storage.updates, equals([0, 1]));
      });
    });

    group('getCurrent()', () {
      test('should maintain the service counter without advancing it', () {
        service.getNewId();
        service.getNewId();

        expect(service.getCurrent(), equals(2));
        expect(service.getCurrent(), equals(2));
      });
    });

    group('reset()', () {
      test('should reset the underlying repository counter', () {
        service.getNewId();
        service.getNewId();

        service.reset();

        expect(service.getCurrent(), equals(0));
      });

      test('should not itself persist through storage (repo-only reset)',
          () {
        final storage = _RecordingStorageService();
        final svc = IdHandlerService.fromRepo(
          repo: IdHandlerRepository(),
          storage: storage,
        )..getNewId();
        storage.updates.clear();

        svc.reset();

        expect(storage.updates, isEmpty);
      });
    });

    group('setCounter()', () {
      test('should set the service counter', () {
        service.setCounter(50);

        expect(service.getCurrent(), equals(50));
        expect(service.getNewId(), equals(50));
      });

      test('should persist the new counter value through storage', () {
        final storage = _RecordingStorageService();
        final svc = IdHandlerService.fromRepo(
          repo: IdHandlerRepository(),
          storage: storage,
        );

        svc.setCounter(42);

        expect(storage.updates, equals([42]));
      });

      test('should propagate the repository ArgumentError for an invalid '
          'counter', () {
        expect(() => service.setCounter(-1), throwsArgumentError);
      });
    });

    group('storage error handling', () {
      test('a storage failure during getNewId propagates to the caller',
          () {
        final failingStorage = _FailingStorageService();
        final svc = IdHandlerService.fromRepo(
          repo: IdHandlerRepository(),
          storage: failingStorage,
        );

        expect(svc.getNewId, throwsA(isA<StateError>()));
      });
    });
  });
}

class _FailingStorageService implements IIdHandlerStorageService {
  @override
  void update(IdType id) => throw StateError('storage unavailable');

  @override
  void save() {}

  @override
  void close() {}

  @override
  void destroy() {}
}

void main() {
  testIdHandlerService();
}
