# Test Helpers

## GanacheManager

Utility per gestire automaticamente il ciclo di vita di Ganache durante i test.

### Utilizzo

#### Opzione 1: Nei test (Ganache auto-start nel test)

```dart
import 'helpers/ganache_manager.dart';

void main() {
  setUpAll(() async {
    // Avvia Ganache automaticamente se non è già in esecuzione
    final available = await GanacheManager.initialize();
    if (!available) {
      print('Ganache non disponibile - test skippati');
      return;
    }
    // Procedi con il setup
  });

  tearDownAll(() async {
    // Pulisce Ganache se l'abbiamo avviato noi
    await GanacheManager.cleanup();
  });

  test('Your test here', () async {
    // Test che richiede Ganache
  });
}
```

#### Opzione 2: Con dart test (Ganache manual)

```bash
# Avvia Ganache manualmente
docker compose -f docker-compose-evm.yml up -d

# Esegui i test (GanacheManager.initialize() verificherà se è disponibile)
dart test
```

#### Opzione 3: Con il test runner

```bash
# Avvia Ganache automaticamente e esegui i test
dart run tool/test_runner.dart
```

### Caratteristiche

- **Auto-detectable**: Verifica automaticamente se Ganache è già in esecuzione
- **Auto-start**: Se non disponibile e Docker è disponibile, lo avvia via docker-compose
- **Health check**: Usa curl per verificare che Ganache sia pronto
- **Auto-cleanup**: Pulisce automaticamente se lo abbiamo avviato noi
- **Timeout handling**: Attende fino a 30 secondi per l'avvio di Ganache
- **Graceful degradation**: Se Ganache non è disponibile, i test vengono skippati

### Metodi Pubblici

```dart
// Inizializa Ganache (avvia se necessario)
// Ritorna true se Ganache è disponibile
Future<bool> GanacheManager.initialize()

// Verifica se Ganache è disponibile
// (health check via curl)
Future<bool> GanacheManager.isAvailable()

// Pulisce (stoppa Ganache se l'abbiamo avviato)
Future<void> GanacheManager.cleanup()
```

### Costanti Configurabili

```dart
static const String ganacheRpcUrl = 'http://localhost:9545';
static const Duration healthCheckTimeout = Duration(seconds: 2);
static const Duration startupTimeout = Duration(seconds: 30);
static const int maxRetries = 30;
```

## Esempi

### Test ErmesSignalingServer

```dart
import 'helpers/ganache_manager.dart';

void main() {
  late SignalingContract contract;
  late ErmesSignalingServer server;

  setUpAll(() async {
    // Avvia Ganache automaticamente
    final available = await GanacheManager.initialize();
    if (!available) {
      print('⚠️  Ganache unavailable - SignalingServer tests will skip');
      return;
    }

    // Deploy contract
    final creds = EthPrivateKey.fromHex('0x...');
    contract = await SignalingContract.deploy(
      rpcUrl: GanacheManager.ganacheRpcUrl,
      credentials: creds,
    );

    server = ErmesSignalingServer(
      contract: contract,
      accountId: creds.address.toString(),
    );
  });

  tearDownAll(() async {
    // Cleanup Ganache se lo abbiamo avviato
    await GanacheManager.cleanup();
  });

  group('SignalingServer Tests', () {
    test('setSignal works', () async {
      // Test implementation
    });
  });
}
```

### Test OrcErmes

I test di OrcErmes usano già GanacheManager per auto-start di Ganache:

```bash
# Semplice: i test avviano Ganache automaticamente
dart test packages/ermes_test/test/concrete_implementations/orchestration/orc_ermes_test.dart
```
