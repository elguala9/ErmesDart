import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:test/test.dart';

void main() {
  group('CipherException', () {
    test('should create with message', () {
      final ex = CipherException('test error');
      expect(ex.message, equals('test error'));
      expect(ex.cause, isNull);
    });

    test('should create with message and cause', () {
      final cause = Exception('root cause');
      final ex = CipherException('test error', cause);
      expect(ex.message, equals('test error'));
      expect(ex.cause, equals(cause));
    });

    test('toString should format correctly', () {
      final ex = CipherException('error');
      expect(ex.toString(), contains('CipherException'));
      expect(ex.toString(), contains('error'));
    });
  });

  group('NoValidKeyException', () {
    test('should inherit from CipherException', () {
      final ex = NoValidKeyException();
      expect(ex, isA<CipherException>());
    });
  });

  group('DecryptionFailedException', () {
    test('should inherit from CipherException', () {
      final ex = DecryptionFailedException();
      expect(ex, isA<CipherException>());
    });
  });

  group('UnsupportedAlgorithmException', () {
    test('should inherit from CipherException', () {
      final ex = UnsupportedAlgorithmException('AES');
      expect(ex, isA<CipherException>());
    });
  });
}
