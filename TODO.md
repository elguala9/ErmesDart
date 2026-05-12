# ErmesDart - TODO List

> Generato il 2026-05-12

---
E -> significa che è da risolvere ma non in questo progetto
## Priorità 1 — CRITICO (blocca compilazione/esecuzione)

- [x] **Fix errore sintassi** `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:106` — già risolto (nessun errore presente)
- [x] **Implementare SHA-256** in `ermes_read_repo.dart` — già implementato via `hash_utils.dart` con `package:crypto`
- [x] **Completare metodi `UnimplementedError`**:
  - `ErmesSignalingHandler.clearConnection()`, `destroy()`, `onSocketReady()`, `waitForConnect()` — già implementati
  - `ErmesAsyncHandshake.handshake()` — già implementato
  - `ErmesConnection.saveState()` / `loadState()` — non richiesti dall'interfaccia `IErmesConnection`
  - `ErmesConnectionsHandler.saveState()` / `loadState()` — già implementati
  - Serializzazione in `ermes_read_repo.dart` / `ermes_send_repo.dart` — già implementata via `SerializationRegistry`
- [E] **Risolvere `pointycastle` version conflict** (bip39 richiede ^3.x, cryptdart richiede ^4.0.0) — fix con dependency_overrides è fragile 

## Priorità 2 — URGENTE

- [x] **Fix reconnect logic**: `_reconnectAttempts = 0` resettato subito dopo l'incremento, annulla il limite — auto-reset after successful reconnect in `ErmesConnection.connect()` and `ErmesSignalingReconnector.reconnect()`
- [x] **Rimuovere `print()` in produzione** in `ermes_read_repo.dart` — 3 `print()` rimossi
- [x] **Aggiungere validazione input** nel riassemblaggio chunk (bounds checking per `roof`) — validazione `roof > 0` e `index in [0, roof)` in `chunk_handler.dart`
- [x] **Sostituire eccezioni generiche** con gerarchia custom (`ErmesException`, `ErmesNetworkException`, etc.) — `Exception` → `SignalingException`, `StateError` → `CoreException`/`SignalingException`
- [x] **Implementare encryption at rest** per messaggi salvati in `work_db` — `AesStorageEncryptionService` + interfaccia `IStorageEncryptionService` + integrazione opzionale in `ErmesStorageRepository`

## Priorità 3 — TEST

- [x] **Aumentare copertura signaling** (~50%):
  - `ErmesAsyncHandshake` e `ErmesHandshakeHandler` — 11 test (285 righe)
  - `ErmesSignalingServer` signal flow — 8 test (onSignal callback, forceRefresh, caching, error/close)
  - `ErmesSignalingHandler` edge cases — 6 test (destroy lifecycle, createSignal con remotePeerId)
- [x] **Test per `ErmesSendRepo.sendAgain()`** — 2 test via `ermes_service_features_test.dart`
- [x] **Test per `ErmesService.sendNewKey()`** — 3 test via `ermes_service_features_test.dart`
- [x] **Test per listener management** — 12+ test su ErmesService, ErmesPeer, ErmesReadRepo
- [x] **Rendere multi-peer tests indipendenti** dal relay Nostr esterno (`wss://relay.damus.io`) — in-memory signaling di default; `useInMemorySignaling: true` in `MultiPeerTestFramework.createPeers()`
- [x] **Aggiornare conteggio test** in CLAUDE.md (dice 531, reali ~1379) — già aggiornato a 1421

## Priorità 4 — MANUTENZIONE

- [ ] **Rimuovere directory orfana** `id_handler/` a root (nessun file dart)
- [ ] **Aggiornare README.md** — mostra struttura vecchia con `apps/cli`
- [ ] **Aggiornare README di `iermes`** — riferimento a `ermes_types` inesistente
- [ ] **Gitignore**: aggiungere `test-results-v2.log`, `timing-hypothesis-results.txt`
- [ ] **Risolvere ~13 TODO comment** sparsi nel codice
- [ ] **Rinominare/rimuovere** `packages/iermes/lib/src/signaling_interface/i_ermes_TODO.dart`
- [ ] **Armonizzare CLAUDE.md** con `.github/copilot-instructions.md`

## Priorità 5 — PERFORMANCE

- [ ] **Sostituire ObservableList con Queue** per operazioni O(1) (`ermes_read_repo.dart`)
- [ ] **Configurare buffer limiti** (dimensione massima messaggio, backpressure)
- [ ] **Riutilizzare istanza Uuid** (creata ogni volta in `ErmesSendRepo`)
