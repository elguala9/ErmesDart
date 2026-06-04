# ErmesDart - TODO

> Aggiornato: 2026-05-26
> Test suite status: **1467/1467 passing** ✅
> Note: dependency / `pointycastle` version issue is tracked separately in `TODO_Version_issue.md`.

---

## 🔴 Priorità 1 — Correttezza / Standard di codice

### Violazioni delle regole di progetto

- [x] **Rimuovere uso di `dynamic` e `as` cast** in `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:140-141`
  - `(stunResponse as dynamic).publicIp as String`
  - `(stunResponse as dynamic).publicPort as int`
  - Soluzione: tipo dedicato per la response STUN o sealed union, niente `dynamic`.

- [x] **Rimuovere `print()` da codice di libreria** — `packages/ermes_core/lib/src/ermes_service.dart:286`
  - Attualmente sopprimo con `// ignore: avoid_print` ma viola la regola. Sostituire con un logger.

- [x] **TODO residuo nel codice**: `packages/ermes_core/lib/src/ermes_send_repo.dart:251` — "In future implement message tracking and confirmations"
  - Verificare se è già coperto da `ermes_message_control` e rimuovere il TODO, altrimenti completare.

### Analyzer

- [x] **`dart analyze`**: No issues found ✅ (pulito in commit "fixed code" 2026-05-26).

---

## 🟠 Priorità 2 — File troppo grandi (regola: ≤150 righe escluse test)

Conteggi aggiornati al 2026-05-26. Tipi/interfacce ricchi sono accettabili; le implementazioni vanno spezzate:

- [ ] `packages/iermes/lib/src/types/signaling_types.dart` — **481** righe (tipi — accettabile)
- [ ] `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart` — **227** righe ↓ (era 465)
- [ ] `packages/ermes_core/lib/src/ermes_service.dart` — **219** righe ↓ (era 446)
- [ ] `packages/ermes_core/lib/src/orc_ermes.dart` — **240** righe ↓ (era 406)
- [ ] `packages/ermes_cipher/lib/src/key_exchange/ecdh_key_exchange_service.dart` — **218** righe ↓ (era 350)
- [ ] `packages/ermes_core/lib/src/ermes_read_repo.dart` — **170** righe ↓ (era 338)
- [ ] `packages/iermes/lib/src/types/ermes/messages.dart` — **320** righe (tipi — accettabile)
- [ ] `packages/iermes/lib/src/types/service/service_messages.dart` — **306** righe (tipi — accettabile)
- [ ] `packages/ermes_core/lib/src/ermes_peer.dart` — **159** righe ↓ (era 260)
- [x] `packages/ermes_core/lib/src/ermes_send_repo.dart` — **114** righe ✅ (era 253)
- [x] `packages/ermes_signaling/lib/src/ermes_signaling_server.dart` — **146** righe ✅ (era 232)
- [ ] `packages/iermes/lib/src/types/ermes/message_root.dart` — **224** righe (tipi — accettabile)
- [x] `packages/ermes_storage/lib/src/ermes_storage_and_caching.dart` — **92** righe ✅ (era 179)
- [ ] `packages/iermes/lib/src/standard_interface/i_ermes.dart` — **169** righe (interfaccia — accettabile)

---

## 🟡 Priorità 3 — Test coverage

Suite globale verde (1467 passing) ma molti package non hanno test diretti — la copertura è centralizzata in `ermes_test`. Verificare che ciascuna area sia effettivamente testata:

- [x] **`ermes_core`**: Test aggiunti in `ermes_test`: `ermes_orc_test.dart`, `ermes_orc_full_flow_test.dart`, `ermes_service_impl_test.dart`, `ermes_service_features_test.dart`, `ermes_service_retransmission_test.dart`, `ermes_encryption_decryption_test.dart`, `ermes_utility_test.dart` — copertura completa.
- [ ] **`ermes_storage`**: solo i 10 file mossi in `ermes_test`. Aggiungere casi su persistenza, crittografia, corruption/recovery.
- [x] **`ermes_signaling`**: `ermes_signaling_handler_test.dart` (391 righe) e `ermes_signaling_interfaces_test.dart` (746 righe) aggiunti — copertura handshake, STUN, reconnect, error paths.
- [x] **`ermes_message_control`**: `message_control_interface_test.dart` presente.
- [x] **`ermes_id_handler`** e **`ermes_core_init`**: `id_handler_test.dart` presente; `initial_point_ermes_usage_test.dart` presente.
- [x] **Test isolation**: isolamento OrcErmes risolto (commit "priority 3 solved" 2026-05-12) — 1467/1467 stabili.
- [x] **`ermes_test_with_mock`**: README aggiunto.

---

## 🟢 Priorità 4 — Documentazione

### README mancanti per package

- [x] `packages/ermes_core/README.md`
- [x] `packages/ermes_core_init/README.md`
- [x] `packages/ermes_id_handler/README.md`
- [x] `packages/ermes_message_control/README.md`
- [x] `packages/ermes_test_with_mock/README.md`
- [ ] `packages/id_handler/README.md` (verificare se il package è ancora in uso o eliminabile — duplicato di `ermes_id_handler`?)

### Documentazione API

