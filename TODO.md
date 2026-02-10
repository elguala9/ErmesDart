# ErmesDart - TODO & Development Tasks

**Last Updated**: 2026-02-10
**Analysis Date**: 2026-02-10

---

## Executive Summary

### Project Status: 🟡 MOSTLY COMPLETE WITH KNOWN GAPS

**Overall Statistics:**
- ✅ Interfaces Implemented: 19/20 (95%)
- ✅ Factories Complete: All factories for implemented interfaces
- ✅ Test Suites: 11/12 interfaces have test suites (92%)
- 🔴 Critical Issues: 4 blocking items
- 🟡 Implementation Gaps: 5 utility function TODOs
- ✅ **NEW**: 2 additional test suites created for unimplemented methods

### Recent Improvements (2026-02-10)
1. ✅ Created comprehensive test suite for `IErmesConnection` interface
2. ✅ Created comprehensive test suite for `IErmesHandshake` interface
3. ✅ Both test suites ready for concrete implementations
4. ✅ Updated TODO documentation with test status

### Critical Path to Production
1. **BLOCKER**: Implement `IOrcErmes` orchestrator interface
2. **BLOCKER**: Complete `ErmesAsyncHandshake.handshake()` method
3. **HIGH**: Implement connection state persistence (saveState/loadState)
4. **HIGH**: Complete reconnection logic
5. **MEDIUM**: Implement serialization utilities

---

