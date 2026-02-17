# Test Failure Report - ErmesDart (ermes_test)

## Summary
- **Total Tests**: 164
- **Passed**: 114 ✅
- **Failed**: 50 ❌
- **Success Rate**: 69.5%

---

## Critical Issues (Root Causes)

### 🔴 Issue 1: Invalid Hexadecimal Parsing in ECDH Serialization
**Severity**: CRITICAL
**Affected Tests**: ~38 failures
**Location**: `packages/ermes_cipher/lib/src/key_exchange/ecdh_key_exchange_service.dart:248`

**Error**:
```
FormatException: Invalid radix-16 number (at character 2)
```

**Root Cause**: The `_hexToBytes()` method is failing to parse hexadecimal strings correctly.

**Affected Tests**:
- ECDHKeyExchangeService Serialization tests
- ECDHKeyExchangeService Factory Methods tests
- Multi-Peer Cipher Exchange Tests (serialization/deserialization cycles)
- Two-Peer Cipher Exchange Integration tests (all serialization-related)
- Algorithm Variants tests

**Stack Trace Pattern**:
```
at ECDHKeyExchangeService._hexToBytes (ecdh_key_exchange_service.dart:248)
at ECDHKeyExchangeService.serialize (ecdh_key_exchange_service.dart:103)
```

---

### 🔴 Issue 2: Test Files Missing `main()` Function
**Severity**: HIGH
**Affected Tests**: 4 failures
**Location**: Various test files in `test/src/concrete_implementations/`

**Error**:
```
Failed to load "test\src\concrete_implementations\cipher\<file>.dart":
Error: Undefined name 'main'.
```

**Missing `main()` in**:
1. `test/src/concrete_implementations/cipher/cipher_factories_test.dart`
2. `test/src/concrete_implementations/cipher/ecdh_key_exchange_test.dart`
3. `test/src/concrete_implementations/cipher/ermes_peer_cipher_impl_test.dart`
4. `test/src/concrete_implementations/cipher/two_peer_cipher_exchange_test.dart`

**Note**: These files appear to be helper/shared test files, not standalone test files. They should either:
- Have a `main()` function with tests
- Be excluded from direct execution and only imported by other test files
- Be moved to a `test/src/helpers/` directory

---

### 🟠 Issue 3: ChaCha20 IV Size Validation
**Severity**: MEDIUM
**Affected Tests**: 1 failure
**Location**: `packages/cryptdart/implementations/symmetric/chacha20_cipher.dart:72`

**Error**:
```
Invalid argument(s): ChaCha20 requires exactly 8 bytes of IV
```

**Affected Test**:
- `Cipher Factories createCipher ChaCha20 cipher can encrypt and decrypt`

**Root Cause**: The cipher factory is providing an incorrect IV size (not 8 bytes) when initializing ChaCha20.

---

## Detailed Failure Breakdown

### By Category

#### Serialization Issues (38 failures)
These all stem from the hexadecimal parsing problem in `ECDHKeyExchangeService._hexToBytes`:

- `serialize returns valid base64url string` - Test
- `generateFromSerialize deserializes correctly` - Test
- `Two-Peer Key Exchange and Communication (two peers exchange keys and communicate securely)` - Multiple variants
- `Serialization and Restoration (can serialize both peer key exchanges)` - Multiple variants
- `can restore from serialization and re-establish secure channel` - Multiple variants
- Multi-peer stress tests involving serialization/deserialization cycles
- Bidirectional communication tests (all involving serialization)

#### Test File Loading Errors (4 failures)
Files that cannot be discovered as test entry points:
- `cipher_factories_test.dart`
- `ecdh_key_exchange_test.dart`
- `ermes_peer_cipher_impl_test.dart`
- `two_peer_cipher_exchange_test.dart`

#### Cipher Implementation Issues (1 failure)
- ChaCha20 IV size mismatch

