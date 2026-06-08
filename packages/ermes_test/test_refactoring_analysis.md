# Test Refactoring Analysis — Dummy/Mock Removal

## Stato Attuale

**Risultato finale:** 874 test passanti ✅ (da ~531 a 874, +343 nuovi test)

### ✅ Completato — Storage Tests (3 files, 197 test)
Sostituiti tutti i mock storage (`_InMemoryStorage`, `MockStorageRepository`, `MockStorage`) con `ErmesStorageRepository(WorkDb.memory())`.

### ✅ Completato — MessageControl (0 dipendenze)
`ErmesMessageControlService` e `ErmesMessageControlRepository` usati direttamente.

### ✅ Completato — IErmesRepository (6 su 8 stub rimossi)

**Approccio:** `RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0)` + `ShspSocket.fromRaw()` crea un socket UDP reale su porta locale. Funziona in qualsiasi ambiente di test.

**Punti chiave:**
- `ErmesRepository` si costruisce senza problemi — `sendHandshake()` nel costruttore è fire-and-forget UDP, non crasha
- `openState` è un setter pubblico su `ShspInstance` — `repo.openState = true` abilita `send()`
- `ErmesSignalingHandler()` ha costruttore vuoto, nessun side effect
- `ErmesBookServiceBase()` + `setAccount()` preconfigura il peer info

| File | Stub Rimosso | Sostituito Con |
|------|-------------|----------------|
| `ermes_newkey_callback_unit_test.dart` | `_SimpleRepository` | `ErmesRepository` reale |
| `ermes_connection_test.dart` | `_StubRepository` | `ErmesRepository` reale |
| `ermes_newkey_callback_test.dart` | `_TestErmesRepository` | `TestErmesRepository` helper |
| `ermes_encryption_decryption_test.dart` | `_TestErmesRepository` | `TestErmesRepository` helper |
| `ermes_service_impl_test.dart` | `_TestErmesRepository` | `ErmesRepository` reale |
| `ermes_peer_test.dart` | `_FakeErmesService` | `ErmesService` reale + `TestErmesRepository` |

### ✅ Completato — IErmesRepository retransmission (2 stub rimossi, 1 mantenuto)

| File | Stub | Sostituzione |
|------|------|-------------|
| `ermes_service_retransmission_test.dart` | `_TestErmesRepository` + `_TestStorage` + `_TestMessageControlService` | `TestErmesRepository` da `test_helpers.dart`, storage rimosso (inutilizzato), `ErmesMessageControlFactory.createBoth()` + `setupMissingIds()` helper |
| `ermes_peer_retransmission_integration_test.dart` | `_BridgeRepository` | Spostato in `ermes_test_with_mock` (routing in-process, nessun mock framework) |

### ✅ Completato — IErmesSignalingServer (1 stub risolto)

`_DummySignalingServer` in `ermes_signaling_reconnector_test.dart` sostituito con `ErmesSignalingServer` reale + `_FakeNostrSignaling` (fake `INostrSignaling` senza rete). Il test è stato spostato in `ermes_test_with_mock`.

## Bug Fixes Trovati Durante il Refactoring

La sostituzione degli stub con implementazioni reali ha rivelato diversi bug latenti:

### `WorkDb.io()` → `WorkDb.memory()`
- **Problema:** `PeerStorageInstance` usava `WorkDb.io()` (file JSON su disco). I file residui di run precedenti con serializzazione incompatibile causavano `FormatException: Unexpected end of input` in 43 test.
- **Fix:** `packages/ermes_storage/lib/src/ermes_storage_and_caching_messages_handler.dart` — cambiato `WorkDb.io()` in `WorkDb.memory()`

### Async non gestito nei test
- **Problema:** `sendRepo.send()`, `peer.send()`, `service.send()` sono `Future<void>` ma venivano chiamati senza `await`. Lo storage async continuava dopo il test, causando errori.
- **Fix:** Aggiunto `await` in `ermes_encryption_decryption_test.dart`, `ermes_peer_test.dart`, `ermes_service_impl_test.dart`

### `integrityCheckValue` come `Digest` invece di `String`
- **Problema:** `MessageRoot.toJson()` includeva `integrityCheckValue` come oggetto `Digest`, incompatibile con la serializzazione JSON di `WorkDb`.
- **Fix:** Normalizzato a `String` via `.toString()` in `MessageRoot.toJson()` (`packages/iermes/lib/src/types/ermes/message_root.dart`)

### Socket cleanup in test
- **Problema:** `TestErmesRepository.cleanUp()` chiamava `rawSocket.close()` bypassando `ShspSocket`, lasciando `_socketSubscription` attivo.
- **Fix:** Sostituito con `socket.close()` in `packages/ermes_test/test/src/test_helpers.dart`

### `Duration.zero` insufficiente per UDP
- **Problema:** `_sendRootMessage()` usava `Future.delayed(Duration.zero)` che non introduce ritardo reale. Buffer UDP esaurito con messaggi multipli.
- **Fix:** Cambiato in `const Duration(milliseconds: 1)` in `packages/ermes_core/lib/src/ermes_send_repo.dart`

## Test Spostati in `ermes_test_with_mock`

I file che richiedono ancora implementazioni minime di interfacce (stub/fake, non mock framework) sono stati spostati in `packages/ermes_test_with_mock/`:

| File | Test Doppi | Motivo |
|------|-----------|--------|
| `ermes_connection_test.dart` | `_TrackingSignalingHandler`, `_FailingClearHandler` | Type parameter `<IShspSocket>` vs `<ShspPeer>` |
| `ermes_peer_retransmission_integration_test.dart` | `_BridgeRepository` | Routing in-process senza socket UDP reali |
| `ermes_signaling_reconnector_test.dart` | `_FakeNostrSignaling`, `_TrackingHandler` | `INostrSignaling` non testabile senza fake + type parameter |

## Riepilogo

| Priorità | Area | Stub Rimossi | Stato |
|----------|------|-------------|-------|
| 1 | Storage | 3 | ✅ COMPLETATO |
| 2 | MessageControl | 1 | ✅ COMPLETATO |
| 3 | IErmesRepository | 6 | ✅ COMPLETATO |
| 4 | IErmesService (FakeErmesService) | 1 | ✅ COMPLETATO |
| 5 | IErmesRepository (retransmission) | 2 | ✅ COMPLETATO |
| 6 | IErmesSignalingServer | 1 | ✅ COMPLETATO (spostato in mock project) |
| 7 | IErmesSignalingHandler | 3 | ➡️ SPOSTATI in `ermes_test_with_mock` |

**Stub rimossi/sostituiti:** 14 (su 19 totali).  
**Bug trovati e fixati durante il refactoring:** 6.  
**Test totali:** 874 passanti ✅ (da ~531).

## Helper Condiviso

`test/src/test_helpers.dart` contiene:
- `createTestRepository()` — crea `ErmesRepository` con socket reale
- `TestErmesRepository extends ErmesRepository` — aggiunge `sentData` + `simulateDataReceived()`
- `setupMissingIds()` — popola ID mancanti su `IErmesMessageControlService` reale usando `idArrived()` (per test threshold/timer)
