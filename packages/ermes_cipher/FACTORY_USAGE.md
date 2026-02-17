# Cipher and Signer Factories

This document explains how to use the new `createCipher` and `createSigner` factories in the `ermes_cipher` library.

## Overview

The factories create cryptographic primitives (ciphers and signers) based on a `KeyInfo` object that contains:
- `key`: The cryptographic key material (as a String)
- `start`: When the key becomes valid
- `expiration`: When the key expires
- `alg`: The algorithm to use (`CryptoAlgorithm` enum)

## Factory Functions

### `createCipher(KeyInfo keyInfo) → ISymmetricCipher`

Creates a symmetric cipher for encryption/decryption operations.

**Supported algorithms:**
- `AES` - Advanced Encryption Standard
- `ChaCha20` - Stream cipher
- `DES` - Data Encryption Standard

**Example:**
```dart
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

// Create KeyInfo with AES algorithm
final keyInfo = KeyInfo(
  '0123456789abcdef0123456789abcdef',  // 32-char key
  DateTime.now(),
  DateTime.now().add(Duration(hours: 1)),
  CryptoAlgorithm.aes,  // or other algorithm
);

// Create cipher
final cipher = createCipher(keyInfo);

// Use cipher
final encrypted = cipher.encrypt([1, 2, 3, 4, 5]);
```

### `createSigner(KeyInfo keyInfo) → ISigner`

Creates a signer for digital signatures and verification.

**Supported algorithms:**
- `Ed25519` / `EdDSA` - Modern signature algorithm (recommended)
- `ECDSA` - Elliptic Curve DSA
  - P-256 (default ECDSA)
  - P-384
  - P-521
- `RSA` - Rivest-Shamir-Adleman
  - PSS (Probabilistic Signature Scheme - recommended)
  - PKCS1v15

**Example:**
```dart
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

// Create KeyInfo with Ed25519 algorithm
final keyInfo = KeyInfo(
  'ed25519_private_key_material',  // Your key material
  DateTime.now(),
  DateTime.now().add(Duration(days: 365)),
  CryptoAlgorithm.ed25519,
);

// Create signer
final signer = createSigner(keyInfo);

// Use signer (note: currently throws UnimplementedError)
// final signature = signer.sign([1, 2, 3, 4, 5]);
// final isValid = signer.verify([1, 2, 3, 4, 5], signature);
```

## Algorithm Detection

Both factories detect the algorithm type by converting the `CryptoAlgorithm` enum to a lowercase string and checking if it contains algorithm keywords:

- `'aes'` → AES cipher
- `'chacha'` → ChaCha20 cipher
- `'des'` → DES cipher
- `'ed25519'` or `'eddsa'` → Ed25519 signer
- `'ecdsa'` + `'p256'` or `'p-256'` → ECDSA P-256
- `'ecdsa'` + `'p384'` or `'p-384'` → ECDSA P-384
- `'ecdsa'` + `'p521'` or `'p-521'` → ECDSA P-521
- `'rsa'` + `'pss'` → RSA-PSS
- `'rsa'` → RSA-SSAPKCS1v15 (default RSA)

## Implementation Notes

### Cipher Factory
- Automatically sets the cipher expiration date from `KeyInfo.expiration`
- Uses hex string parsing by default for key material
- ChaCha20 nonce is set to empty bytes (TODO: implement proper nonce generation)

### Signer Factory
- Returns signer implementations that extend `CryptDartSigner`
- Base classes: `ISigner` (interface), `CryptDartSigner` (abstract base)
- Current implementations are **placeholder stubs** with `UnimplementedError`
- Implement the `sign()`, `verify()`, and `getPublicKey()` methods based on your needs

### Extending the Factories

To add support for new algorithms:

1. **For Ciphers:** Add a new condition in `createCipher()` that detects the algorithm and creates the appropriate cipher
2. **For Signers:** Create a new signer class extending `CryptDartSigner` and add detection logic in `createSigner()`

Example:
```dart
// New signer class
final class MyCustomSigner extends CryptDartSigner {
  MyCustomSigner(super.keyString);

  @override
  List<int> sign(List<int> message) {
    // Your implementation
  }

  @override
  bool verify(List<int> message, List<int> signature) {
    // Your implementation
  }

  @override
  List<int> getPublicKey() {
    // Your implementation
  }
}

// Update factory
if (algString.contains('mycustom')) {
  return MyCustomSigner(keyInfo.key);
}
```

## Interfaces

### `ISigner` Interface

```dart
abstract interface class ISigner {
  List<int> sign(List<int> message);
  bool verify(List<int> message, List<int> signature);
  List<int> getPublicKey();
}
```

## Error Handling

Both factories throw generic `Exception` with descriptive messages if:
- Algorithm is not supported
- Key format is invalid
- Algorithm cannot be parsed from `CryptoAlgorithm`

Example:
```dart
try {
  final cipher = createCipher(unknownKeyInfo);
} catch (e) {
  print('Error: $e');  // "Cipher algorithm not supported: ..."
}
```

## Future Work

- [ ] Implement actual signing/verification methods in signer classes
- [ ] Add proper nonce generation for ChaCha20
- [ ] Support key material parsing from multiple formats (hex, base64, raw bytes)
- [ ] Add key validation and format checking
- [ ] Implement proper key derivation if needed
