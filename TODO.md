# ErmesDart - TODO List

> Generato il 2026-05-13

---
E -> significa che è da risolvere ma non in questo progetto

## Priorità 1 — CRITICO (blocca compilazione/esecuzione)

- [E] **Risolvere `pointycastle` version conflict** (bip39 richiede ^3.x, cryptdart richiede ^4.0.0) — fix con dependency_overrides è fragile

## Priorità 2 — ORC ERMES: COPERTURA API

Completare `IOrcErmes` per coprire tutti i metodi delle dipendenze, così da non dover mai chiamare una dipendenza direttamente.

### Fatto — Book Service (`IErmesBookService<BookData>`)
- [x] `setAccount`, `updateAccount`, `getAccount`, `getAccountList`, `deleteAccount`, `clear`, `numberOfElements`, `listOfIds`, `getPeerInfo`

### Fatto — Signaling Server (`IErmesSignalingServer`)
- [x] **`getIdAccount()`** — sapere il proprio identity
- [x] **`isSignalingConnected()`** — verificare connettività signaling
- [x] **`onSignalingError()`** — osservare errori signaling
- [x] **`onSignalingClose()`** — notifica disconnessione signaling
- [x] **`bookService.destroy()` in `OrcErmes.destroy()`** — fix resource leak
