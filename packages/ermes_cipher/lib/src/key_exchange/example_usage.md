# ECDH Key Utilities - Usage Example

## Overview

The `SerializableECDHPrivateKey` class provides a way to create, store, and restore ECDH (Elliptic Curve Diffie-Hellman) key pairs using the P-256 curve.

## Creating a Key from Existing Bytes

```dart
import 'package:ermes_cipher/ermes_cipher.dart';

// You have key bytes from some source (e.g., cryptographic library)
List<int> privateKeyBytes = [...]; // 32 bytes for P-256
List<int> publicKeyBytes = [...];  // 65 bytes for P-256 (uncompressed)

// Create a SerializableECDHPrivateKey instance
final key = ECDHKeyUtilities.createFromBytes(
  privateKeyBytes: privateKeyBytes,
  publicKeyBytes: publicKeyBytes,
);

// Access the key material
print(key.privateKeyBytes); // Returns the private key bytes
print(key.publicKeyBytes);  // Returns the public key bytes
print(key.curve);           // Prints "P-256"
```

## Serializing a Key for Storage

```dart
// Serialize the key to a string (positional format)
String serialized = ECDHKeyUtilities.saveToString(key);

// The format is: "base64(privateKey):base64(publicKey)"
// This can be stored in a file, database, or configuration
print(serialized); // Example: "ABC123DEF456:XYZ789..."
```

## Restoring a Key from Storage

```dart
// Load the key from the serialized string
String storedKey = "ABC123DEF456:XYZ789..."; // From storage
final restoredKey = ECDHKeyUtilities.loadFromString(storedKey);

// The restored key is identical to the original
print(restoredKey == key); // true (if same key material)
```

## Complete Example: Store and Restore

```dart
import 'package:ermes_cipher/ermes_cipher.dart';

void main() {
  // 1. Create a key from key material
  final privateKey = List<int>.filled(32, 1);  // Example: 32 bytes of 0x01
  final publicKey = List<int>.filled(65, 2);   // Example: 65 bytes of 0x02

  final key = ECDHKeyUtilities.createFromBytes(
    privateKeyBytes: privateKey,
    publicKeyBytes: publicKey,
  );

  // 2. Save to string
  final serialized = ECDHKeyUtilities.saveToString(key);
  print('Serialized: $serialized');

  // 3. Restore from string
  final restored = ECDHKeyUtilities.loadFromString(serialized);
  print('Restored equals original: ${restored == key}');

  // 4. Verify the data
  print('Private key restored: ${restored.privateKeyBytes.length} bytes');
  print('Public key restored: ${restored.publicKeyBytes.length} bytes');
}
```

## Format Specification

The serialization format uses Base64 encoding to convert binary key data to text:

```
[base64(private_key)]:[base64(public_key)]
```

- **Separator**: Colon `:`
- **Private Key**: 32 bytes for P-256 (encoded in Base64)
- **Public Key**: 65 bytes for P-256, uncompressed format (encoded in Base64)

### Example:
```
bm93L2xldC9zYWZlcnx0aGlzaXNhYmFzZTY0ZW5jb2Rpbmc=:dGhpc2lzYWxzb2Jhc2U2NGVuY29kZWRkYXRh
```

## Key Characteristics

- **Immutable**: Once created, a key cannot be modified
- **Copy-safe**: Accessing key bytes returns copies, not references
- **Comparable**: Keys can be compared with `==` operator
- **Hashable**: Keys can be used in Sets and as Map keys

## Error Handling

```dart
try {
  final invalidSerialized = "not:valid:format";
  final key = ECDHKeyUtilities.loadFromString(invalidSerialized);
} on FormatException catch (e) {
  print('Failed to deserialize: ${e.message}');
}
```

## Generating New Keys

```dart
// Generate a new ECDH key pair (P-256 curve)
final newKey = await ECDHKeyUtilities.generateNewKey();
print('Generated new key: ${newKey.curve}');
print('Private key: ${newKey.privateKeyBytes.length} bytes');
print('Public key: ${newKey.publicKeyBytes.length} bytes');

// Immediately save it
String saved = ECDHKeyUtilities.saveToString(newKey);
print('Saved for later use: $saved');

// Restore it later
final restored = ECDHKeyUtilities.loadFromString(saved);
print('Keys match: ${restored == newKey}');
```

### Using Generated Keys

```dart
// Generate and use immediately without saving
final ephemeralKey = await ECDHKeyUtilities.generateNewKey();

// Use for ECDH key exchange, digital signatures, etc.
final publicKeyForPeer = ephemeralKey.publicKeyBytes;
```

## Integration with Cryptographic Operations

Once you have a `SerializableECDHPrivateKey`, you can use the key bytes with:
- Key agreement operations (e.g., with `ECDHKeyExchange` from cryptdart)
- Digital signatures (if applicable)
- Storage in secure locations (files, databases, secure enclaves)
- Transmission over secure channels with proper authentication
- Key derivation for symmetric cipher keys

### Example: Using with cryptdart's ECDHKeyExchange

```dart
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';

// Create ECDH instance with stored key material
final storedKey = ECDHKeyUtilities.loadFromString(savedKeyString);

// Convert key bytes back to the format cryptdart expects
// (This depends on cryptdart's actual byte format requirements)
final ecdh = ECDHKeyExchange((
  parent: (
    algorithm: KeyExchangeAlgorithm.ecdh,
    expirationDate: DateTime.now().add(Duration(hours: 1)),
    expirationTimes: null,
  ),
  publicKey: _bytesToHex(storedKey.publicKeyBytes),
  privateKey: _bytesToHex(storedKey.privateKeyBytes),
  curve: storedKey.curve,
));

// Perform key exchange
final otherPublicKeyHex = '...'; // From peer
final sharedSecret = await ecdh.generateSharedSecret(otherPublicKeyHex);
```
