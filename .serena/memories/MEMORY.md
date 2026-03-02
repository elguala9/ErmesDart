# Parresia ErmesDart Project Memory

## OrcErmes Test Suite + GanacheManager ✅ COMPLETED (2026-03-03)
**Final Status**: Fully automated Ganache startup from Dart
- GanacheManager finds docker-compose-evm.yml from any subdirectory
- Auto-cleans old containers/networks before startup
- Supports docker-compose v1 and v2 syntax
- Windows-compatible with fallback paths
- Simple usage: `cd packages/ermes_test && dart test`

**Key Improvements**:
1. Path resolution: Searches parent directories (up to 5 levels)
2. Aggressive cleanup: Removes conflicting containers/networks
3. Network naming: Fixed parresia-contract-network → parresia-ermes-network
4. Fallback support: docker-compose AND docker compose (v2)

**Test Execution Flow**:
1. dart test (from packages/ermes_test)
2. setUpAll → GanacheManager.initialize()
3. Find docker-compose-evm.yml (anywhere in parent path)
4. Clean old containers/networks
5. Start: docker-compose up -d
6. Wait: health check via curl
7. Execute: 128 core + 19 OrcErmes tests
8. tearDownAll → GanacheManager.cleanup()
9. Stop: docker-compose down (if we started it)

**Commits**:
- 1c556db: feat: Add OrcErmes test suite
- 3c01001: feat: Add GanacheManager auto-startup
- 22519ea: docs: Add GANACHE_AUTO_STARTUP.md
- c79b596: improve: Windows compatibility
- 8c1439b: improve: Path resolution and cleanup

## OrcErmes Test Suite ✅ COMPLETED (2026-03-03)
**Files Created**:
- `packages/ermes_test/test/src/concrete_implementations/orchestration/orc_ermes_test.dart` (19 tests)
- `packages/ermes_test/test/src/concrete_implementations/orchestration/orchestration_tests.dart` (aggregator)

**Test Coverage** (19 tests total):
1. **Connection Management** (4): openConnection, closeConnection, getConnections, idempotency
2. **Message Exchange** (5): send, onMessage, multiple callbacks, fragmentation
3. **Lifecycle** (3): destroy, destroy(force), save
4. **Bidirectional** (2): Alice↔Bob, sequential exchanges
5. **Error Handling** (3): invalid peer, closed connection, multiple destroy

**Key Features**:
- ✅ NO MOCKS - Real components only
- ✅ Real SignalingContract on Ganache
- ✅ Real SHSP socket & STUN handler (factory helpers)
- ✅ Graceful skip if Ganache unavailable
- ✅ Integrated into concrete_implementations_test.dart
- ✅ All compile without errors

**Execution** (requires Ganache):
```bash
docker compose -f docker-compose-evm.yml up -d
dart test packages/ermes_test/test/concrete_implementations_test.dart
```

## Auto-Ganache Test Runner ✅ IMPLEMENTED (2026-03-02)
**New Feature**: Automatic Ganache startup integrated into test runner

### Tool: `tool/test_runner.dart`
Dart script that intelligently manages Ganache lifecycle:
1. **Check Ganache**: Detects if Ganache is already running at http://localhost:9545
2. **Auto-Start**: If unavailable and Docker available, starts `docker-compose-evm.yml`
3. **Health Check**: Waits up to 30 seconds for Ganache to respond
4. **Run Tests**: Executes full test suite (549 tests)
5. **Fallback**: If Docker unavailable, gracefully continues (531 tests pass, 18 skip)
6. **Cleanup**: Automatically stops Ganache after tests complete

### Updated Scripts
- **scripts/run_tests.sh** (Linux/Mac): Simplified to call `dart run tool/test_runner.dart`
- **scripts/run_tests.bat** (Windows): Simplified to call `dart run tool/test_runner.dart`

### Usage
```bash
# Linux/Mac
./scripts/run_tests.sh

# Windows
scripts\run_tests.bat

# Or directly
dart run tool/test_runner.dart
```

