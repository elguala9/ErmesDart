# Guide: Running Tests with Melos

Guida completa per eseguire i test del progetto ErmesDart usando Melos.

## 📋 Prerequisiti

1. **Dart SDK** installato
2. **Docker** e **Docker Compose** installati
3. **Melos** installato globalmente:

```bash
dart pub global activate melos
```

## 🚀 Comandi Principali

### 1. Runnare TUTTI i test (unit + Docker peer)

```bash
# Esegue unit test Dart + Docker peer test + raccoglie risultati
melos run test:all
```

**Output:**
- Log real-time dei test
- File `test_results_summary.json` con risultati dettagliati

---

### 2. Runnare solo i Docker Peer Tests

```bash
# Opzione A: Solo esecuzione (senza raccolta risultati)
melos run test:peer:docker

# Opzione B: Esecuzione + raccolta automatica dei risultati
melos run test:peer:docker:full

# Opzione C: Solo raccolta risultati (dopo un run precedente)
melos run test:peer:docker:results
```

---

### 3. Runnare solo Unit Tests Dart

```bash
# One-shot
melos run test:unit

# Modalità watch (auto-run al cambio file)
melos run test:unit:watch
```

---

### 4. Gestione dei Container Docker

```bash
# Visualizzare lo status dei container
melos run test:peer:docker:status

# Visualizzare i log in tempo reale
melos run test:peer:docker:logs

# Pulire i container e i volumi
melos run test:peer:docker:clean

# Reset completo (rimuove tutto, incl. immagini)
melos run test:peer:docker:reset
```

---

## 📊 File di Risultati

### Struttura

```
test_results/
├── alice_result.json       # Risultati di Alice
├── bob_result.json         # Risultati di Bob
├── charlie_result.json     # Risultati di Charlie
└── dave_result.json        # Risultati di Dave

test_results_summary.json    # Summary aggregato di tutti i risultati
```

### Esempio di `alice_result.json`

```json
{
  "peer_name": "Alice",
  "peer_address": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  "expected_messages": 9,
  "received_messages": 9,
  "missing_messages": [],
  "verification_errors": [],
  "success": true,
  "timestamp": "2026-04-08T21:36:45.123456Z"
}
```

### Esempio di `test_results_summary.json`

```json
{
  "timestamp": "2026-04-08T21:36:50Z",
  "total_peers": 4,
  "results": [
    { "peer_name": "Alice", ... },
    { "peer_name": "Bob", ... },
    { "peer_name": "Charlie", ... },
    { "peer_name": "Dave", ... }
  ],
  "summary": {
    "peers_passed": 4,
    "total_peers": 4,
    "success_rate": "4/4",
    "total_messages_expected": 36,
    "total_messages_received": 36,
    "all_passed": true
  }
}
```

---

## 🔄 Workflow Completo

### Scenario 1: Primo run (niente cache)

```bash
# 1. Pulisci tutto
melos run test:peer:docker:reset

# 2. Esegui test con raccolta risultati
melos run test:peer:docker:full

# 3. Visualizza risultati
cat test_results_summary.json | jq '.'
```

### Scenario 2: Develop iterativo

```bash
# 1. Prima volta: run completo
melos run test:all

# 2. Modifica config nel JSON:
vi packages/ermes_peer_node/config/test_config.json

# 3. Re-run senza clean (cache Docker layers)
melos run test:peer:docker:full

# 4. Check risultati
cat test_results_summary.json
```

### Scenario 3: CI/CD Pipeline

```bash
#!/bin/bash
set -e

echo "Running all tests..."
melos run test:all

# Exit code sarà 0 se tutti i test passano, 1 altrimenti
exit_code=$?

# Archivia risultati come artifact
if [ -f test_results_summary.json ]; then
    cp test_results_summary.json /path/to/artifacts/
fi

exit $exit_code
```

---

## 📝 Checklist: Leggere i Risultati

```
✅ Apri test_results_summary.json
✅ Controlla "all_passed": true
✅ Verifica "success_rate": "4/4"
✅ Leggi "total_messages_received": 36
✅ Se fallito, apri peer_result.json per dettagli
✅ Controlla "verification_errors" se presenti
```

---

## 🔍 Troubleshooting

### I risultati non vengono salvati

```bash
# Controlla che la directory esista
ls -la test_results/

# Se vuota, verifica il volume mount:
docker inspect ermes-test-peer-alice | grep -A10 Mounts
```

### "No peer test results found"

```bash
# I container potrebbero aver fallito prima di salvare i risultati
# Controlla i log:
melos run test:peer:docker:logs

# Poi ri-run:
melos run test:peer:docker:full
```

### Exit code errato

```bash
# Leggi il file summary:
cat test_results_summary.json | jq '.summary'

# Se "all_passed": false, un peer ha fallito
# Dettagli in: test_results/<peer>_result.json
```

---

## 🎯 Quick Reference

| Comando | Uso |
|---------|-----|
| `melos run test:all` | ✨ **RECOMMENDED**: Runnare tutto |
| `melos run test:peer:docker:full` | Docker peer test + risultati |
| `melos run test:unit` | Solo unit test Dart |
| `melos run test:unit:watch` | Unit test in modalità watch |
| `melos run test:peer:docker:results` | Raccogliere risultati da run precedente |
| `melos run test:peer:docker:logs` | Vedi log live |
| `melos run test:peer:docker:reset` | Pulisci tutto |

---

## 📚 File di Configurazione

- **melos.yaml** - Definizione di tutti gli script
- **test_results_summary.json** - Summary aggregato (auto-generato)
- **packages/ermes_peer_node/config/test_config.json** - Config messaggi/timing
Modifica `test_config.json` per customizzare il test senza rebuild Docker.

---

## 🎉 Success Criteria

Un test è **✅ PASS** se:

1. Tutti e 4 i peer hanno status `success: true`
2. Nessun `missing_messages` in alcun peer
3. Nessun `verification_errors` in alcun peer
4. `test_results_summary.json` ha `"all_passed": true`
