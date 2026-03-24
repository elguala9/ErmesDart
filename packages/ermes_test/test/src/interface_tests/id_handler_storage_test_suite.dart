import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IIdHandlerStorageRepository and IIdHandlerStorageService
///
/// Validates that implementations conform to the ID handler storage contract
void testIdHandlerStorage(
  String name,
  IIdHandlerStorageRepository Function() create,
) {
  group('$name Tests', () {
    group('IIdHandlerStorageRepository', () {
      late IIdHandlerStorageRepository storage;

      setUp(() {
        storage = create();
      });

      test('should create instance', () {
        expect(storage, isNotNull);
      });

      test('should handle update with valid ID', () {
        const testId = 42;
        storage.update(testId);
        expect(storage, isNotNull);
      });

      test('should handle multiple updates', () {
        storage
          ..update(1)
          ..update(2)
          ..update(3);
        expect(storage, isNotNull);
      });

      test('should handle save operation', () {
        storage.save();
        expect(storage, isNotNull);
      });

      test('should handle close operation', () {
        storage.close();
        expect(storage, isNotNull);
      });

      test('should handle destroy operation', () {
        storage.destroy();
        expect(storage, isNotNull);
      });

      test('should handle sequence of operations', () {
        storage
          ..update(10)
          ..save()
          ..update(20)
          ..close()
          ..destroy();
        expect(storage, isNotNull);
      });

      test('should handle update with zero ID', () {
        storage.update(0);
        expect(storage, isNotNull);
      });

      test('should handle update with large ID', () {
        const largeId = 9007199254740991; // MAX_SAFE_INTEGER
        storage.update(largeId);
        expect(storage, isNotNull);
      });

      test('should implement IIdHandlerStorageRepository', () {
        expect(storage, isA<IIdHandlerStorageRepository>());
      });
    });
  });
}
