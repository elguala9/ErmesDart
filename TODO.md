# ErmesDart — TODO List

## Stato Progetto
- **Test passanti**: 799 ✅
- **Test skippati**: 66 (Ganache) + 4 (Nostr relay)
- **Test falliti**: 1 ❌
- **Coverage**: ermes_cipher/storage/id_handler/message_control ~95-100%, ermes_core ~70%, ermes_signaling ~50%

---

## 🔴 Critici / Bloccanti

- [ ] **Fix test fallito**: `tampering with encrypted data fails during decryption` in `packages/ermes_test/test/src/concrete_implementations/cipher/ermes_peer_key_exchange_test.dart` — la corruzione dei dati causa `Exception: Unknown algorithm byte: 0xa0` invece del fallimento di decifratura atteso
- [ ] **Sostituire hash debole con SHA-256**: `packages/ermes_core/lib/src/ermes_read_repo.dart` usa `data.hashCode.toString()` (Dart hashCode, non crittografico) invece di SHA-256. Rischio collisioni.

---

## 🟠 Alta Priorità

### Signaling (copertura ~50%)
- [ ] Testare `ErmesSignalingHandler` — 12/13 metodi non coperti
- [ ] Testare `ErmesAsyncHandshake` — intero handshake asincrono senza test
- [ ] Testare `ErmesHandshakeHandler`
- [ ] Testare `ErmesSignalingFactory` e `ErmesSignalingServerFactory` (factory methods)
- [ ] Testare `ErmesBookFactories`
- [ ] Testare handshake layer (processSignal, signaling flow)

### Core (~70% coverage)
- [ ] Testare `ErmesFactory` — factory repository/service
- [ ] Testare `OrcErmesAdvancedFactory` — factory avanzata con STUN
- [ ] Testare `ShspSocketFactoryHelper` (6 metodi statici)
- [ ] Testare `ShspSocketHandler` / `ShspSocketHandlerSingleton`
- [ ] Testare `ErmesService.sendNewKey()` — rotazione chiavi
- [ ] Testare `ErmesSendRepo.sendAgain()` — ritrasmissione
- [ ] Testare listener management su `ErmesService`, `ErmesPeer`
- [ ] Testare `ErmesReadRepo` service message listeners
- [ ] Testare flusso completo `OrcErmes`

### Core Init (~50% coverage)
- [ ] Testare `initialPointErmesCore()`, `getIOrcErmes()`
- [ ] Testare tutte le 8 funzioni di init signaling registry

### Interfacce non testate
- [ ] Testare `ISignalErmes`, `ISignalErmesRaw`, `IErmesSignalingServer`
- [ ] Testare `IErmesSignalingHandler`
- [ ] Testare `IErmesHandshake`, `IErmesHandshakeHandler`

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
| Test totali | 799 passanti, 1 fallito, 70 skippati |
| `@Deprecated` | 3 occorrenze |
| `UnimplementedError` in prod | 2 (factory `fromJson`, `generateFromSerialize`) |
| Security bug known | 1 (hash debole) |

*Generato dall'analisi del codice il 2026-05-10.*
