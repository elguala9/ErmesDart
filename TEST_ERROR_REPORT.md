# ErmesDart Test Error Report

## Summary
**Total Tests Run:** 225
**Passed:** 217
**Failed:** 8
**Success Rate:** 96.4%

---

## Critical Errors (8 total)

### 1. **ChaCha20 IV Size Error** (2 occurrences)
**Location:** `packages/ermes_test/test/src/concrete_implementations/cipher/cipher_factories_test.dart:133:34`
**Error:** `Invalid argument(s): ChaCha20 requires exactly 8 bytes of IV`
**Root Cause:** ChaCha20 algorithm in `cryptdart` requires exactly 8 bytes of Initialization Vector (IV), but the cipher factory is providing a different size.
**Affected Component:** `createCipher()` factory function for ChaCha20
**Test:** `Cipher Factories createCipher ChaCha20 cipher can encrypt and decrypt`

**Fix Required:**
- Check `packages/ermes_cipher/lib/src/factories/ermes_cipher_factories.dart`
- Verify IV generation for ChaCha20 ensures exactly 8 bytes
- May need to adjust random IV generation or use 8-byte IV specifically for ChaCha20

---

### 2. **Missing Decryption Cipher** (1 occurrence)
**Location:** `packages/ermes_test/test/src/multi_peer/cipher_exchange_tests.dart:138:24`
**Error:** `CipherException: Decryption cipher not found for key 461a96ff657311dfcba1872b3a0118ef6f47eced328acf0b5df1a0e6a450e9f0`
**Root Cause:** In multi-peer scenarios, decryption cipher is not properly registered or synchronized across peers.
**Affected Component:** `ErmesPeerCipher.decrypt()` in `packages/ermes_cipher/lib/src/ermes_peer_cipher.dart:59`
**Test:** `Multi-Peer Cipher Exchange Tests Three-Peer Mesh Network with Ciphers three peers can all communicate with each other`

**Issue:** The cipher key ID doesn't exist in the peer's decryption cipher registry when attempting to decrypt.

---

### 3. **Non-deterministic Encryption** (2 occurrences)
**Location:** `packages/ermes_test/test/src/concrete_implementations/cipher/two_peer_cipher_exchange_test.dart:160:9`
**Error:** `Expected: not [62, 185, 114, 64, ...] Actual: [62, 185, 114, 64, ...]` (Same ciphertext)
**Root Cause:** Test expects same plaintext with same key to produce different ciphertexts (due to IV randomization), but getting identical ciphertexts instead.
**Affected Test:** `Two-Peer Cipher Exchange Integration Bidirectional Communication same message produces different ciphertexts`

**Issue:** Either:
- IV is not being randomized per encryption operation
- IVs are being reused instead of generated fresh each time
- Cipher state is carrying over between operations

---

### 4. **Digest Object JSON Serialization Error** (1 occurrence)
**Location:** `packages/ermes_test/test/src/concrete_implementations/core/ermes_service_impl_test.dart:85:35`
**Error:** `Converting object to an encodable object failed: Instance of 'Digest'`
**Root Cause:** Attempting to JSON encode a `Digest` object which is not JSON serializable.
**Affected Component:** `objectToUint8Array()` in `packages/ermes_core/lib/src/ermes_send_repo.dart:38`
**Test:** `ErmesService Concrete Implementation Message Callbacks addOnMessageDataListener registers callback`

**Fix Required:**
- Digest objects must be converted to bytes before JSON serialization
- Check if Digest has a `.bytes` property or similar

---

### 5. **Insufficient Generated Keys in Stress Test** (1 occurrence)
**Location:** `packages/ermes_test/test/src/multi_peer/cipher_exchange_tests.dart:240:9`
**Error:** `Expected: <50> Actual: <44>`
**Root Cause:** Stress test expected 50 successfully generated keys but only got 44.
**Affected Test:** `Multi-Peer Cipher Exchange Tests Stress Tests can handle rapid key generation`

**Issue:** Some key generation operations may be failing silently or timing out during rapid generation.

---

### 6. **Wrong Exception Type for Invalid KeyId** (1 occurrence)
**Location:** `packages/ermes_test/test/src/multi_peer/cipher_exchange_tests.dart:302:9`
**Error:** `Expected: throws <CipherException> Actual: threw ArgumentError: Input data length must be a multiple of cipher's block size`
**Root Cause:** When decrypting with wrong keyId, the code attempts to use wrong cipher which fails with `ArgumentError` instead of `CipherException`.
**Affected Component:** `ErmesPeerCipher.decrypt()` - no validation before attempting decryption
**Test:** `Multi-Peer Cipher Exchange Tests Error Handling wrong keyId throws CipherException`

**Fix Required:**
- Add explicit check in `decrypt()` method for keyId existence
- Throw `CipherException` before attempting decryption with wrong key

---

## Error Categories

| Category | Count | Severity |
|----------|-------|----------|
| ChaCha20 IV Configuration | 2 | 🔴 High |
| Missing Cipher Registration | 1 | 🔴 High |
| Non-deterministic Behavior | 2 | 🟡 Medium |
| JSON Serialization | 1 | 🟡 Medium |
| Stress Testing | 1 | 🟡 Medium |
| Exception Handling | 1 | 🟡 Medium |

---

## Recommended Fix Priority

1. **🔴 URGENT - ChaCha20 IV Size (2 failures)**
   - Affects cipher factory functionality
   - Easy fix: ensure 8-byte IV for ChaCha20
   - File: `packages/ermes_cipher/lib/src/factories/ermes_cipher_factories.dart`

2. **🔴 URGENT - Missing Decryption Cipher (1 failure)**
   - Breaks multi-peer communication
   - Investigate cipher key synchronization
   - File: `packages/ermes_cipher/lib/src/ermes_peer_cipher.dart`

3. **🟡 MEDIUM - Exception Type for Invalid KeyId (1 failure)**
   - Add validation in decrypt method
   - File: `packages/ermes_cipher/lib/src/ermes_peer_cipher.dart`

4. **🟡 MEDIUM - Non-deterministic Encryption (2 failures)**
   - Review IV generation logic
   - Ensure IV is randomized per operation

5. **🟡 MEDIUM - JSON Serialization (1 failure)**
   - Add Digest object serialization
   - File: `packages/ermes_core/lib/src/ermes_send_repo.dart`

6. **🟡 MEDIUM - Stress Test (1 failure)**
   - Investigate key generation failures under load

---

## Next Steps

1. Review `packages/ermes_cipher/lib/src/factories/ermes_cipher_factories.dart` - IV configuration
2. Check `packages/ermes_cipher/lib/src/ermes_peer_cipher.dart` - decrypt method validation
3. Verify `packages/ermes_core/lib/src/ermes_send_repo.dart` - Digest serialization
4. Investigate IV generation and randomization strategy
5. Profile stress test for key generation bottlenecks