#### Other Failures (7 unaccounted)
Various tests with similar serialization-related errors

---

## Recommended Fixes

### Priority 1: Fix ECDH Hexadecimal Parsing (Fixes ~38 tests)

**File**: `packages/ermes_cipher/lib/src/key_exchange/ecdh_key_exchange_service.dart`

**Location**: Line 248 in `_hexToBytes()` method

**Action Required**:
- Review the hex string format being passed to `_hexToBytes()`
- Verify the string doesn't have unexpected prefixes (e.g., "0x")
- Check for encoding issues or extra whitespace
- Ensure the radix is correctly specified as 16

**Example Investigation**:
```dart
// Current code (problematic)
int.parse(hexString, radix: 16);

// Possible issues:
// 1. hexString contains "0x" prefix → strip it
// 2. hexString has extra whitespace → trim it
// 3. hexString encoding is wrong → decode properly
```

---

### Priority 2: Fix Test File Discovery (Fixes 4 tests)

**Action Required**:
Check if the test files in `test/src/concrete_implementations/cipher/` are:
1. Meant to be standalone tests → Add `main()` function
2. Meant to be helper files → Rename or reorganize to avoid test discovery

**Suggestion**: Review `concrete_implementations_test.dart` to see how it imports and uses these files.

---

### Priority 3: Fix ChaCha20 IV Size (Fixes 1 test)

**File**: Check the cipher factory that creates ChaCha20 instances

**Action Required**:
- Verify that ChaCha20 is initialized with exactly 8-byte IV
- Check `packages/ermes_cipher/lib/src/factories/ermes_cipher_factories.dart`
- Look at how `ChaCha20Cipher` is instantiated

---

## Test File Organization Issues

The test directory structure includes files that may not be intended as standalone tests:

```
test/
├── concrete_implementations_test.dart          (✅ Main test entry)
├── multi_peer_integration_test.dart            (✅ Main test entry)
├── src/
│   ├── concrete_implementations/
│   │   └── cipher/
│   │       ├── cipher_factories_test.dart      (❌ No main())
│   │       ├── ecdh_key_exchange_test.dart     (❌ No main())
│   │       ├── ermes_peer_cipher_impl_test.dart (❌ No main())
│   │       └── two_peer_cipher_exchange_test.dart (❌ No main())
│   └── multi_peer/
│       └── cipher_exchange_tests.dart          (Likely a helper)
│   └── utilities/
│       └── hash_utils_test.dart                (Status unknown)
```

**Recommendation**: Clarify which files are entry points vs. helper files.

---

## Quick Reference: Failing Tests

### All tests failing due to `_hexToBytes` (38 tests)
1. ECDHKeyExchangeService Serialization serialize returns valid base64url string [E]
2. ECDHKeyExchangeService Symmetric Cipher Generation generateISymmetric with custom algorithm [E]
3. ECDHKeyExchangeService Factory Methods generateFromSerialize deserializes correctly [E]
4-38. Various multi-peer and two-peer cipher exchange tests [E]

### Test file loading failures (4 tests)
1. Failed to load cipher_factories_test.dart
2. Failed to load ecdh_key_exchange_test.dart
3. Failed to load ermes_peer_cipher_impl_test.dart
4. Failed to load two_peer_cipher_exchange_test.dart

### Other failures (8 tests)
1. Cipher Factories createCipher ChaCha20 cipher can encrypt and decrypt [E]
7. Various stress and bidirectional communication tests

---

## Next Steps

1. **Immediate**: Fix the `_hexToBytes` method - this will likely resolve 38+ test failures
2. **Short-term**: Clarify test file structure and add missing `main()` functions
3. **Follow-up**: Test the ChaCha20 fix after hexadecimal parsing is resolved
4. **Validation**: Run tests again and verify all 164 tests pass

---

**Report Generated**: 2026-02-17
**Test Duration**: ~2 seconds
**Command**: `dart test`