- [ ] Documentare l'algoritmo di chunking in `ErmesService`
- [ ] Documentare il flusso di message assembly in `ErmesReadRepo`
- [ ] Documentare la pipeline di frammentazione in `ErmesSendRepo`
- [ ] Documentare la sequenza di handshake signaling
- [ ] Diagram di flusso end-to-end (eventualmente sotto `diagrams/`)

### Documenti da consolidare

- [ ] Razionalizzare i molti file `.md` in root (`IMPROVEMENTS.md`, `CLOUD_TESTS_BLUEPRINT.md`, `MELOS_QUICK_START.md`, `TEST_RUNNING_GUIDE.md`, `TESTING_SUMMARY.md`, `COVERAGE.md`, `coverage-report.md`, `project_architecture.md`, `test-results-v2.log`, `timing-hypothesis-results.txt`). Eliminare i log/file generati dal repo, spostare il resto in `docs/` o linkarli da `README.md`.
- [ ] `IMPROVEMENTS.md` è datato 2026-02-01 — la maggior parte è ormai risolta. Aggiornare o archiviare.

---

## 🔵 Priorità 5 — Architettura e qualità

- [x] **Gerarchia di eccezioni custom**: `ErmesException`, `ErmesNetworkException`, `ErmesSerializationException`, `ErmesStorageException`, `ErmesValidationException` in `packages/iermes/lib/src/exceptions/ermes_exception.dart` — usate nei package.
- [ ] **Logging framework**: `dart analyze` è pulito (nessun `print` rimasto), ma nessun framework `logging` adottato formalmente. Da valutare se adottare `package:logging`.
- [ ] **Validazione input**: `ErmesValidationException` usata in `chunk_handler.dart` e `maxByte` validato in `ermes_service.dart`. Manca bounds checking sistematico su tutti i punti di ingresso (chunk index, peer id format oltre ETH).
- [ ] **Dipendenza circolare** `ermes_core` ↔ `ermes_core_init`: `ermes_core/pubspec.yaml` dipende da `ermes_core_init` (riga 35) e viceversa — circolarità reale. La dipendenza `ermes_core` ↔ `ermes_signaling` invece NON è circolare (`ermes_signaling` dipende solo da `iermes`).
- [x] **Storage crittografato a riposo**: `aes_storage_encryption_service.dart` implementato in `ermes_storage` con interfaccia `IErmesStorageEncryption` in `iermes`.
- [ ] **Backoff esponenziale per reconnect** (`ermes_signaling_reconnector.dart`): `_reconnectAttempts` conta tentativi ma nessun delay/backoff — reconnect immediato. Implementare delay esponenziale.
- [x] **ObservableList → Queue**: `ObservableQueue` già in uso in `ermes_read_repo.dart` (O(1) dequeue).
- [x] **Connection pooling**: `ErmesConnectionsHandler` (singleton) implementa `IErmesConnectionsHandler` con `addConnection`, `getConnection`, `hasConnection` — pool attivo.
- [x] **UUID singleton**: `const Uuid()` in Dart è canonicalizzato — oggetto condiviso a compile-time, nessuno spreco.

---

## ⚪ Priorità 6 — Pulizia minore

- [x] **File "TODO" nel nome**: `i_ermes_signaling_todo.dart` eliminato (commit "tod ok" 2026-05-13).
- [ ] **`packages/id_handler/`** vs **`packages/ermes_id_handler/`**: `id_handler` NON è nel workspace `pubspec.yaml` (solo `ermes_id_handler` lo è) — verificare se è ancora usato o eliminabile come residuo legacy.
- [x] **`coverage/`** in repo: aggiunto a `.gitignore` (riga 10).
- [x] **`coverage-report.md`** in repo: aggiunto a `.gitignore`.
- [x] **`timing-hypothesis-results.txt`** in root: aggiunto a `.gitignore` (riga 40).
- [x] **`test-results-v2.log`** in root: coperto da wildcard `test-results*.log` in `.gitignore` (riga 55).
- [x] **Verificare `analysis_options.yaml`**: `avoid_dynamic_calls` (riga 6) e `avoid_print` (riga 37) entrambe enforced ✅.
- [ ] **Standardizzare struttura directory** dei package (`lib/src/{models,services,repositories,factories,utils}`) — al momento la struttura è incoerente tra package.

---

## ✅ Risolti dalle scorse review

Per riferimento (no action items, solo memoria di cosa è già fatto rispetto a `IMPROVEMENTS.md`):

- ✅ Errore di sintassi in `ermes_signaling_handler.dart:106`
- ✅ 11 metodi `UnimplementedError` (handshake, clearConnection, destroy, onSocketReady, ecc.)
- ✅ Serializzazione `uint8ArrayToObject` / `objectToUint8Array`
- ✅ ECDH key exchange e validazione chiavi
- ✅ Async storage refactor di `ErmesService.send()` / `ErmesSendRepo.send()`
- ✅ `stun_shsp ^0.2.1` upgrade
- ✅ `ShspSocketHandlerSingleton` integrato con `StunHandlerSingleton`
- ✅ `ErmesSignalingServer` v2.0.0 con `getSignalCompressed` / `setSignalCompressed`
- ✅ Test centralizzati in `ermes_test`
- ✅ Suite globale verde: 1467/1467 ✅
