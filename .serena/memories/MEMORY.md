# ErmesDart Project Memory - Implementation Progress

## ✅ Enum-based Algorithm Types (2026-02-22)
**Issue**: Code was using string values to identify encryption algorithms instead of proper enums
**Solution**: Use `CryptoAlgorithm` enum (from `cryptdart`) instead of string literals
**Key Changes**:
- Changed `ServiceMessageNewKey.algorithm` type from `String` → `CryptoAlgorithm`
- Removed `generateSymmetricFromString()` and `_parseAlgorithmString()` factory methods (obsolete)
- Updated `ErmesService.sendNewKey()` to accept `CryptoAlgorithm` parameter
- Updated all test files to use `SymmetricAlgorithm.aes` enum instead of string literals
  - `ermes_newkey_callback_test.dart`: Changed all 'AES-256', 'ECDH', 'RSA' strings to `SymmetricAlgorithm.aes`
  - `ermes_service_impl_test.dart`: Changed 'AES-256' to `SymmetricAlgorithm.aes`
  - `service_message_newkey_test.dart`: Changed all algorithm string values to enums
- Fixed `ServiceMessageNewKey.copyWith()` signature: `String? algorithm` → `CryptoAlgorithm?`
- Fixed JSON deserialization in `fromJson()` to cast as `CryptoAlgorithm`
- **Status**: ✅ Complete - dart analyze shows 0 errors

---

## ✅ Recently Completed: ErmesPeer Facade (2026-02-22)
**Purpose**: High-level facade that simplifies peer-to-peer messaging API
- Connection management (lifecycle: initialize, dispose)
- Message sending with offline queueing
- Connection state notifications
- ECDH key exchange integration (placeholder)

**Status**: ✅ Complete - 0 errors, committed to develop

---

## ✅ Key Rotation Implementation (2026-02-22)
**Purpose**: Automatic encryption key rotation based on time and message count
- Time-based: 3600 seconds (1 hour) default
- Message count: 1000 messages default
- Generates new cipher via `generateSymmetric(key, SymmetricAlgorithm.aes)` 
- Sends `ServiceMessageNewKey` to peer
**Status**: ✅ Complete

---

## Architecture Pattern: IdAccountType over ErmesPeerInfo
- **Goal**: Reduce coupling in repository/service layer
- **Status**: ✅ Complete

---

Current Date: 2026-02-22
