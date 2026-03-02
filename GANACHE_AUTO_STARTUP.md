# Auto-Ganache Startup per OrcErmes Tests

## TL;DR - Uso Semplice

```bash
cd packages/ermes_test
dart test
# ✅ Ganache avvia automaticamente
# ✅ Test eseguono (inclusi OrcErmes con signaling reale)
# ✅ Ganache stoppa automaticamente
```

**Tutto completamente automatico.** Niente da configurare, niente da fare manualmente.

## Come funziona

1. **`dart test` esegue i test**
2. **`setUpAll()` chiama `GanacheManager.initialize()`**
3. GanacheManager:
   - ✅ Verifica se Ganache è già running
   - ✅ Se no, verifica se Docker è disponibile
   - ✅ Se sì, avvia `docker-compose up -d`
   - ✅ Aspetta che Ganache sia ready (health check)
4. **Test eseguono** (inclusi i 19 test di OrcErmes)
5. **`tearDownAll()` chiama `GanacheManager.cleanup()`**
6. GanacheManager:
   - ✅ Stoppa Ganache se l'abbiamo avviato noi
   - ✅ Lascia running se era già presente

## Prerequisiti

- ✅ Docker Desktop (per Windows) oppure Docker (per Linux/Mac)
- ✅ Dart SDK
- ✅ `docker-compose-evm.yml` nella root del progetto ✅ (già presente)

## Scenari

### Scenario 1: Ganache non è mai stato avviato

```bash
cd packages/ermes_test
dart test

# Output:
# ❌ Ganache not available at http://localhost:9545
# 🚀 Attempting to start Ganache via docker-compose...
# ⏳ Waiting for Ganache to be ready...
# ✅ Ganache started successfully
#
# (test eseguono qui)
#
# 🛑 Stopping Ganache...
# ✅ Ganache stopped
#
# All tests passed!
```

### Scenario 2: Ganache è già running

```bash
cd packages/ermes_test
dart test

# Output:
# ✅ Ganache is already running at http://localhost:9545
#
# (test eseguono qui - nessun stop finale)
#
# All tests passed!
```

### Scenario 3: Docker non è disponibile

```bash
cd packages/ermes_test
dart test

# Output:
# ❌ Ganache not available at http://localhost:9545
# ⚠️  Docker is not available - Ganache tests will be skipped
#
# (test non-Ganache eseguono, 17 test OrcErmes skippati gracefully)
#
# All tests passed! (with 17 skipped)
```

## Test Coverage

### Test eseguiti:
- ✅ **128 test** core (cipher, encryption, storage, retransmission)
- ✅ **19 test OrcErmes** (quando Ganache è disponibile)
  - Connection Management (4)
  - Message Exchange (5)
  - Lifecycle (3)
  - Bidirectional Communication (2)
  - Error Handling (3)

### Risultati attesi:
```
✅ All 147 tests passed!
    (128 core + 19 OrcErmes)
```

## Componenti

### 1. GanacheManager (`packages/ermes_test/test/src/helpers/ganache_manager.dart`)
```dart
// Inizializa Ganache (avvia se necessario)
final available = await GanacheManager.initialize();

// Cleanup (stoppa se l'abbiamo avviato)
await GanacheManager.cleanup();
```

### 2. OrcErmes Tests (`packages/ermes_test/test/src/concrete_implementations/orchestration/orc_ermes_test.dart`)
- 19 test integration con real SignalingContract
- No mocks - solo implementazioni reali
- Usa GanacheManager automaticamente

### 3. Docker Compose (`docker-compose-evm.yml`)
```yaml
services:
  ganache:
    image: trufflesuite/ganache:latest
    ports:
      - "9545:8545"
    # ... configurazione completa
```

## Uso Avanzato

### Eseguire solo i test OrcErmes

```bash
cd packages/ermes_test
dart test -n "OrcErmes"
```

### Eseguire con verbose output

```bash
cd packages/ermes_test
dart test --chain-stack-traces
```

### Eseguire test skippati (forza esecuzione anche senza Ganache)

```bash
cd packages/ermes_test
dart test --run-skipped
# (Fallirà se Ganache non disponibile, ma mostra il tentativo)
```

### Usare test runner esterno (alternativa)

```bash
dart run tool/test_runner.dart
# Stesso risultato ma con output più dettagliato
```

## Troubleshooting

### "Docker is not available"
**Soluzione**: Installa Docker Desktop
- [Windows](https://docs.docker.com/desktop/install/windows-install/)
- [Mac](https://docs.docker.com/desktop/install/mac-install/)
- [Linux](https://docs.docker.com/engine/install/)

### "Timeout waiting for Ganache"
**Soluzione**: Aumenta il timeout nel GanacheManager oppure:
```bash
# Avvia manualmente Ganache per diagnosticare:
docker-compose -f docker-compose-evm.yml logs ganache
```

### "port 9545 already in use"
**Soluzione**: Una vecchia istanza di Ganache è ancora in esecuzione
```bash
# Stoppa tutti i container:
docker-compose -f docker-compose-evm.yml down

# Oppure uccidi il container specifico:
docker kill parresia-contract-ganache
```

### "Cannot find docker-compose-evm.yml"
**Soluzione**: Assicurati di eseguire da root del progetto:
```bash
cd /path/to/ErmesDart
dart test packages/ermes_test/test/concrete_implementations_test.dart
```

## Configurazione Personalizzata

### Cambia la porta di Ganache

Nel `docker-compose-evm.yml`:
```yaml
ports:
  - "9545:8545"  # Cambia il primo numero
```

Nel GanacheManager:
```dart
static const String ganacheRpcUrl = 'http://localhost:9545';  // Cambia qui
```

### Cambia il timeout di startup

Nel GanacheManager:
```dart
static const Duration startupTimeout = Duration(seconds: 30);  // Cambia qui
static const int maxRetries = 30;  // Cambia qui
```

## Verifica che tutto funziona

```bash
# 1. Verifica Docker
docker ps

# 2. Verifica docker-compose
docker-compose --version

# 3. Esegui i test
cd packages/ermes_test
dart test
```

## Risultato finale

Quando esegui:
```bash
dart test
```

Otterrai automaticamente:
1. ✅ Ganache avviato (se necessario)
2. ✅ 128 test core passati
3. ✅ 19 test OrcErmes eseguiti (con real Ganache)
4. ✅ Ganache stoppato (se l'abbiamo avviato)
5. ✅ Tutto pulito e pronto

**Zero configurazione. Zero comandi manuali.**