### Test Results
- **With Docker**: 549 tests passing ✅ (531 unit + 18 Ganache)
- **Without Docker**: 531 tests passing ✅, 18 tests skip gracefully

### Key Implementation Details
- Uses `Process.run()` to execute docker-compose
- Health check via curl to http://localhost:9545
- 30-second retry loop with 1-second intervals
- Graceful exception handling for all failure modes
- Only stops Ganache if we started it

## Test Suite Status: ✅ ALL TESTS PASS (2026-03-02)
**Total Tests**: 549
- **531 tests PASSING** ✅
- **18 tests SKIPPED** (gracefully - ErmesSignalingServer when Ganache unavailable)
- **0 tests FAILING** ✅

**Key Fix**: Modified `ermes_signaling_server_test.dart` to skip gracefully when Ganache unavailable:
- Moved `ganacheAvailable` to global scope (initialized to `false`)
- Uses `skip` parameter on group instead of throwing exceptions
- Tests skip with message: "Ganache not available at http://localhost:9545"
- Result: **No test failures**, only skips when infrastructure unavailable

## Dart Test Fixes: Async Storage & Singleton Isolation ✅ COMPLETED (2026-03-02)
**Task**: Fix dart test errors after removing `IErmesStorageAndCaching` injection from `ErmesService`
**Files Modified**:
1. **ermes_send_repo.dart** (Bug Fix):
   - Fixed critical bug: `sendAgain()` had unconditional `throw Exception()` - removed it
   - Made `send()` async and `sendMessageType()` async to await storage operations
   - Root cause: Messages weren't stored in-memory cache before tests tried to retrieve them
   - Solution: Await storage operations so callers ensure storage completes before proceeding

2. **ermes_service.dart** (API Change):
   - Updated `send()` to be `async` and await `ermesSendRepo.send()`
   - Moved post-send listeners to after storage completes

3. **i_ermes.dart** (Interface Update):
   - Updated interface signature: `void send()` → `Future<void> send()`

4. **ermes_service_retransmission_test.dart** (Test Fixes):
   - Made `_TestErmesRepository` accept optional `peerId` parameter
   - Added `testCounter` in setUp to generate unique peerId per test (avoiding singleton contamination)
   - Updated all `service.send()` calls to `await service.send()`
   - Fixed obsolete tests that relied on old pre-storage parameter

5. **ermes_peer_test.dart** (Mock Update):
   - Updated `_FakeErmesService.send()` to return `Future<void>`

## ErmesSignalingServer v2.0.0 Upgrade ✅ COMPLETED (2026-03-01)
**File**: `packages/ermes_signaling/lib/src/ermes_signaling_server.dart`
**Changes**:
1. Removed `ignore_for_file: argument_type_not_assignable` comment (no longer needed)
2. Replaced `dart:typed_data` import with `signaling_contract_extensions.dart`
3. Added `EthereumAddress` import from `wallet` package
4. Updated `getSignal()` to use `getSignalCompressed()` (handles gzip auto-decompression)
5. Updated `setSignal()` to use `setSignalCompressed()` (handles gzip auto-compression)
6. Added `wallet: ^0.0.18` to pubspec.yaml dependencies
7. **Test Result**: All 128 tests passing ✅

## Testing Guidelines
- **No mocks in tests** - Use only real implementations, not mocks or fake objects
- See `packages/ermes_test/CLAUDE.md` for testing guidelines
- **Encryption/Decryption Tests**: Created comprehensive tests covering:
  - ErmesSendRepo encryption when cipher IS available
  - ErmesSendRepo encryption when cipher is NOT available (null case)
  - ErmesReadRepo decryption when digest is present
  - ErmesReadRepo handling when digest is null (no encryption)
  - End-to-end encryption/decryption flows including fragmentation

