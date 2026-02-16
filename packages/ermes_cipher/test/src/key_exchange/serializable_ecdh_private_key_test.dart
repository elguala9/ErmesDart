// Test for SerializableECDHPrivateKey
// Run with: dart test test/src/key_exchange/

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:test/test.dart';

void main() {
  group('SerializableECDHPrivateKey', () {
    late List<int> privateKeyBytes;
    late List<int> publicKeyBytes;
    late SerializableECDHPrivateKey key;

    setUp(() {
      // Create sample P-256 key material
      privateKeyBytes = List<int>.generate(32, (i) => (i * 7) % 256);
      publicKeyBytes = List<int>.generate(65, (i) => (i * 11) % 256);
      key = SerializableECDHPrivateKey.fromBytes(
        privateKeyBytes: privateKeyBytes,
        publicKeyBytes: publicKeyBytes,
      );
    });

    test('creates instance from bytes', () {
      expect(key.privateKeyBytes, equals(privateKeyBytes));
      expect(key.publicKeyBytes, equals(publicKeyBytes));
      expect(key.curve, equals('P-256'));
    });

    test('returns copies of key bytes', () {
      final private1 = key.privateKeyBytes;
      final private2 = key.privateKeyBytes;

      // Different objects
      expect(identical(private1, private2), isFalse);
      // Same content
      expect(private1, equals(private2));
    });

    test('serializes to string format', () {
      final serialized = key.serialize();

      expect(serialized, isA<String>());
      expect(serialized.contains(':'), isTrue);

      final parts = serialized.split(':');
      expect(parts.length, equals(2));
    });

    test('deserializes from string format', () {
      final serialized = key.serialize();
      final deserialized =
          SerializableECDHPrivateKey.deserialize(serialized);

      expect(deserialized.privateKeyBytes, equals(privateKeyBytes));
      expect(deserialized.publicKeyBytes, equals(publicKeyBytes));
    });

    test('round-trip serialization preserves data', () {
      final serialized = key.serialize();
      final restored = SerializableECDHPrivateKey.deserialize(serialized);

      expect(restored == key, isTrue);
    });

    test('rejects invalid serialization format', () {
      expect(
        () => SerializableECDHPrivateKey.deserialize('invalid'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SerializableECDHPrivateKey.deserialize('a:b:c'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects empty key bytes', () {
      expect(
        () => SerializableECDHPrivateKey.fromBytes(
          privateKeyBytes: [],
          publicKeyBytes: publicKeyBytes,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => SerializableECDHPrivateKey.fromBytes(
          privateKeyBytes: privateKeyBytes,
          publicKeyBytes: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('equality operator works correctly', () {
      final key2 = SerializableECDHPrivateKey.fromBytes(
        privateKeyBytes: privateKeyBytes,
        publicKeyBytes: publicKeyBytes,
      );

      expect(key == key2, isTrue);
      expect(key.hashCode == key2.hashCode, isTrue);
    });

    test('different keys are not equal', () {
      final differentPrivate =
          List<int>.generate(32, (i) => (i * 13) % 256);
      final differentKey = SerializableECDHPrivateKey.fromBytes(
        privateKeyBytes: differentPrivate,
        publicKeyBytes: publicKeyBytes,
      );

      expect(key == differentKey, isFalse);
      expect(key.hashCode == differentKey.hashCode, isFalse);
    });

    test('toString provides readable representation', () {
      final str = key.toString();

      expect(str, contains('SerializableECDHPrivateKey'));
      expect(str, contains('P-256'));
      expect(str, contains('32B')); // private key size
      expect(str, contains('65B')); // public key size
    });

    test('utility functions work correctly', () {
      // Create
      final created = ECDHKeyUtilities.createFromBytes(
        privateKeyBytes: privateKeyBytes,
        publicKeyBytes: publicKeyBytes,
      );
      expect(created, equals(key));

      // Save
      final saved = ECDHKeyUtilities.saveToString(key);
      expect(saved, isA<String>());

      // Load
      final loaded = ECDHKeyUtilities.loadFromString(saved);
      expect(loaded, equals(key));
    });
  });

  group('ECDHKeyUtilities.generateNewKey', () {
    test('generates valid key pair', () async {
      final newKey = await ECDHKeyUtilities.generateNewKey();

      expect(newKey, isA<SerializableECDHPrivateKey>());
      expect(newKey.curve, equals('P-256'));
      expect(newKey.privateKeyBytes.length, equals(32));
      expect(newKey.publicKeyBytes.length, equals(65));
    });

    test('generates unique keys', () async {
      final key1 = await ECDHKeyUtilities.generateNewKey();
      final key2 = await ECDHKeyUtilities.generateNewKey();

      expect(key1, isNot(equals(key2)));
      expect(key1.privateKeyBytes, isNot(equals(key2.privateKeyBytes)));
      expect(key1.publicKeyBytes, isNot(equals(key2.publicKeyBytes)));
    });

    test('generated key is serializable', () async {
      final newKey = await ECDHKeyUtilities.generateNewKey();
      final serialized = ECDHKeyUtilities.saveToString(newKey);
      final restored = ECDHKeyUtilities.loadFromString(serialized);

      expect(restored, equals(newKey));
    });

    test('generated key has valid structure', () async {
      final newKey = await ECDHKeyUtilities.generateNewKey();

      // Private key should be 32 bytes for P-256
      expect(newKey.privateKeyBytes.length, equals(32));

      // Public key should be 65 bytes (uncompressed P-256)
      expect(newKey.publicKeyBytes.length, equals(65));
      // First byte of uncompressed point should be 0x04
      expect(newKey.publicKeyBytes.first, equals(0x04));
    });
  });
}
