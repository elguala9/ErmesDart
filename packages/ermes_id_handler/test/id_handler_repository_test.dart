import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:test/test.dart';

void main() {
  group('IdHandlerRepository', () {
    late IdHandlerRepository repository;

    setUp(() {
      repository = IdHandlerRepository();
    });

    test('should generate sequential IDs starting from 0', () {
      expect(repository.getNewId(), equals(0));
      expect(repository.getNewId(), equals(1));
      expect(repository.getNewId(), equals(2));
    });

    test('should maintain current counter', () {
      repository
        ..getNewId()
        ..getNewId();
      expect(repository.getCurrent(), equals(2));
    });

    test('should reset counter to 0', () {
      repository
        ..getNewId()
        ..getNewId()
        ..reset();
      expect(repository.getCurrent(), equals(0));
      expect(repository.getNewId(), equals(0));
    });

    test('should set counter to specific value', () {
      repository.setCounter(100);
      expect(repository.getCurrent(), equals(100));
      expect(repository.getNewId(), equals(100));
    });

    test('should wrap around when exceeding max value', () {
      final customRepo = IdHandlerRepository(max: 5, start: 4);
      expect(customRepo.getNewId(), equals(4));
      expect(customRepo.getNewId(), equals(5));
      expect(customRepo.getNewId(), equals(0));
      expect(customRepo.getNewId(), equals(1));
    });

    test('should reject negative counter', () {
      expect(() => repository.setCounter(-1), throwsArgumentError);
    });

    test('should reject counter exceeding max', () {
      final customRepo = IdHandlerRepository(max: 100);
      expect(() => customRepo.setCounter(101), throwsArgumentError);
    });

    test('should accept custom start value', () {
      final customRepo = IdHandlerRepository(start: 50);
      expect(customRepo.getCurrent(), equals(50));
      expect(customRepo.getNewId(), equals(50));
    });

    test('should reject start > max', () {
      expect(
        () => IdHandlerRepository(max: 10, start: 11),
        throwsArgumentError,
      );
    });

    test('should reject max < 1', () {
      expect(() => IdHandlerRepository(max: 0), throwsArgumentError);
    });
  });
}