## Test Organization (2026-02-28) ✅ CENTRALIZED
**Requirement**: All tests must be in `ermes_test` package only
**Status**: ✅ COMPLETED
- Moved 6 storage tests from `packages/ermes_storage/test/` → `packages/ermes_test/test/src/concrete_implementations/storage/`
- Removed test dev_dependency from ermes_storage pubspec.yaml
- No other packages have test directories (verified)
- Created aggregator `storage_tests.dart` for running all storage tests

## ErmesService Retransmission Test Suite (Completed ✅)
**File**: `packages/ermes_test/test/src/concrete_implementations/core/ermes_service_retransmission_test.dart`
- **27 comprehensive tests** covering all four retransmission paths
- **Test Groups**:
  1. Service Creation & Validation (3) - maxByte > 1024 throws error
  2. Send Callbacks (4) - onDataSending/Sent execution order
  3. Receive Errors (2) - empty messages, buffer overflow handling
  4. Acknowledge-based (4) - gap detection and resend logic
  5. Array Request (3) - explicit peer requests for missing IDs
  6. Periodic Timer (4) - time-based background checks
  7. Threshold-based (4) - reactive control after each message
  8. Lifecycle (3) - idempotency and cleanup
- **Helper Implementations** (no mocks, all real):
  - `_TestErmesRepository` - with configurable `open` state
  - `_TestStorage` - in-memory `IErmesStorageAndCaching` implementation
  - `_TestMessageControlService` - configurable missing ID tracking

## Book API Design: Sync Methods
- **IErmesBookService** and **IErmesBookRepository** are now fully synchronous
- No `Future` in method signatures - direct returns for in-memory operations
- Methods: `setAccount()`, `getAccount()`, `listOfIds()`, `deleteAccount()`, etc.

## Architecture Pattern: IdAccountType over ErmesPeerInfo
**Goal**: Reduce coupling - pass only IDs to repository/service layer
**Pattern**: When full peer info needed, use IErmesBookService to retrieve it
**Implementation**:
- **ErmesRepository**:
  - Public factory: `ErmesRepository.create(remotePeerId, socket, signalHandler, ermesBookService)`
  - Internally retrieves ErmesPeerInfo from book service
  - Private constructor handles actual ShspInstance creation
- **ErmesSignalingHandler**: Injects IErmesBookService, calls `getPeerInfo(id)` when needed
- **IErmesBookService**: Added method `getPeerInfo(IdAccountType): Future<ErmesPeerInfo?>`

## ErmesService Constructor (Updated 2026-03-02)
**File**: `packages/ermes_core/lib/src/ermes_service.dart`
**Current Signature**:
```dart
ErmesService({
  required IErmesRepository repository,
  required IIdHandlerService idHandler,
  int? maxBuffer,                        // Max buffered messages (default 100)
  int? maxByte,                          // Max message size (default 16KB)
  CallbackOnDataArrived? callbackOnDataArrived,  // Data arrival callback
  this.ermesMessageControlService,       // Optional: message tracking for retransmission
  int? missingMessagesCheckIntervalMs,   // Periodic timer interval (optional)
  this.missingMessagesThreshold,         // Threshold for missing ID requests (optional)
})
```
**Note**: Storage is handled separately in ErmesReadRepo (no direct `ermesStorageAndCaching` param)

## ECDH Cipher Key Exchange Fix ✅ VERIFIED (2026-02-28)
**Issue**: AES cipher was rejecting keys with "Key length not 128/192/256 bits" error
**Root Cause**: When ECDH passed bytes to `generateSymmetric()`, they were reconverted to hex string without length validation
**Solution** (commit bc295fa):
- Added `_hexStringToBytes()` helper in ermes_cipher_factories.dart for reliable hex→bytes conversion
- Added AES key length validation (ensures 128/192/256 bit keys)
- Improved error messages for diagnostics
- Modified `generateISymmetric()` to convert shared secret from hex to bytes
- Updated `generateSymmetric()` to accept both String and byte keys
**Status**: ✅ Tests passing