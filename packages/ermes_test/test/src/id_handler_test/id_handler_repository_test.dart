// ignore_for_file: cascade_invocations

import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:test/test.dart';

void testIdHandlerRepository() {
  group('IdHandlerRepository', () {
    late IdHandlerRepository repository;

    setUp(() {
      repository = IdHandlerRepository();
    });

    group('constructor', () {
      test('should generate sequential IDs starting from 0', () {
        expect(repository.getNewId(), equals(0));
        expect(repository.getNewId(), equals(1));
        expect(repository.getNewId(), equals(2));
      });

      test('should handle custom start value', () {
        final customRepo = IdHandlerRepository(start: 50);

        expect(customRepo.getCurrent(), equals(50));
        expect(customRepo.getNewId(), equals(50));
      });

      test('should reject a max below 1', () {
        expect(() => IdHandlerRepository(max: 0), throwsArgumentError);
      });

      test('should reject a negative max', () {
        expect(() => IdHandlerRepository(max: -1), throwsArgumentError);
      });

      test('should accept max of exactly 1', () {
        final repo = IdHandlerRepository(max: 1);
        expect(repo.getNewId(), equals(0));
        expect(repo.getNewId(), equals(1));
        expect(repo.getNewId(), equals(0)); // wraps
      });

      test('should reject a negative start', () {
        expect(
          () => IdHandlerRepository(start: -1),
          throwsArgumentError,
        );
      });

      test('should reject a start greater than max', () {
        expect(
          () => IdHandlerRepository(max: 10, start: 11),
          throwsArgumentError,
        );
      });

      test('should accept start exactly equal to max', () {
        final repo = IdHandlerRepository(max: 10, start: 10);
        expect(repo.getCurrent(), equals(10));
        expect(repo.getNewId(), equals(10));
        expect(repo.getNewId(), equals(0)); // wraps immediately
      });
    });

    group('getNewId()', () {
      test('should wrap around when exceeding max value', () {
        final customRepo = IdHandlerRepository(max: 5, start: 4);

        expect(customRepo.getNewId(), equals(4)); // id 4
        expect(customRepo.getNewId(), equals(5)); // id 5, max reached
        expect(customRepo.getNewId(), equals(0)); // wraps to 0
        expect(customRepo.getNewId(), equals(1));
      });

      test('should handle large max values and wrap correctly', () {
        final largeRepo = IdHandlerRepository();

        largeRepo.setCounter(9007199254740990);

        expect(largeRepo.getNewId(), equals(9007199254740990));
        expect(largeRepo.getNewId(), equals(0)); // wraps
      });

      test('should generate 1000 sequential IDs without error', () {
        for (var i = 0; i < 1000; i++) {
          expect(repository.getNewId(), equals(i));
        }
      });
    });

    group('getCurrent()', () {
      test('should maintain current counter without advancing it', () {
        repository.getNewId(); // 0
        repository.getNewId(); // 1

        expect(repository.getCurrent(), equals(2));
        expect(repository.getCurrent(), equals(2)); // unchanged by re-reading
      });
    });

    group('reset()', () {
      test('should reset counter to zero', () {
        repository.getNewId();
        repository.getNewId();

        repository.reset();

        expect(repository.getCurrent(), equals(0));
        expect(repository.getNewId(), equals(0));
      });

      test('should be idempotent', () {
        repository.getNewId();
        repository
          ..reset()
          ..reset();

        expect(repository.getCurrent(), equals(0));
      });
    });

    group('setCounter()', () {
      test('should set counter to specific value', () {
        repository.setCounter(100);

        expect(repository.getCurrent(), equals(100));
        expect(repository.getNewId(), equals(100));
      });

      test('should reject a negative counter', () {
        expect(() => repository.setCounter(-1), throwsArgumentError);
      });

      test('should reject a counter exceeding max', () {
        final customRepo = IdHandlerRepository(max: 100);

        expect(() => customRepo.setCounter(101), throwsArgumentError);
      });

      test('should accept a counter of exactly 0', () {
        repository.setCounter(50);
        repository.setCounter(0);
        expect(repository.getNewId(), equals(0));
      });

      test('should accept a counter of exactly max', () {
        final customRepo = IdHandlerRepository(max: 10);
        customRepo.setCounter(10);
        expect(customRepo.getNewId(), equals(10));
        expect(customRepo.getNewId(), equals(0)); // wraps
      });

      test('should leave the counter unchanged after a rejected call', () {
        repository.setCounter(50);
        expect(() => repository.setCounter(-1), throwsArgumentError);
        expect(repository.getCurrent(), equals(50));
      });
    });

    group('concurrency', () {
      test('interleaved getNewId calls across two repositories stay '
          'independent', () {
        final repoA = IdHandlerRepository();
        final repoB = IdHandlerRepository(start: 100);

        final idsA = <int>[];
        final idsB = <int>[];
        for (var i = 0; i < 50; i++) {
          idsA.add(repoA.getNewId());
          idsB.add(repoB.getNewId());
        }

        expect(idsA, equals(List.generate(50, (i) => i)));
        expect(idsB, equals(List.generate(50, (i) => i + 100)));
      });
    });
  });
}

void main() {
  testIdHandlerRepository();
}
