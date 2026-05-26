# ErmesDart - TODO

> Generated: 2026-05-22
> Test suite status: **1467/1467 passing** ✅
> Note: dependency / `pointycastle` version issue is tracked separately in `TODO_Version_issue.md`.

---

## 🔴 Priorità 1 — Correttezza / Standard di codice

### Violazioni delle regole di progetto

- [ ] **Rimuovere uso di `dynamic` e `as` cast** in `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:140-141`
  - `(stunResponse as dynamic).publicIp as String`
  - `(stunResponse as dynamic).publicPort as int`
  - Soluzione: tipo dedicato per la response STUN o sealed union, niente `dynamic`.

- [ ] **Rimuovere `print()` da codice di libreria** — `packages/ermes_core/lib/src/ermes_service.dart:286`
  - Attualmente sopprimo con `// ignore: avoid_print` ma viola la regola. Sostituire con un logger.

- [ ] **TODO residuo nel codice**: `packages/ermes_core/lib/src/ermes_send_repo.dart:251` — "In future implement message tracking and confirmations"
  - Verificare se è già coperto da `ermes_message_control` e rimuovere il TODO, altrimenti completare.

### Analyzer

- [ ] **`dart analyze`**: 1 warning + 38 info da pulire (most: `avoid_print` in runner docker — accettabile, ma valutare; alcuni `lines_longer_than_80_chars`, `cascade_invocations`, `use_late_for_private_fields`, `avoid_catching_errors` in `ermes_read_repo.dart:334`, `unused_field` in test 709).

---

## 🟠 Priorità 2 — File troppo grandi (regola: ≤150 righe escluse test)

Lista file lib oltre la soglia. Da valutare refactor (i tipi/interfacce ricchi sono spesso accettabili, ma le implementazioni vanno spezzate):

- [ ] `packages/iermes/lib/src/types/signaling_types.dart` — **481** righe
- [ ] `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart` — **465** righe (alta priorità: è anche logica)
- [ ] `packages/ermes_core/lib/src/ermes_service.dart` — **446** righe
- [ ] `packages/ermes_core/lib/src/orc_ermes.dart` — **406** righe
- [ ] `packages/ermes_cipher/lib/src/key_exchange/ecdh_key_exchange_service.dart` — **350** righe
- [ ] `packages/ermes_core/lib/src/ermes_read_repo.dart` — **338** righe
- [ ] `packages/iermes/lib/src/types/ermes/messages.dart` — **320** righe (probabilmente OK, tipi)
- [ ] `packages/iermes/lib/src/types/service/service_messages.dart` — **306** righe (probabilmente OK, tipi)
- [ ] `packages/ermes_core/lib/src/ermes_peer.dart` — **260** righe
- [ ] `packages/ermes_core/lib/src/ermes_send_repo.dart` — **253** righe
- [ ] `packages/ermes_signaling/lib/src/ermes_signaling_server.dart` — **232** righe
- [ ] `packages/iermes/lib/src/types/ermes/message_root.dart` — **224** righe
- [ ] `packages/ermes_storage/lib/src/ermes_storage_and_caching.dart` — **179** righe
- [ ] `packages/iermes/lib/src/standard_interface/i_ermes.dart` — **169** righe

---

## 🟡 Priorità 3 — Test coverage

Suite globale verde (1467 passing) ma molti package non hanno test diretti — la copertura è centralizzata in `ermes_test`. Verificare che ciascuna area sia effettivamente testata:

- [ ] **`ermes_core`**: nessun file di test sotto `packages/ermes_core/test/`. Coperto solo dall'aggregato `ermes_test`. Verificare che `ErmesService`, `ErmesReadRepo`, `ErmesSendRepo`, chunking/reassembly, `OrcErmes`, retransmission abbiano tutti gruppi di test dedicati nell'aggregato; aggiungere quelli mancanti.
- [ ] **`ermes_storage`**: solo i 10 file mossi in `ermes_test`. Aggiungere casi su persistenza, crittografia, corruption/recovery.
- [ ] **`ermes_signaling`**: estendere oltre i test su `ErmesSignalingServer`. Aggiungere copertura su `ErmesSignalingHandler` (handshake, STUN, reconnect, error paths).
- [ ] **`ermes_message_control`**: solo 3 file. Servono test su gap-detection, missing-id requests, periodic checks.
- [ ] **`ermes_id_handler`** e **`ermes_core_init`**: minimal. Aggiungere edge cases (collisioni, init multipla, registry isolation).
- [ ] **Test isolation**: gli 8 test OrcErmes che fallivano in aggregato (cfr. memoria 2026-04-20) sono ora verdi nell'esecuzione corrente — verificare se l'isolamento è stato risolto definitivamente o se è "flaky".
- [ ] **`ermes_test_with_mock`**: nessun README, valutare se è ancora usato.

---

## 🟢 Priorità 4 — Documentazione

### README mancanti per package

- [ ] `packages/ermes_core/README.md`
- [ ] `packages/ermes_core_init/README.md`
- [ ] `packages/ermes_id_handler/README.md`
- [ ] `packages/ermes_message_control/README.md`
- [ ] `packages/ermes_test_with_mock/README.md`
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

- [ ] **Gerarchia di eccezioni custom**: attualmente si usano `Exception` generiche. Introdurre `ErmesException`, `ErmesNetworkException`, `ErmesSerializationException`, `ErmesStorageException`, `ErmesValidationException` come richiesto dal CLAUDE.md di progetto.
- [ ] **Logging framework**: scegliere `logging` (Dart standard) e sostituire ogni `print` e ogni `// TODO log` residuo.
- [ ] **Validazione input**: bounds checking su tutti i punti di ingresso esterni (chunk index, message size, peer id format già presente per ETH ma da estendere).
- [ ] **Dipendenza circolare** `ermes_core` ↔ `ermes_signaling`: verificare se è davvero presente nel grafo attuale (è citata in `IMPROVEMENTS.md`); se sì, estrarre interfacce in `iermes`.
- [ ] **Storage crittografato a riposo**: i messaggi salvati in storage non sono cifrati. Valutare uso di `ermes_cipher` anche per persistenza.
- [ ] **Backoff esponenziale per reconnect** (`ermes_connection.dart`): la logica di reconnect attuale (cfr. `IMPROVEMENTS.md`) resetta `_reconnectAttempts` subito. Verificare e implementare backoff serio.
- [ ] **ObservableList → Queue**: in `ermes_read_repo.dart`, `removeAt(0)` su `List` è O(n). Migrare a `dart:collection` `Queue` per O(1).
- [ ] **Connection pooling** per peer contattati frequentemente.
- [ ] **UUID singleton**: `const Uuid()` riusato invece di crearne uno per ogni `ErmesSendRepo`.

---

## ⚪ Priorità 6 — Pulizia minore

- [ ] **File "TODO" nel nome**: verificare se `packages/iermes/lib/src/signaling_interface/i_ermes_TODO.dart` esiste ancora (segnalato in IMPROVEMENTS.md, da rinominare o rimuovere).
- [ ] **`packages/id_handler/`** vs **`packages/ermes_id_handler/`**: due package separati con nome simile — chiarire ruolo o consolidare.
- [ ] **`coverage/` e `coverage-report.md`** in repo: aggiungere a `.gitignore` (sono artefatti).
- [ ] **`test-results-v2.log`, `timing-hypothesis-results.txt`** in root: rimuovere o spostare in `.local/`.
- [ ] **Verificare `analysis_options.yaml`**: confermare che le regole `avoid_dynamic_calls`, `avoid_print` siano enforced.
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
