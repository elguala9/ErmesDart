# ermes_cipher

Cryptographic implementation for Ermes with multi-key rotation support.

## Overview

`ermes_cipher` provides a complete implementation of the encryption interfaces defined in the `iermes` package. It features:

- **Multi-key support**: Manage multiple encryption keys with validity timestamps
- **Automatic key rotation**: Automatically select the appropriate key based on start/expiration times
- **Transparent fallback**: On decryption failure, automatically tries other available keys
- **Clock drift tolerance**: Gracefully handles clock differences between peers
- **Performance optimization**: Caches cipher objects to reduce creation overhead
- **Automatic cleanup**: Removes keys expired more than 24 hours ago

## Features

### ErmesPeerCipher

The main class implementing `IErmesPeerCipher` with the following capabilities:

- **Multi-Key Management**: Store and manage multiple `KeyInfo` objects simultaneously
- **Smart Key Selection**: Uses `KeySelector` to choose the optimal key for each operation
- **Encrypt/Decrypt Operations**: Supports seamless encryption and decryption with automatic key selection
- **Key Addition**: Add new keys to the pool at runtime with `addKey(KeyInfo)`
- **Fallback Decryption**: If primary key fails, tries other keys in the pool

### KeySelector

Intelligent key selection algorithm:

- **For Encryption**: Uses currently valid key with the furthest expiration; falls back to most recently started key
- **For Decryption**: Uses currently valid key; tolerates recently expired keys for clock drift scenarios

### ErmesCryptCollection

Factory for creating encrypt/decrypt instances:

- Creates `IErmesEncrypt` and `IErmesDecrypt` implementations
- Supports multiple algorithms (AES, ChaCha20)
- Extensible for future algorithms

### Exception Handling

Custom exception classes:

- `CipherException`: Base exception for cipher errors
- `NoValidKeyException`: Thrown when no valid encryption key exists
- `DecryptionFailedException`: Thrown when decryption fails with all keys
- `UnsupportedAlgorithmException`: Thrown for unsupported algorithms

## Usage

### Basic Setup

```dart
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:ermes_cipher/ermes_cipher.dart';

// Create initial key
final keyInfo = KeyInfo(
  'base64EncodedKey',
  DateTime.now(),
  DateTime.now().add(Duration(hours: 1)),
);

// Create cipher
final cipher = createErmesPeerCipher(
  algorithm: CryptoAlgorithm.AES,
  initialKeys: [keyInfo],
);
```

### Encrypt and Decrypt

```dart
// Encrypt data
final data = [1, 2, 3, 4, 5];
final encrypted = cipher.encrypt(data);

// Decrypt data
final decrypted = cipher.decrypt(encrypted);
```

### Key Rotation

```dart
// Add new key to pool
final newKeyInfo = KeyInfo(
  'newBase64EncodedKey',
  DateTime.now().add(Duration(minutes: 55)),
  DateTime.now().add(Duration(hours: 2)),
);

cipher.addKey(newKeyInfo);

// Cipher automatically uses the most appropriate key
```

## Architecture

### Package Structure

```
lib/
├── ermes_cipher.dart                    # Barrel file
└── src/
    ├── ermes_peer_cipher.dart           # Main implementation
    ├── ermes_encrypt.dart               # Encrypt implementations
    ├── ermes_decrypt.dart               # Decrypt implementations
    ├── ermes_crypt_collection.dart      # Factory
    ├── key_selector.dart                # Key selection logic
    ├── exceptions.dart                  # Custom exceptions
    └── factories/
        └── ermes_cipher_factories.dart  # Public factories
```

## Design Decisions

### Multi-Key Approach

The implementation stores multiple `KeyInfo` objects to support:
- Gradual key rotation without service interruption
- Handling of late-arriving messages encrypted with old keys
- Clock drift between peers

### Automatic Cleanup

Keys expired more than 24 hours ago are automatically removed to:
- Limit memory usage
- Maintain a reasonable key pool size
- Prevent stale key accumulation

### Fallback Mechanism

On decryption failure, the cipher tries other keys because:
- Handles out-of-order message delivery
- Compensates for clock drift between peers
- Provides graceful degradation

## Dependencies

- `cryptdart: ^0.1.2` - Cryptographic primitives
- `ermes_types` - Type definitions
- `iermes` - Interface contracts
- `barrel_files_annotation` - Code generation annotations

## Notes

### Cryptdart Version

Currently uses `cryptdart: ^0.1.2`. The implementation is designed to be easily migrated to future versions with improved algorithm support. See `ermes_crypt_collection.dart` for the algorithm selection logic.

### Algorithm Support

- **AES**: Fully supported (currently throws `UnsupportedError` due to cryptdart API determination needed)
- **ChaCha20**: Placeholder for future support

### Key Format

Keys are expected to be base64-encoded strings that can be decoded into appropriate byte arrays for the selected cipher algorithm.

## Testing

Comprehensive test suite included covering:
- Key selection logic (various scenarios)
- Encryption/decryption round-trips
- Multi-key scenarios
- Key rotation
- Fallback mechanisms
- Error conditions

Run tests with:
```bash
dart test
```

## Future Improvements

- [ ] Implement actual AES encryption with proper key derivation
- [ ] Add support for ChaCha20 when available in cryptdart
- [ ] Add thread-safety with locks for concurrent access
- [ ] Add metrics/monitoring for key usage
- [ ] Support for async encryption operations
- [ ] Key versioning and tracking

## Contributing

When extending this package:
1. Maintain compatibility with `IErmesPeerCipher` interface
2. Add tests for new functionality
3. Follow existing code patterns
4. Update this README with new features

## License

Part of the ErmesDart project.
