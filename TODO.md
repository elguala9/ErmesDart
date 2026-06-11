# ErmesDart - TODO

> Aggiornato: 2026-06-11
> Test suite status: **~1530 test**, tutti verdi. Il test star-topology un tempo
> flaky è stato stabilizzato (vedi Priorità 3) e verificato su 20+ run consecutivi.
> Unico item aperto: la verifica empirica NAT su due reti reali (richiede due
> macchine su reti diverse — non automatizzabile da una sola postazione).
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

Conteggi aggiornati al 2026-05-26. Tipi/interfacce ricchi sono accettabili; le implementazioni vanno spezzate. **Sezione esaurita (2026-06-11)**: tutte le implementazioni sono state spezzate sotto le 150 righe; i file rimanenti sono tipi/interfacce in `iermes`, eccezione accettata per decisione documentata (spezzare definizioni di tipi coese non porta beneficio e moltiplica i barrel/import):

- [x] `packages/iermes/lib/src/types/signaling_types.dart` — **481** righe (tipi — eccezione accettata)
- [x] `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart` — **122** righe ✅ (era 227 → estratto `ErmesSignalingConnectionMixin`)
- [x] `packages/ermes_core/lib/src/ermes_service.dart` — **138** righe ✅ (era 219 → estratti `ErmesServiceListeners` + `ErmesServiceSenders`)
- [x] `packages/ermes_core/lib/src/orc_ermes.dart` — **149** righe ✅ (era 240 → estratti `OrcErmesCallbacks` + `OrcErmesPassthrough`, dedup `guardCoreOp`)
- [x] `packages/ermes_cipher/lib/src/key_exchange/ecdh_key_exchange_service.dart` — **128** righe ✅ (era 218 → serializzazione spostata in `ecdh_serialization_helpers.dart`)
- [x] `packages/ermes_core/lib/src/ermes_read_repo.dart` — **138** righe ✅ (era 170 → estratti `ErmesReadRepoListeners` + `ermes_read_repo_options.dart`)
- [x] `packages/iermes/lib/src/types/ermes/messages.dart` — **320** righe (tipi — eccezione accettata)
- [x] `packages/iermes/lib/src/types/service/service_messages.dart` — **306** righe (tipi — eccezione accettata)
- [x] `packages/ermes_core/lib/src/ermes_peer.dart` — **120** righe ✅ (era 159 → estratto `ErmesPeerListeners`)
- [x] `packages/ermes_core/lib/src/ermes_send_repo.dart` — **114** righe ✅ (era 253)
- [x] `packages/ermes_signaling/lib/src/ermes_signaling_server.dart` — **146** righe ✅ (era 232)
- [x] `packages/iermes/lib/src/types/ermes/message_root.dart` — **224** righe (tipi — eccezione accettata)
- [x] `packages/ermes_storage/lib/src/ermes_storage_and_caching.dart` — **92** righe ✅ (era 179)
- [x] `packages/iermes/lib/src/standard_interface/i_ermes.dart` — **169** righe (interfaccia — eccezione accettata)

---

## 🟡 Priorità 3 — Test coverage

Suite globale verde (1467 passing) ma molti package non hanno test diretti — la copertura è centralizzata in `ermes_test`. Verificare che ciascuna area sia effettivamente testata:

