import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesIdValidator();
}

void testErmesIdValidator() {
  group('ErmesIdValidator', () {
    final valid = 'a' * 64;
    const validMixedCase =
        '0123456789ABCDEFabcdef0123456789ABCDEFabcdef0123456789ABCDEF0123';

    group('isValidPublicKey()', () {
      test('accepts a 64-char lowercase hex string', () {
        expect(ErmesIdValidator.isValidPublicKey(valid), isTrue);
      });

      test('accepts mixed-case hex', () {
        expect(ErmesIdValidator.isValidPublicKey(validMixedCase), isTrue);
      });

      test('rejects empty string', () {
        expect(ErmesIdValidator.isValidPublicKey(''), isFalse);
      });

      test('rejects 63-char string (too short)', () {
        expect(ErmesIdValidator.isValidPublicKey('a' * 63), isFalse);
      });

      test('rejects 65-char string (too long)', () {
        expect(ErmesIdValidator.isValidPublicKey('a' * 65), isFalse);
      });

      test('rejects non-hex characters', () {
        expect(ErmesIdValidator.isValidPublicKey('g' * 64), isFalse);
      });

      test('publicKeyHexLength is 64', () {
        expect(ErmesIdValidator.publicKeyHexLength, 64);
      });
    });

    group('validatePublicKey()', () {
      test('does not throw for a valid key', () {
        expect(
          () => ErmesIdValidator.validatePublicKey(valid),
          returnsNormally,
        );
      });

      test('throws ErmesValidationException for an invalid key', () {
        expect(
          () => ErmesIdValidator.validatePublicKey('not-valid'),
          throwsA(isA<ErmesValidationException>()),
        );
      });

      test('error message includes the offending value and field name', () {
        try {
          ErmesIdValidator.validatePublicKey('bad', field: 'recipient');
          fail('Expected ErmesValidationException');
        } on ErmesValidationException catch (e) {
          expect(e.toString(), contains('recipient'));
          expect(e.toString(), contains('bad'));
        }
      });

      test('truncates very long invalid input in the error message', () {
        final long = 'z' * 500;
        try {
          ErmesIdValidator.validatePublicKey(long);
          fail('Expected ErmesValidationException');
        } on ErmesValidationException catch (e) {
          expect(e.toString(), contains('...'));
          expect(e.toString().length, lessThan(long.length));
        }
      });
    });
  });
}
