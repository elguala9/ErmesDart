# ECDH Key Exchange Module

This module provides serializable ECDH (Elliptic Curve Diffie-Hellman) key management for the Ermes cipher package.

## Overview

The module provides a simple way to:
- Store ECDH key material (private and public keys) in a compact, serializable format
- Serialize keys to strings for storage or transmission
- Deserialize keys back to usable objects
- Work with P-256 elliptic curve keys

## Key Components

### 1. SerializableECDHPrivateKey

Main class for managing ECDH private key pairs with serialization support.

**Features:**
- Immutable key storage
- Binary-safe key material handling
- Serialization to Base64-encoded strings
- Deserialization with format validation
- Equality comparison and hashing
- Full copy safety (getters return copies, not references)

**Typical Sizes:**
- Private key: 32 bytes (P-256)
- Public key: 65 bytes (P-256, uncompressed format)
- Serialized length: ~172 characters (Base64 encoded + separator)

### 2. ECDHKeyUtilities

Static utility class providing convenient factory methods.

**Methods:**
- `createFromBytes()` - Create from raw key material
- `saveToString()` - Serialize to string
- `loadFromString()` - Deserialize from string
- `generateNewKey()` - Generate random key pair (future: requires cryptdart integration)

## Usage

### Creating a Key from Existing Material

```dart
import 'package:ermes_cipher/ermes_cipher.dart';

// You have key bytes from some source
List<int> privateKey = [...]; // 32 bytes
List<int> publicKey = [...];  // 65 bytes

final key = ECDHKeyUtilities.createFromBytes(
  privateKeyBytes: privateKey,
  publicKeyBytes: publicKey,
);
```

### Storing a Key

```dart
// Serialize to string
String serialized = ECDHKeyUtilities.saveToString(key);

// Store in file, database, config, etc.
// Format: "base64(privateKey):base64(publicKey)"
```

### Loading a Stored Key

```dart
// Load from storage
String stored = loadFromStorage();

final key = ECDHKeyUtilities.loadFromString(stored);

// Use key material
print(key.privateKeyBytes); // Raw bytes
print(key.publicKeyBytes);  // Raw bytes
```

## Serialization Format

```
[base64(private_key)]:[base64(public_key)]
```

**Example:**
```
bm93L2xldC9zYWZlcnx0aGlzaXNhYmFzZTY0ZW5jb2Rpbmc=:dGhpc2lzYWxzb2Jhc2U2NGVuY29kZWRkYXRh
```

**Rationale:**
- Base64 ensures printable ASCII strings (safe for any storage)
- Colon separator is unambiguous
- Self-describing format (no length prefix needed)
- Reversible (can recover original bytes)

## Error Handling

```dart
try {
  final key = ECDHKeyUtilities.loadFromString(data);
} on FormatException catch (e) {
  print('Invalid format: ${e.message}');
} on ArgumentError catch (e) {
  print('Invalid data: ${e.message}');
}
```

## Integration with cryptdart

To use with cryptdart's ECDH:

```dart
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';

// Load stored key
final stored = ECDHKeyUtilities.loadFromString(serializedData);

// Create ECDHKeyExchange instance
final ecdh = ECDHKeyExchange((
  parent: (
    algorithm: KeyExchangeAlgorithm.ecdh,
    expirationDate: DateTime.now().add(Duration(hours: 1)),
    expirationTimes: null,
  ),
  publicKey: _toHexString(stored.publicKeyBytes),
  privateKey: _toHexString(stored.privateKeyBytes),
  curve: stored.curve,
));

// Perform key exchange
final sharedSecret = await ecdh.generateSharedSecret(otherPublicKey);
```

## Testing

Example tests are provided in `serializable_ecdh_private_key_test.dart`.

To run tests in your project:

```bash
cd packages/ermes_cipher
dart test test/src/key_exchange/
```

## Security Considerations

- Keys are stored as raw bytes - ensure proper protection at storage layer
- Serialized strings contain sensitive material - treat as secrets
- Copies are made on access to prevent external modification
- No automatic zeroing of memory (Dart limitation)
- Use secure storage (encrypted filesystem, secure enclave) for production

## Performance

- Serialization: O(n) where n is key size (~100 bytes)
- Deserialization: O(n) Base64 decode + parsing
- Equality check: O(n) byte comparison
- Hashing: O(n) hash computation

## Future Enhancements

- [x] Direct key generation using cryptdart's ECDH ✅ **DONE**
- [ ] Support for P-384 and P-521 curves
- [ ] Compressed public key format option
- [ ] Key derivation functions (KDF) integration
- [ ] Secure key storage backend abstraction