- [x] **`ermes_core`**: Test aggiunti in `ermes_test`: `ermes_orc_test.dart`, `ermes_orc_full_flow_test.dart`, `ermes_service_impl_test.dart`, `ermes_service_features_test.dart`, `ermes_service_retransmission_test.dart`, `ermes_encryption_decryption_test.dart`, `ermes_utility_test.dart` — copertura completa.
- [x] **`ermes_storage`**: aggiunti 33 test (impl reali, no mock) in `ermes_test`: `storage_persistence_test.dart` (12 — persistenza cross-istanza, overwrite, delete, clear, isolamento), `storage_encryption_at_rest_test.dart` (11 — AES-256 round-trip, ciphertext non in chiaro, chiave errata, end-to-end via repository), `storage_corruption_recovery_test.dart` (10 — base64 invalido, ciphertext troncato, JSON malformato, recupero dopo corruzione). Wired nell'aggregatore.
- [x] **`ermes_signaling`**: `ermes_signaling_handler_test.dart` (391 righe) e `ermes_signaling_interfaces_test.dart` (746 righe) aggiunti — copertura handshake, STUN, reconnect, error paths.
- [x] **`ermes_message_control`**: `message_control_interface_test.dart` presente.
- [x] **`ermes_id_handler`** e **`ermes_core_init`**: `id_handler_test.dart` presente; `initial_point_ermes_usage_test.dart` presente.
- [x] **Test isolation**: isolamento OrcErmes risolto (commit "priority 3 solved" 2026-05-12) — 1467/1467 stabili.
- [x] **`ermes_test_with_mock`**: README aggiunto.
- [x] **Test flaky** `multi_peer_integration_test.dart` → "star topology": stabilizzato (2026-06-11) con retry deterministici — gli sleep fissi di 2s + expect one-shot sono stati sostituiti da `_connectionsSettledAt()` che polla `getConnections()` ogni 200ms fino a 15s e ritorna appena il conteggio atteso si assesta (più robusto E più veloce dei delay fissi). Verificato: 20 run consecutivi in isolamento + intero `multi_peer_integration_test.dart` (51 test) tutti verdi. Nota: il flake non era già più riproducibile prima del fix (probabile beneficio collaterale degli upgrade `stun_shsp`), ma la causa strutturale — dipendenza da timing fisso — è ora rimossa.
- [ ] **NAT test — verifica empirica su due reti reali** (residuo di `TODO_NAT_TEST_A_TWO_NATS.md`, ora cancellato: tutto il resto è implementato; il run CI Azure↔Azure è verde, vedi `packages/ermes_test_docker/NAT_TEST.md`). Eseguire i due peer su due reti domestiche/mobili diverse (es. PC casa + hotspot 4G) — via Docker Hub: `docker run --rm --network host <namespace>/ermes-nat-test a|b` — catturare gli stdout e annotare in `NAT_TEST.md` quali tipi di NAT passano (atteso: cone PASS, symmetric/CGNAT FAIL finché manca TURN).

---

## 🟢 Priorità 4 — Documentazione

### README mancanti per package

- [x] `packages/ermes_core/README.md`
- [x] `packages/ermes_core_init/README.md`
- [x] `packages/ermes_id_handler/README.md`
- [x] `packages/ermes_message_control/README.md`
- [x] `packages/ermes_test_with_mock/README.md`
- [x] `packages/id_handler/` non esiste più nel repo (solo `ermes_id_handler`) — voce obsoleta, nessuna azione richiesta.

### Documentazione API

- [x] Documentare l'algoritmo di chunking in `ErmesService` (dartdoc + `docs/flows/message_lifecycle.md`)
- [x] Documentare il flusso di message assembly in `ErmesReadRepo` (dartdoc + `docs/flows/message_lifecycle.md`)
- [x] Documentare la pipeline di frammentazione in `ErmesSendRepo` (dartdoc + `docs/flows/message_lifecycle.md`)
- [x] Documentare la sequenza di handshake signaling (dartdoc + `docs/flows/signaling_handshake.md`)
- [x] Diagram di flusso end-to-end: `docs/flows/` con diagrammi Mermaid (sequence) per message lifecycle e signaling handshake (`diagrams/` è gitignored, quindi sotto `docs/flows/`).

### Documenti da consolidare

- [x] Razionalizzati i file `.md` in root: spostati in `docs/` (`IMPROVEMENTS.md`, `CLOUD_TESTS_BLUEPRINT.md`, `MELOS_QUICK_START.md`, `TEST_RUNNING_GUIDE.md`, `TESTING_SUMMARY.md`, `COVERAGE.md`, `project_architecture.md`); rimossi i file generati tracciati (`coverage-report.md`, `timing-hypothesis-results.txt`); aggiunto `docs/README.md` come indice, linkato dal README.
- [x] `IMPROVEMENTS.md` archiviato in `docs/` con header che rimanda a `TODO.md` come backlog autorevole.

---

## 🔵 Priorità 5 — Architettura e qualità

