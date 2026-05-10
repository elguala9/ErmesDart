# ErmesDart — TODO List

## Stato Progetto
- **Test passanti**: 1374 ✅ (1355 always-run + 19 con relay Nostr raggiungibile)
- **Test falliti**: 0 ✅ (se relay Nostr disponibile)
- **Coverage**: ermes_cipher/storage/id_handler/message_control ~95-100%, ermes_core ~70%, ermes_signaling ~50%

---

## 🔴 Critici / Bloccanti

### 5 test multi-peer dipendenti da relay Nostr esterno
- 5 test in `packages/ermes_test/test/src/multi_peer/` usano `wss://relay.damus.io`
- Falliscono se relay non raggiungibile (CI senza relay)
- 4 test usano `createPeers()` + `connectPeers()` → creano connessioni WebSocket reali
- 1 test (`multi_peer_scenarios.dart:105`) verifica `nostrSignaling.isConnected()`

### 1 test flaky — buffer SHSP saturo
- `disconnect_reconnect_tests.dart:169` — `star topology: center connects 3 peers, disconnect 2, reconnect`
- `ShspNetworkException: Failed to send message - socket buffer may be full`
- Intermittente, non riproducibile in isolamento
- Stessa causa del fix in `TestErmesRepository`

---

## 🟢 Bassa Priorità

- [ ] **Risolvere conflitto `pointycastle`**: mantenuto `dependency_overrides` (bip39 1.0.6 non aggiornato da 5 anni)

---

## Note

| Metadato | Valore |
|----------|--------|
| Packages | 12 |
| Test totali | 1374 passanti, 0 falliti (con relay), 1 flaky |
| `@Deprecated` | 0 occorrenze |
| `Exception('...')` in lib/ | 0 occorrenze |
| `CoreException` / `SignalingException` / `MessageControlException` | 22 throw |
| `CipherException` e sottoclassi | 11 throw |
| `UnimplementedError` in prod | 2 (factory `fromJson`, `generateFromSerialize`) |
| Security bug known | 1 (hash debole) |

*Generato dall'analisi del codice il 2026-05-11.*
