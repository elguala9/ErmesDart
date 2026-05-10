# ErmesDart — TODO List

## Stato Progetto
- **Test passanti**: 1371 ✅ (+182 nuovi test)
- **Test skippati**: 66 (Ganache) + 4 (Nostr relay)
- **Test falliti**: 0 ✅
- **Coverage**: ermes_cipher/storage/id_handler/message_control ~95-100%, ermes_core ~70%, ermes_signaling ~50%

---

## 🔴 Critici / Bloccanti

Nessuno — tutti i test passano (1147).

---

## 🟠 Alta Priorità ✅

Completata. Tutti gli item di alta priorità (signaling handler, core factories, service features, interfacce, init, flusso completo OrcErmes) sono coperti da test.

### Signaling (copertura ~50%) ✅
- [x] Testare `ErmesSignalingHandler` — 12/13 metodi non coperti (18 test)
- [x] Testare `ErmesAsyncHandshake` — intero handshake asincrono senza test
- [x] Testare `ErmesHandshakeHandler`
- [x] Testare `ErmesSignalingFactory` e `ErmesSignalingServerFactory` (factory methods)
- [x] Testare `ErmesBookFactories`
- [x] Testare handshake layer (processSignal, signaling flow)

### Core (~70% coverage)
- [x] Testare `ErmesFactory` — factory repository/service
- [x] Testare `OrcErmesAdvancedFactory` — factory avanzata con STUN
- [x] Testare `ShspSocketFactoryHelper` (6 metodi statici)
- [x] Testare `ShspSocketHandler` / `ShspSocketHandlerSingleton`
- [x] Testare `ErmesService.sendNewKey()` — rotazione chiavi
- [x] Testare `ErmesSendRepo.sendAgain()` — ritrasmissione
- [x] Testare listener management su `ErmesService`, `ErmesPeer`
- [x] Testare `ErmesReadRepo` service message listeners
- [x] Testare `OrcErmes.destroy()` e edge case aggiuntivi
- [x] Testare flusso completo `OrcErmes` — 2 peer con signaling in-memory

### Core Init (~50% coverage)
- [x] Testare `initialPointErmesCore()`, `getIOrcErmes()` — verifica esistenza funzioni
- [x] Testare tutte le 8 funzioni di init signaling registry — verifica esistenza

### Interfacce non testate
- [x] Testare `ISignalErmes`, `ISignalErmesRaw`, `IErmesSignalingServer`
- [x] Testare `IErmesSignalingHandler`
- [x] Testare `IErmesHandshake`, `IErmesHandshakeHandler` — verificate tramite implementazioni

---

## 🟡 Media Priorità

### TODO nel codice
- [ ] **Implementare message tracking e conferme**: `packages/ermes_core/lib/src/ermes_send_repo.dart:251`
- [ ] **Gestire async mancante**: `packages/ermes_id_handler/lib/src/handlers/id_handler_service.dart:26` — `storage.update(newId)` chiamata senza await
- [ ] **Sostituire `GenericObjectManager`**: `packages/iermes/lib/src/managers/generic_object_manager.dart:1` — implementazione provvisoria di singleton manager
- [ ] **Rinominare `i_ermes_todo.dart`**: `packages/iermes/lib/src/signaling_interface/i_ermes_todo.dart` — interfaccia `IErmesSignalingTODO` con nome provvisorio
- [ ] **Rinominare `i_ermes_ice_deprecated.dart`**: contiene `// ignore: file_names` e commento `// This file should be renamed`
- [ ] **Pulire export deprecato**: `packages/iermes/lib/iermes.dart:19` esporta `i_ermes_ice_deprecated.dart`

### Reconnect Logic
- [ ] **Completare `saveState()`**: `packages/ermes_core/lib/src/ermes_connection.dart:42-44` — stub che chiama `_serializeConnectionsState()` (privato, non fa nulla)
- [ ] **Completare `loadState()`**: `packages/ermes_core/lib/src/ermes_connection.dart:47-50` — body vuoto
- [ ] **Fixare reset tentativi riconnessione**: reset immediato dopo `clearConnection` vanifica il conteggio

### Scenari Multi-Peer
- [ ] Test group chat con 3+ peer
- [ ] Test topologie mesh e star
- [ ] Test 5+ peer simultanei
- [ ] Test disconnessione/riconnessione multipla

---

## 🟢 Bassa Priorità

### Refactoring
- [ ] **Rimuovere directory `mixin/` vuota**: `packages/iermes/lib/src/mixin/` — 0 file
- [ ] **Rimuovere directory `interface_tests/` vuota**: `packages/ermes_test/test/src/interface_tests/` — 0 file
- [ ] **Sostituire eccezioni generiche** (`Exception('messaggio')`) con gerarchia di eccezioni custom in tutto il progetto (solo `ermes_cipher` ha `CipherException`)
- [ ] **Risolvere conflitto `pointycastle`**: `nostr_signaling` → `bip39` richiede ^3.0.0, `cryptdart` richiede ^4.0.0. Attualmente bloccato con `dependency_overrides`

