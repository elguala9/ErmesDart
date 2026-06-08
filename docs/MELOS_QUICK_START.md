# Melos Quick Start - Docker Peer Tests

## ⚡ TL;DR - 3 comandi

```bash
# 1. Installa melos (una sola volta)
dart pub global activate melos

# 2. Runnare TUTTI i test (unit + peer Docker)
melos run test:all

# 3. Leggi i risultati
cat test_results_summary.json
```

---

## 📊 Comandi Essenziali

### Runnare test peer Docker

```bash
# Opzione A: Run + risultati automatici
melos run test:peer:docker:full

# Opzione B: Solo run (no raccolta risultati)
melos run test:peer:docker

# Opzione C: Solo raccolta risultati
melos run test:peer:docker:results
```

### Pulizia

```bash
# Pulisci container
melos run test:peer:docker:clean

# Reset totale (rimuove immagini, volumi, etc)
melos run test:peer:docker:reset
```

### Monitoraggio

```bash
# Vedi log live
melos run test:peer:docker:logs

# Status container
melos run test:peer:docker:status
```

---

## 📄 Dove trovare i risultati

```
test_results/
├── alice_result.json       ← Risultato Alice
├── bob_result.json         ← Risultato Bob
├── charlie_result.json     ← Risultato Charlie
└── dave_result.json        ← Risultato Dave

test_results_summary.json    ← Summary di tutti (LEGGERE QUESTO!)
```

---

## ✅ Come verificare il successo

```bash
# Metodo 1: Leggere il summary
cat test_results_summary.json | jq '.summary'
# Output atteso: "all_passed": true

# Metodo 2: Verificare exit code
melos run test:all && echo "✅ ALL PASSED" || echo "❌ FAILED"

# Metodo 3: Contare i peer passati
jq '.summary.peers_passed' test_results_summary.json
# Output atteso: 4
```

---

## 🎯 Workflow di sviluppo

```bash
# 1. Prima volta
melos run test:peer:docker:reset

# 2. Edita config
vim packages/ermes_peer_node/config/test_config.json

# 3. Re-run (cache Docker layers = veloce)
melos run test:peer:docker:full

# 4. Leggi risultati
cat test_results_summary.json | jq '.summary'

# 5. Se modifichi il codice Dart:
melos run test:peer:docker:reset
melos run test:peer:docker:full
```

---

## 🚨 Se qualcosa non funziona

```bash
# 1. Vedi i log
melos run test:peer:docker:logs

# 2. Pulisci e ri-prova
melos run test:peer:docker:reset
melos run test:peer:docker:full

# 3. Controlla i risultati singoli
cat test_results/alice_result.json | jq '.verification_errors'
```

---

## 📚 Documentazione completa

Vedi **TEST_RUNNING_GUIDE.md** per:
- Spiegazione dettagliata di ogni comando
- Struttura dei file di risultati
- Workflow CI/CD
- Troubleshooting avanzato
