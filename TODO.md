# ErmesDart — TODO List

## Stato Progetto
- **Test passanti**: 1379 ✅ (1360 always-run + 19 con relay Nostr raggiungibile)
- **Test falliti**: 0 ✅ (0 flaky)
- **Coverage**: ermes_cipher/storage/id_handler/message_control ~95-100%, ermes_core ~70%, ermes_signaling ~50%

---

## 🔴 Critici / Bloccanti

### ~37 test multi-peer dipendenti da relay Nostr esterno
- Tutti i test in `packages/ermes_test/test/src/multi_peer/` che chiamano `createPeers()` (default: `wss://relay.damus.io`) aprono WebSocket reali — sono circa 37 test
- Falliscono se relay non raggiungibile (CI senza relay, firewall, DNS)
- 1 test (`multi_peer_scenarios.dart:105`) verifica esplicitamente `nostrSignaling.isConnected()`
- **Non è un problema di produzione**: relay configurabile, segnalazione solo per discovery P2P
- **Soluzione già dimostrata**: `_MemSig` in `disconnect_reconnect_tests.dart` — stesso pattern applicabile a `MultiPeerTestFramework`

---

## 🟢 Bassa Priorità

- [ ] **Risolvere conflitto `pointycastle`**: mantenuto `dependency_overrides` (bip39 1.0.6 non aggiornato da 5 anni)

---

## Note

| Metadato | Valore |
|----------|--------|
| Packages | 12 |
| Test totali | 1379 passanti, 0 falliti (con relay), 0 flaky ✅ |
| `@Deprecated` | 0 occorrenze |
| `Exception('...')` in lib/ | 0 occorrenze |
| `CoreException` / `SignalingException` / `MessageControlException` | 22 throw |
| `CipherException` e sottoclassi | 11 throw |
| `UnimplementedError` in prod | 2 (factory `fromJson`, `generateFromSerialize`) |
| Security bug known | 1 (hash debole) |

*Generato dall'analisi del codice il 2026-05-11.*
