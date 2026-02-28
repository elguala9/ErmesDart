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

## ✅ Key Rotation Implementation - Simplified (2026-02-22)
**Purpose**: Automatic encryption key rotation based on time and message count
- Time-based: 3600 seconds (1 hour) default
- Message count: 1000 messages default
- **New Implementation**: Clean 3-step flow (generate → create → send)
  1. Generate 256-bit random key with `Random.secure()` from `dart:math`
  2. Create cipher with `generateSymmetric(key, SymmetricAlgorithm.aes)`
  3. Add to handler and send with `sendNewKey()`
- Removed: `_generateRandomHexKey()`, `_sendKeyRotationNotification()`
- **Status**: ✅ Complete - simplified and clean

---

## Architecture Pattern: IdAccountType over ErmesPeerInfo
- **Goal**: Reduce coupling in repository/service layer
- **Status**: ✅ Complete

---

## ✅ IErmesStorageAndCachingMessages Implementation (2026-02-22)
**Purpose**: Extend storage/caching interface with `deleteUntil()` method
**Implementation**:
- `ErmesStorageAndCaching` now extends `IErmesStorageAndCachingMessages<DataJson>`
- **deleteUntil(int id)**: Deletes all IDs from 0 to the passed id (inclusive)
  - Uses fire-and-forget pattern with `unawaited()` from `dart:async`
  - Deletes from both cache and storage in parallel (without waiting)
  - Follows same pattern as existing `delete()` method
- **Changes Made**:
  1. Added `import 'dart:async'` for `unawaited` function
  2. Changed class inheritance to extend `IErmesStorageAndCachingMessages`
  3. Implemented `deleteUntil()` method with loop from 0 to id (inclusive)
  4. Regenerated iermes barrel file (index_generator) to export the new interface
- **Status**: ✅ Complete - 0 errors, no warnings

---

## ✅ ErmesStorageAndCachingMessagesHandler Singleton (2026-02-23)
**Purpose**: Centralized management of `ErmesStorageAndCachingMessages` instances
**Implementation**:
- **Location**: `packages/ermes_storage/lib/src/ermes_storage_and_caching_messages_handler.dart`
- **Pattern**: Thread-safe singleton with static instance
- **Key Features**:
  - Composite key: `"idAccountType|idConnectionType"`
  - Methods: `get()`, `set()`, `contains()`, `remove()`, `getAll()`, `clear()`, `count` property
  - Immutable map access via `getAll()`
- **Usage**:
  ```dart
  final handler = ErmesStorageAndCachingMessagesHandler.instance;
  handler.set('alice', 'conn-123', storageInstance);
  final storage = handler.get('alice', 'conn-123');
  if (handler.contains('alice', 'conn-123')) { ... }
  handler.remove('alice', 'conn-123');
  ```
- **Status**: ✅ Complete - 0 errors, no warnings, auto-exported via 

---

Current Date: 2026-02-23
