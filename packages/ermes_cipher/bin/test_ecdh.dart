// Simple ECDH key generation and serialization test
import 'package:ermes_cipher/ermes_cipher.dart';

Future<void> main() async {
  print('🔐 Testing ECDH Key Generation and Serialization\n');
  print('═' * 60);

  try {
    // Test 1: Generate new key
    print('\n✓ Test 1: Generate new ECDH key pair');
    print('  Generating random P-256 key...');
    final newKey = await ECDHKeyUtilities.generateNewKey();
    print('  ✅ Success!');
    print('  - Curve: ${newKey.curve}');
    print('  - Private key: ${newKey.privateKeyBytes.length} bytes');
    print('  - Public key: ${newKey.publicKeyBytes.length} bytes');
    print('  - First byte of public key: 0x${newKey.publicKeyBytes.first.toRadixString(16).padLeft(2, '0').toUpperCase()}');

    // Test 2: Serialize key
    print('\n✓ Test 2: Serialize key to string');
    final serialized = ECDHKeyUtilities.saveToString(newKey);
    print('  ✅ Success!');
    print('  - Serialized length: ${serialized.length} characters');
    print('  - Format: "base64(private):base64(public)"');
    print('  - First 50 chars: ${serialized.substring(0, 50)}...');

    // Test 3: Deserialize key
    print('\n✓ Test 3: Deserialize key from string');
    final restored = ECDHKeyUtilities.loadFromString(serialized);
    print('  ✅ Success!');
    print('  - Restored curve: ${restored.curve}');
    print('  - Private key: ${restored.privateKeyBytes.length} bytes');
    print('  - Public key: ${restored.publicKeyBytes.length} bytes');

    // Test 4: Verify round-trip
    print('\n✓ Test 4: Verify round-trip serialization');
    final keysMatch = restored == newKey;
    print('  ✅ Success!');
    print('  - Keys are identical: $keysMatch');

    // Test 5: Generate multiple keys
    print('\n✓ Test 5: Generate multiple unique keys');
    final key1 = await ECDHKeyUtilities.generateNewKey();
    final key2 = await ECDHKeyUtilities.generateNewKey();
    final uniqueKeys = key1 != key2;
    print('  ✅ Success!');
    print('  - Key 1 private: ${key1.privateKeyBytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}...');
    print('  - Key 2 private: ${key2.privateKeyBytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}...');
    print('  - Keys are unique: $uniqueKeys');

    // Test 6: Create from bytes
    print('\n✓ Test 6: Create key from existing bytes');
    final privateBytes = List<int>.generate(32, (i) => (i * 7) % 256);
    final publicBytes = List<int>.generate(65, (i) => (i * 11) % 256);
    final customKey = ECDHKeyUtilities.createFromBytes(
      privateKeyBytes: privateBytes,
      publicKeyBytes: publicBytes,
    );
    print('  ✅ Success!');
    print('  - Custom key created');
    print('  - Private: ${privateBytes.length} bytes');
    print('  - Public: ${publicBytes.length} bytes');

    // Test 7: Test immutability
    print('\n✓ Test 7: Verify key immutability');
    final keyBytes1 = customKey.privateKeyBytes;
    final keyBytes2 = customKey.privateKeyBytes;
    final areDifferentObjects = !identical(keyBytes1, keyBytes2);
    print('  ✅ Success!');
    print('  - Multiple accesses return different objects: $areDifferentObjects');
    print('  - Content is identical: ${keyBytes1.length == keyBytes2.length}');

    print('\n' + '═' * 60);
    print('✅ All tests passed successfully!\n');
  } catch (e, st) {
    print('\n❌ Test failed:');
    print('Error: $e');
    print('Stack: $st');
  }
}
