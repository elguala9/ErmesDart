import 'dart:typed_data';

import 'package:ermes_core/src/utility/hash_utils.dart';
import 'package:test/test.dart';

void main() {
  group('hash_utils', () {
    group('calculateHashSync', () {
      test('produces consistent hash for same data', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final hash1 = calculateHashSync(data);
        final hash2 = calculateHashSync(data);

        expect(hash1, equals(hash2));
      });

      test('produces SHA-256 hex string (64 chars)', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final hash = calculateHashSync(data);

        expect(hash.length, equals(64));
        expect(hash, matches(RegExp(r'^[a-f0-9]{64}$')));
      });

      test('produces different hash for different data', () {
        final data1 = Uint8List.fromList([1, 2, 3, 4]);
        final data2 = Uint8List.fromList([1, 2, 3, 5]);

        final hash1 = calculateHashSync(data1);
        final hash2 = calculateHashSync(data2);

        expect(hash1, isNot(equals(hash2)));
      });

      test('handles empty data', () {
        final data = Uint8List(0);
        final hash = calculateHashSync(data);

        expect(hash.length, equals(64));
      });

      test('handles large data', () {
        final data = Uint8List(10000);
        for (var i = 0; i < data.length; i++) {
          data[i] = (i % 256).toUnsigned(8);
        }

        final hash = calculateHashSync(data);
        expect(hash.length, equals(64));
      });
    });

    group('verifyHash', () {
      test('returns true for matching hash', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final hash = calculateHashSync(data);

        expect(verifyHash(data, hash), isTrue);
      });

      test('returns false for non-matching hash', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final wrongHash = calculateHashSync(Uint8List.fromList([5, 6, 7, 8]));

        expect(verifyHash(data, wrongHash), isFalse);
      });

      test('returns false for corrupted data', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final hash = calculateHashSync(data);

        final corruptedData = Uint8List.fromList([1, 2, 3, 5]);
        expect(verifyHash(corruptedData, hash), isFalse);
      });

      test('is case sensitive for hex string', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final hash = calculateHashSync(data);
        final upperHash = hash.toUpperCase();

        // SHA-256 hex is lowercase, so uppercase should fail
        expect(verifyHash(data, upperHash), isFalse);
      });
    });
  });
}