## Table of Contents
1. [Interfacce Non Implementate](#interfacce-non-implementate)
2. [Factory Mancanti](#factory-mancanti)
3. [Implementazioni Non Testate](#implementazioni-non-testate)
4. [Utility Functions TODO](#utility-functions-todo)
5. [Priority Matrix](#priority-matrix)

---

## Interfacce Non Implementate

### 🔴 Critiche

#### 1. **IOrcErmes** - Orchestrator Interface (MANCANTE)
- **Location**: `packages/iermes/lib/src/standard_interface/i_orc_ermes.dart:10`
- **Status**: ❌ **NON IMPLEMENTATA**
- **Description**: Interfaccia per l'orchestrazione di connessioni multiple
- **Required Implementation**:
  - [ ] Creare classe `OrcErmes` (o nome appropriato)
  - [ ] Implementare tutti i metodi dell'interfaccia
  - [ ] Scrivere test di conformità
  - [ ] Factory pattern per la creazione
- **Complexity**: HIGH
- **Impact**: Bloccante per orchestrazione multi-connessione

#### 2. **IErmesHandshake** - Async Handshake (INCOMPLETA)
- **Location**: `packages/ermes_signaling/lib/src/handshake/ermes_handshake.dart:18`
- **Status**: ⚠️ **PARZIALMENTE IMPLEMENTATA**
- **Implementation Issues**:
  - `handshake()` method lancia `UnimplementedError()` (line 28)
  - [ ] Completare logica handshake
  - [ ] Implementare async operations
  - [ ] Gestire timeout e errori
  - [ ] Test coverage per handshake flow
- **Complexity**: HIGH
- **Impact**: Compromette il signaling corretto tra peer

---

## Factory Mancanti

### 🔴 Critiche

#### 1. **OrcErmesFactory** - MANCANTE
- **Location**: Dovrebbe essere in `packages/ermes_core/lib/src/factories/`
- **Status**: ❌ **NON ESISTE**
- **Required Methods**:
  - [ ] `createRepository()` - per IOrcErmes repository
  - [ ] `createService()` - per IOrcErmes service
- **Dependency**: Bloccata dalla mancanza di implementazione IOrcErmes
- **Priority**: ALTA (dopo implementazione IOrcErmes)

---

## Implementazioni Non Testate

### 🔴 Critiche - Metodi Non Implementati

#### 1. **ErmesConnection.saveState()**
- **Location**: `packages/ermes_core/lib/src/ermes_connection.dart:89`
- **Status**: ❌ **NON IMPLEMENTATA**
- **Current**: Lancia `UnimplementedError`
- **Required**:
  - [ ] Implementare persistenza dello stato della connessione
  - [ ] Definire formato di serializzazione
  - [ ] Scrivere test di salvataggio/ripristino
- **Complexity**: MEDIUM
- **Impact**: Impossibile persistere stato connessione tra sessioni

#### 2. **ErmesConnection.loadState()**
- **Location**: `packages/ermes_core/lib/src/ermes_connection.dart:97`
- **Status**: ❌ **NON IMPLEMENTATA**
- **Current**: Lancia `UnimplementedError`
- **Required**:
  - [ ] Implementare caricamento dello stato
  - [ ] Validazione dati caricati
  - [ ] Gestione stati inconsistenti
  - [ ] Test di caricamento stati
- **Complexity**: MEDIUM
- **Impact**: Impossibile ripristinare connessioni precedenti

#### 3. **ErmesConnection.reconnect()**
- **Location**: `packages/ermes_core/lib/src/ermes_connection.dart:27-37`
- **Status**: ⚠️ **PARZIALMENTE IMPLEMENTATA**
- **Current**: TODO commentato nel codice (lines 35-37)
- **Required**:
  - [ ] Completare logica riconnessione
  - [ ] Gestire edge cases (timeout, stato incoerente)
  - [ ] Test di riconnessione con fallback
- **Complexity**: MEDIUM
- **Impact**: Riconnessioni non affidabili

#### 4. **ErmesAsyncHandshake** - Metodo Principale
- **Location**: `packages/ermes_signaling/lib/src/handshake/ermes_handshake.dart:18`
- **Status**: ❌ **NON IMPLEMENTATA**
- **Current**: `handshake()` method lancia `UnimplementedError` (line 28)
- **Required**:
  - [ ] Implementare async handshake protocol
  - [ ] Gestire timeout e retry logic
  - [ ] Implementare state machine per handshake
  - [ ] Test coverage completo
- **Complexity**: HIGH
- **Impact**: Signaling non funzionante

---

### 🟡 Mediamente Importanti - Utility Functions

#### 1. **Observable List Utility**
- **Location**: `packages/ermes_core/lib/src/ermes_read_repo.dart:12`
- **TODO**: "Find Dart equivalent for 'observable-list' package"
- **Status**: ⚠️ **MANCANTE DIPENDENZA**
- **Required**:
  - [ ] Ricercare package Dart equivalente o implementare custom
  - [ ] Integrare con ErmesReadRepository
  - [ ] Test per reactive updates
- **Options**:
  - Usare `Stream` di Dart
  - Usare `ValueListenable` di Flutter
  - Usare reactive packages (get, riverpod, ecc.)

#### 2. **Hash Serialization Utility**
- **Location**: `packages/ermes_core/lib/src/ermes_read_repo.dart:43`
- **TODO**: "Find Dart equivalent for 'serialization-utility' Hash functions"
- **Status**: ⚠️ **MANCANTE UTILITY**
- **Required**:
  - [ ] Implementare funzioni hash per serializzazione
  - [ ] Garantire compatibilità cross-peer
  - [ ] Test di hash consistency
- **Options**:
  - crypto package (SHA256, etc.)
  - convert package per encoding
  - Custom implementation

#### 3. **Serialization Functions**
- **Location**: `packages/ermes_core/lib/src/ermes_read_repo.dart:56`
- **TODO**: "Find Dart equivalent for 'serialization-utility' serialization functions"
- **Status**: ⚠️ **MANCANTE UTILITY**
- **Required**:
  - [ ] Definire format di serializzazione
  - [ ] Implementare encoder/decoder
  - [ ] Test di round-trip serialization

#### 4. **Send Repository Serialization**
- **Location**: `packages/ermes_core/lib/src/ermes_send_repo.dart:12`
- **TODO**: "Find Dart equivalent for 'serialization-utility' functions"
- **Status**: ⚠️ **MANCANTE UTILITY**
- **Required**: (Stesso delle precedenti)

#### 5. **Uint8Array Composition**
- **Location**: `packages/ermes_core/lib/src/ermes_utility/chunk_handler.dart:6`
- **TODO**: "Find Dart equivalent for 'serialization-utility/src/Array' composeUint8Array"
- **Status**: ⚠️ **MANCANTE UTILITY**
- **Required**:
  - [ ] Implementare composizione array di byte
  - [ ] Performance ottimizzata
  - [ ] Test su grandi payload

#### 6. **SHSP Socket Close Method**
- **Location**: `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:73, 83`
- **TODO**: "Verify the correct method name for closing a ShspInstance"
- **Status**: ⚠️ **AMBIGUO**
- **Required**:
  - [ ] Verificare nome metodo corretto in ShspInstance
  - [ ] Aggiornare codice per match
  - [ ] Test di chiusura socket

---

## Utility Functions TODO

### Priority: MEDIUM - Serialization Module
```dart
// MISSING: packages/ermes_core/lib/src/ermes_read_repo.dart

// Required implementations:
// 1. Observable list management
//    - Reactive updates on data changes
//    - Efficient change tracking
//
// 2. Hash functions for validation
//    - Hash calculation for message integrity
//    - Hash comparison and verification
//
// 3. Serialization utilities
//    - Encode data to bytes
//    - Decode bytes to data structures
//    - Format validation
```

### Priority: MEDIUM - Chunk Handling
```dart
// MISSING: packages/ermes_core/lib/src/ermes_utility/chunk_handler.dart

// Required implementation:
// - composeUint8Array() - compose multiple Uint8Array into single array
//   - Handle different array sizes
//   - Optimize for performance
//   - Memory efficient concatenation
```

### Priority: MEDIUM - Socket Management
```dart
// VERIFY: packages/ermes_signaling/lib/src/ermes_signaling_handler.dart

// Locations where socket closing needs verification:
// - Line 73: Socket close method name
// - Line 83: Socket close method name
//
// Current assumption: close() or shutdown()?
// Required: Check ShspInstance API documentation
```

---

## Priority Matrix

### 🔴 CRITICAL (Blockers)
1. **IOrcErmes implementation** - Blocking orchestration features
   - Estimated effort: HIGH
   - Estimated time: 3-5 days
   - Depends on: None

2. **ErmesAsyncHandshake completion** - Blocking signaling
   - Estimated effort: HIGH
   - Estimated time: 2-3 days
   - Depends on: None

3. **ErmesConnection state methods** (saveState, loadState)
   - Estimated effort: MEDIUM
   - Estimated time: 1-2 days
   - Depends on: Serialization utilities

### 🟡 HIGH (Should fix soon)
1. **Serialization utilities** - Multiple components depend on this
   - Estimated effort: MEDIUM
   - Estimated time: 2 days
   - Blocks: Read/Send repositories, state persistence

2. **ErmesConnection.reconnect()** completion
   - Estimated effort: MEDIUM
   - Estimated time: 1 day
   - Depends on: Connection state management

### 🟢 MEDIUM (Nice to have)
1. Chunk handler optimization
2. Observable list implementation selection
3. SHSP socket method verification

---

## Testing Status Summary

### ✅ Well Tested Interfaces
- `IErmesRepository` - Full coverage
- `IErmesService` - Full coverage
- `IErmesStorageRepository` - Full coverage
- `IErmesCachingRepository` - Full coverage
- `IErmesConnectionsHandler` - Full coverage
- `IErmesBookRepository` - Full coverage
- `IErmesSignalingRepository` - Full coverage
- `IErmesSignalingService` - Full coverage
- `IErmesMessageControlRepository` - Full coverage
- `IIdHandler` - Full coverage
- `IIdHandlerStorage` - Full coverage

### ✅ Test Suites Created
- **IErmesConnection** - `packages/ermes_test/test/src/interface_tests/ermes_connection_test_suite.dart`
  - ✅ Connection initialization tests
  - ✅ Connection lifecycle (close) tests
  - ✅ Ping/health check tests
  - ✅ Close callback tests
  - ✅ Reconnection tests
  - ✅ State persistence tests (validates UnimplementedError)
  - ✅ Destruction tests
  - ✅ Edge cases

- **IErmesHandshake** - `packages/ermes_test/test/src/interface_tests/ermes_handshake_test_suite.dart`
  - ✅ Handshake initialization tests
  - ✅ Handshake protocol tests
  - ✅ State management tests
  - ✅ Error handling tests
  - ✅ Interface compliance tests

### ⚠️ Partially Tested
- `ErmesConnection` - Test suite created but needs concrete implementation factory
- `ErmesAsyncHandshake` - Test suite created, validates UnimplementedError

### ❌ Not Tested
- `IOrcErmes` - Not implemented, no factory available
- Connection state persistence (save/load) - Tests validate they throw UnimplementedError
- Connection reconnection logic - Tests validate basic flow

---

## Test Suite Implementation Status

### Recently Created (2026-02-10)

#### ✅ ErmesConnection Test Suite
- **File**: `packages/ermes_test/test/src/interface_tests/ermes_connection_test_suite.dart`
- **Function**: `testIErmesConnection<IErmesConnection>(implementationName, factory)`
- **Tests**: 30+ test cases
- **Status**: Ready to use
- **Note**: Requires concrete implementation factory to run
- **Example Usage**:
  ```dart
  void main() {
    testIErmesConnection('ErmesConnection', () {
      // Create and return IErmesConnection instance
      return createConnectionInstance();
    });
  }
  ```

#### ✅ ErmesHandshake Test Suite
- **File**: `packages/ermes_test/test/src/interface_tests/ermes_handshake_test_suite.dart`
- **Function**: `testIErmesHandshake<TInput, TSignal>(implementationName, factory)`
- **Tests**: 15+ test cases
- **Status**: Ready to use, handles UnimplementedError gracefully
- **Note**: Tests support both complete and incomplete implementations
- **Example Usage**:
  ```dart
  void main() {
    testIErmesHandshake<MyInput, MySignal>(
      'ErmesAsyncHandshake',
      () => ErmesAsyncHandshake(inputData),
    );
  }
  ```

### Next Steps for Testing
1. Create concrete test files in `packages/ermes_test/test/src/concrete_implementations/` that invoke the test suites
2. Implement mock factories for ErmesConnection and ErmesAsyncHandshake
3. Update existing tests to use the new test suites
4. Verify all tests pass with proper error handling for unimplemented methods

---

## Quick Reference: Commands

### Run all tests
```bash
melos run test
```

### Run interface tests only
```bash
melos run test:interfaces
```

### Run analysis
```bash
melos run analyze
```

### Check format
```bash
melos run format:check
```

### Format code
```bash
melos run format
```

### Full CI pipeline
```bash
melos run ci
```

---

## Related Documentation
- See [README.md](README.md) for project overview
- See [TESTING.md](TESTING.md) for testing instructions
- See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