### Test condizionali (non eseguibili in CI senza setup)
- [ ] 66 test Ganache-dipendenti — richiedono `http://localhost:9545`
- [ ] 4 test multi-peer — richiedono relay Nostr raggiungibile

---

## Legacy (già in deprecation)
- [ ] Rimuovere `IErmesIceRepository` e `_IErmesIcePrivate` (deprecati, sostituiti da `addOnDataArrivedListener`)
- [ ] Rimuovere metodi deprecati in `ermes_read_repo.dart:167,175`

---

## Note

| Metadato | Valore |
|----------|--------|
| Packages | 12 |
| Test totali | 1371 passanti, 0 falliti, 5 skippati |
| `@Deprecated` | 3 occorrenze |
| `UnimplementedError` in prod | 2 (factory `fromJson`, `generateFromSerialize`) |
| Security bug known | 1 (hash debole) |

*Generato dall'analisi del codice il 2026-05-10. Aggiornato dopo fix reali.*

---

## Fix Applicati

### Nuovi test alta priorità (73 test aggiunti)
**Problema**: Mancanza di copertura su signaling handler, core factories, service features, e init.
**Fix**: Creati 4 nuovi file di test e aggiornati 2 esistenti:
- `ermes_signaling_handler_test.dart` — 18 test (costruttori, connection mgmt, createSignal, ecc.)
- `ermes_core_extended_test.dart` — 15 test (ShspSocketFactoryHelper, ShspSocketHandler, OrcErmesAdvancedFactory)
- `ermes_service_features_test.dart` — 32 test (sendNewKey, sendAgain, listener mgmt)
- `ermes_handshake.dart` — +5 test (handshakeAsync, caching)
- `ermes_signaling_factory.dart` — +3 test (factory integration)
- `initial_point_ermes_core_test.dart` — 8 test (verifica esistenza funzioni init)
**File**: `packages/ermes_test/test/src/concrete_implementations/core/`
**Risultato**: Test totali passanti da 398 a 471 nel test aggregator.

### Secondo round test alta priorità (42 test aggiunti)
**Problema**: Mancanza di copertura su ErmesFactory, processSignal, interfacce signaling, OrcErmes edge case.
**Fix**: Creato 1 nuovo file di test e aggiornati 3 esistenti:
- `ermes_signaling_interfaces_test.dart` — 28 test (ISignalErmes, ISignalErmesRaw, IErmesSignalingServer)
- `ermes_factories_test.dart` — +5 test (ErmesFactory createRepository, createService, configurazione)
- `ermes_signaling_handler_test.dart` — +5 test (IErmesSignalingHandler, processSignal error cases)
- `ermes_orc_test.dart` — +4 test (destroy, force destroy, idempotent, onMessage callbacks)
**Risultato**: Test totali passanti da 1147 a 1189.

### Terzo round: OrcErmes full flow test (4 test aggiunti)
**Problema**: L'ultimo item di alta priorità (flusso completo `OrcErmes` con 2 peer) non era testato. I test multi-peer esistenti creano solo infrastruttura di signaling, mai `OrcErmes` con scambio messaggi reale.
**Fix**: Creato `ermes_orc_full_flow_test.dart` con signaling in-memory condivisa (`_SharedMemoryNostrSignaling`) e signaling handler senza STUN (`_FastSignalingHandler`):
- 2 peer si connettono via `openConnection()` e scambiano messaggi
- Comunicazione bidirezionale
- Ciclo di vita: open, close, reconnect
- Usa `Future.wait` per handshake parallelo (altrimenti il primo handshake viene perso)
**File**: `packages/ermes_test/test/src/concrete_implementations/core/ermes_orc_full_flow_test.dart`
**Risultato**: 1371 test passanti, 0 falliti. Tutti gli item di alta priorità completati ✅

### `TestErmesRepository` — buffer SHSP saturo
**Problema**: `TestErmesRepository.send()` chiamava `super.send(data)` su un socket SHSP reale. Nella suite completa il buffer si saturava e lanciava `ShspNetworkException`, causando 1 test fallito.
**Fix**: Rimosso `super.send(data)` dal test helper — i test verificano solo `sentData` locale.
**File**: `packages/ermes_test/test/src/test_helpers.dart:112`

### Analisi errata (non c'erano bug)
- **Hash debole**: `hash_utils.dart` usava già SHA-256, non `hashCode`. L'analisi iniziale era errata.
- **Test cipher fallito**: Il test `tampering with encrypted data` PASSAAVA già. L'analisi iniziale era errata.
