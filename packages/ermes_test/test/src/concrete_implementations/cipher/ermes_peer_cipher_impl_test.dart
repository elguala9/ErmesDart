import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:cryptdart/interfaces/i_cipher.dart';
import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesPeerCipherImplementation();
}

void testErmesPeerCipherImplementation() {
  group('ErmesPeerCipher', () {
    late ErmesPeerCipher cipher;
    late ICipher mockCipher1;
    late ICipher mockCipher2;

    setUp(() {
      cipher = ErmesPeerCipher();
      mockCipher1 = _MockCipher(
        keyId: sha256.convert([1]),
        expirationDate: DateTime.now().add(const Duration(hours: 1)),
      );
      mockCipher2 = _MockCipher(
        keyId: sha256.convert([2]),
        expirationDate: DateTime.now().add(const Duration(hours: 2)),
      );
    });

    test('encrypt throws CipherException when no encryption cipher available',
        () {
      expect(
        () => cipher.encrypt(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<CipherException>()),
      );
    });

    test('addEncryptCipher adds cipher to encryption list', () {
      cipher.addEncryptCipher(mockCipher1);
      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = cipher.encrypt(data);
      expect(encrypted.encryptedData, isNotEmpty);
      expect(encrypted.keyId, equals(mockCipher1.keyId));
    });

    test('addDecryptCipher allows decryption with correct keyId', () {
      final mockCipher = _MockCipher(
        keyId: sha256.convert([3]),
        expirationDate: DateTime.now().add(const Duration(hours: 1)),
      );
      cipher.addDecryptCipher(mockCipher);

      final encrypted = DataEncrypted(mockCipher.keyId, Uint8List.fromList([4, 5, 6]));

      expect(
        () => cipher.decrypt(encrypted),
        returnsNormally,
      );
    });

    test('decrypt throws CipherException when cipher not found', () {
      final unknownKeyId = sha256.convert([999]);
      final encrypted = DataEncrypted(unknownKeyId, Uint8List.fromList([1, 2, 3]));

      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('encrypt uses first cipher [0] when multiple ciphers available', () {
      cipher
        ..addEncryptCipher(mockCipher1)
        ..addEncryptCipher(mockCipher2);

      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = cipher.encrypt(data);

      // Should use the one with latest expiration (mockCipher2)
      expect(encrypted.keyId, equals(mockCipher2.keyId));
    });

    test('clearOldEncryptCipher removes expired encryption ciphers', () {
      final expiredCipher = _MockCipher(
        keyId: sha256.convert([4]),
        expirationDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      cipher
        ..addEncryptCipher(expiredCipher)
        ..addEncryptCipher(mockCipher1)
        ..clearOldEncryptCipher();

      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = cipher.encrypt(data);

      // Should use mockCipher1 since expiredCipher is removed
      expect(encrypted.keyId, equals(mockCipher1.keyId));
    });

    test('clearOldDecryptCipher removes expired decryption ciphers', () {
      final expiredCipher = _MockCipher(
        keyId: sha256.convert([5]),
        expirationDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      cipher
        ..addDecryptCipher(expiredCipher)
        ..clearOldDecryptCipher();

      final encrypted = DataEncrypted(expiredCipher.keyId, Uint8List.fromList([1, 2, 3]));

      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('removeEncryptCipher removes specific encryption cipher', () {
      cipher
        ..addEncryptCipher(mockCipher1)
        ..addEncryptCipher(mockCipher2)
        ..removeEncryptCipher(mockCipher2.keyId);

      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = cipher.encrypt(data);

      expect(encrypted.keyId, equals(mockCipher1.keyId));
    });

    test('removeDecryptCipher removes specific decryption cipher', () {
      cipher
        ..addDecryptCipher(mockCipher1)
        ..removeDecryptCipher(mockCipher1.keyId);

      final encrypted = DataEncrypted(mockCipher1.keyId, Uint8List.fromList([1, 2, 3]));

      expect(
        () => cipher.decrypt(encrypted),
        throwsA(isA<CipherException>()),
      );
    });

    test('roundtrip encrypt and decrypt', () {
      final testCipher = _MockCipher(
        keyId: sha256.convert([10]),
        expirationDate: DateTime.now().add(const Duration(hours: 1)),
      );

      cipher
        ..addEncryptCipher(testCipher)
        ..addDecryptCipher(testCipher);

      final originalData = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
      final encrypted = cipher.encrypt(originalData);
      final decrypted = cipher.decrypt(encrypted);

      expect(decrypted, equals(originalData));
    });
  });
}

/// Mock implementation of ICipher for testing
class _MockCipher implements ICipher {
  _MockCipher({
    required this.keyId,
    required this.expirationDate,
  });

  @override
  final Digest keyId;

  @override
  final DateTime? expirationDate;

  @override
  int? get expirationTimes => null;

  @override
  int? get expirationTimesRemaining => null;

  @override
  bool isExpired() => expirationDate != null &&
      expirationDate!.isBefore(DateTime.now());

  @override
  void incrementUse() {
    // Mock: do nothing
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #algorithm) {
      return null;
    }
    return super.noSuchMethod(invocation);
  }

  @override
  List<int> encrypt(List<int> data) => [...data, 0xFF]; // Mock: append 0xFF

  @override
  List<int> decrypt(List<int> data) =>
      data.isEmpty ? [] : data.sublist(0, data.length - 1); // Mock: remove last
}