- [x] **Gerarchia di eccezioni custom**: `ErmesException`, `ErmesNetworkException`, `ErmesSerializationException`, `ErmesStorageException`, `ErmesValidationException` in `packages/iermes/lib/src/exceptions/ermes_exception.dart` — usate nei package.
- [x] **Logging framework**: adottato `package:logging`. Aggiunto `packages/ermes_core/lib/src/logging/ermes_log.dart` (`ermesCoreLogger` + `ermesLoggerFor(name)`); la libreria emette solo record, l'app decide l'output via `Logger.root.onRecord` (documentato nel dartdoc). Migrato l'unico log di libreria (`developer.log` in `ermes_service_key_handler.dart`) a `_log.severe(...)`. I `print` in `ermes_test_docker` sono intenzionali (transport CI).
- [x] **Validazione input**: chunk index/roof/total-size già validati in `chunk_handler.dart`; estratto `ErmesIdValidator` (`packages/ermes_core/lib/src/validation/ermes_id_validator.dart`) che centralizza la validazione del formato public key (64 hex). Applicato in `OrcErmes.openConnection()` e `OrcErmes.send()` (sostituisce la regex inline) e coperto da `ermes_id_validator_test.dart` (11 test).
- [x] **Dipendenza circolare** `ermes_core` ↔ `ermes_core_init`: risolta. `ermes_read_repo`/`ermes_send_repo` importavano solo due getter DI da `ermes_core_init`; spostati in `ermes_core/lib/src/storage_singletons.dart` (risolvono via `SingletonDIAccess` con tipi da `ermes_storage`, già dipendenza). Rimossa la dipendenza `ermes_core_init` da `ermes_core/pubspec.yaml`; ora la dipendenza è unidirezionale (`ermes_core_init` → `ermes_core`).
- [x] **Storage crittografato a riposo**: `aes_storage_encryption_service.dart` implementato in `ermes_storage` con interfaccia `IErmesStorageEncryption` in `iermes`.
- [x] **Backoff esponenziale per reconnect** (`ermes_signaling_reconnector.dart`): implementato delay `baseDelay * 2^(attempt-1)` con cap `maxReconnectDelay` e funzione `delay` iniettabile per test veloci.
- [x] **ObservableList → Queue**: `ObservableQueue` già in uso in `ermes_read_repo.dart` (O(1) dequeue).
- [x] **Connection pooling**: `ErmesConnectionsHandler` (singleton) implementa `IErmesConnectionsHandler` con `addConnection`, `getConnection`, `hasConnection` — pool attivo.
- [x] **UUID singleton**: `const Uuid()` in Dart è canonicalizzato — oggetto condiviso a compile-time, nessuno spreco.

---

## ⚪ Priorità 6 — Pulizia minore

- [x] **File "TODO" nel nome**: `i_ermes_signaling_todo.dart` eliminato (commit "tod ok" 2026-05-13).
- [x] **`packages/id_handler/`** vs **`packages/ermes_id_handler/`**: `id_handler` non esiste più nel repo — nessun residuo legacy da rimuovere.
- [x] **`coverage/`** in repo: aggiunto a `.gitignore` (riga 10).
- [x] **`coverage-report.md`** in repo: rimosso dal tracking git (era ancora committato nonostante `.gitignore`).
- [x] **`timing-hypothesis-results.txt`** in root: rimosso dal tracking git e coperto da `.gitignore`.
- [x] **`test-results-v2.log`** in root: coperto da wildcard `test-results*.log` in `.gitignore` (riga 55).
- [x] **Verificare `analysis_options.yaml`**: `avoid_dynamic_calls` (riga 6) e `avoid_print` (riga 37) entrambe enforced ✅.
- [x] **Standardizzare struttura directory** dei package: convenzione standard ora documentata e autorevole in `CONTRIBUTING.md` (sezione "Package Structure"). Decisione: i package raggruppano i file per **dominio** (`*_implementation/`, `key_exchange/`, `handshake/`, `stun/`, `caching_implementation/`, `storage_encryption/`, `validation/`, `logging/`, `models/`) + cartelle convenzionali `factories/` e `generated/`, invece del generico `models/services/repositories/utils` (che era solo aspirazionale in CONTRIBUTING e non seguito da nessun package). Un reorg fisico massivo verso lo schema generico è stato volutamente scartato: alto churn su import/barrel/DI, rischio per la suite (1497 test verdi), e nessun beneficio funzionale — i raggruppamenti per dominio esistenti sono più significativi. Corretti anche i riferimenti obsoleti a `bootstrap.bat/.sh` → `melos bootstrap` e documentata la centralizzazione dei test in `ermes_test`.

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
