# ErmesDart - Possibili Miglioramenti

> **ARCHIVED (2026-06-08)** — Historical analysis from 2026-02-01. Most items
> here have since been resolved; the live, authoritative backlog now lives in
> `TODO.md` at the repository root. Kept for reference only.

> Analisi completa del progetto con raccomandazioni per miglioramenti
> Data: 2026-02-01

---

## Indice

1. [Riepilogo Esecutivo](#riepilogo-esecutivo)
2. [Problemi Critici](#problemi-critici)
3. [Problemi di Sicurezza](#problemi-di-sicurezza)
4. [Qualita del Codice](#qualita-del-codice)
5. [Test e Documentazione](#test-e-documentazione)
6. [Performance](#performance)
7. [Architettura e Organizzazione](#architettura-e-organizzazione)
8. [Gestione Dipendenze](#gestione-dipendenze)
9. [Piano di Azione](#piano-di-azione)

---

## Riepilogo Esecutivo

| Categoria | Stato | Severita |
|-----------|-------|----------|
| **Architettura** | Ben strutturata, ma dipendenze circolari | Media |
| **Test** | Lacune critiche (types: 0 test) | Alta |
| **Documentazione** | Buona per interfacce, mancante per implementazioni | Media |
| **Qualita Codice** | Multipli TODO e stub | Alta |
| **Error Handling** | Eccezioni generiche, nessuna gerarchia | Media |
| **Performance** | ObservableList O(n^2), buffer illimitati | Media |
| **Sicurezza** | Hash debole, nessuna crittografia, input non validato | Critica |
| **Compilazione** | Errore sintassi blocca ermes_signaling | Critica |

---

## Problemi Critici

### 1. Errore di Sintassi - BLOCCA COMPILAZIONE

**File**: `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:106`

```dart
Future<void> handshake(ShspInstance instance,
  SocketReadyCallback<SocketDto<ShspPeer>> callback,
  ISignalErmes signal) async {
    instance.sendHandshake();
    if  // <-- INCOMPLETO: Manca condizione e corpo
  }
```

**Azione**: Completare immediatamente la logica del metodo `handshake()`.

---

### 2. Metodi Non Implementati (11 istanze)

I seguenti metodi lanciano `UnimplementedError()`:

| File | Metodo | Linea |
|------|--------|-------|
| `ermes_signaling_handler.dart` | `clearConnection()` | 30 |
| `ermes_signaling_handler.dart` | `destroy()` | 61 |
| `ermes_signaling_handler.dart` | `onSocketReady()` | 70 |
| `ermes_signaling_handler.dart` | `waitForConnect()` | 111 |
| `ermes_handshake.dart` | `handshake()` | vari |
| `ermes_connection.dart` | `saveState()` | - |
| `ermes_connection.dart` | `loadState()` | - |
| `ermes_connections_handler.dart` | `saveState()` | - |
| `ermes_connections_handler.dart` | `loadState()` | - |

**Azione**: Implementare tutti i metodi o, come soluzione temporanea, aggiungere logging e return appropriati.

---

### 3. Serializzazione Non Implementata

**File**: `ermes_read_repo.dart`, `ermes_send_repo.dart`

```dart
T uint8ArrayToObject<T>(Uint8List data) {
  throw UnimplementedError('serialization-utility not available');
}

Uint8List objectToUint8Array<T>(T obj) {
  throw UnimplementedError('serialization-utility not available');
}
```

**Azione**: Implementare la serializzazione usando `dart:convert` o libreria dedicata.

---

## Problemi di Sicurezza

### 1. Hash Debole - CRITICO

**File**: `packages/ermes_core/lib/src/ermes_read_repo.dart:44`

```dart
String calculateHashSync(Uint8List data) =>
    data.hashCode.toString(); // This should use SHA-256 in production
```

**Rischio**: `hashCode` di Dart non e crittograficamente sicuro. Permette collisioni intenzionali e potenziale manomissione messaggi.

**Soluzione**:
```dart
import 'package:crypto/crypto.dart';

String calculateHashSync(Uint8List data) {
  return sha256.convert(data).toString();
}
```

---

### 2. Storage Non Crittografato

I messaggi sono salvati in `work_db` senza crittografia.

**Azione**:
- Implementare crittografia a riposo per i messaggi
- Considerare l'uso di `flutter_secure_storage` o equivalente

---

### 3. Gestione Chiavi Pubbliche

```dart
publicKey: ''  // Campo vuoto
```

**Problemi**:
- Nessuna validazione delle chiavi
- Nessun protocollo di scambio chiavi visibile

**Azione**: Implementare validazione e scambio chiavi sicuro.

---

### 4. Nessuna Validazione Input

**Esempio**: Riassemblaggio chunk non valida il valore `roof`

```dart
// Potrebbe essere sfruttato per DoS (richiesta di riassemblare chunk infiniti)
```

**Azione**: Aggiungere validazione bounds per tutti gli input esterni.

---

## Qualita del Codice

### 1. TODO Comments (13 istanze)

| Posizione | Descrizione |
|-----------|-------------|
| `ermes_core/pubspec.yaml:17` | Versione UUID mismatch |
| `ermes_core/pubspec.yaml:27` | Package serialization-utility mancante |
| `ermes_core/pubspec.yaml:30` | Socket.io support non implementato |
| `ermes_read_repo.dart:10` | ObservableList equivalente |
| `ermes_read_repo.dart:41` | Hash functions (SHA-256) |
| `ermes_read_repo.dart:46` | Serialization functions |
| `ermes_send_repo.dart:10` | Serialization functions |
| `chunk_handler.dart:6` | Array composition |
| `ermes_connection.dart:30` | Repository reconnection logic |
| `ermes_signaling_handler.dart` | Multipli metodi (30, 61, 70, 111) |

**Azione**: Risolvere tutti i TODO o creare issue GitHub per tracciamento.

---

### 2. Print Statement in Produzione

**File**: `packages/ermes_core/lib/src/ermes_read_repo.dart:167`

```dart
print('Received empty or invalid message');
```

**Azione**: Sostituire con logging framework appropriato (es. `logging` package).

---

### 3. Gestione Errori Debole

**Problema**: Uso di eccezioni generiche ovunque.

```dart
throw Exception('Failed to initialize Ermes repository: $e');
```

**Soluzione**: Creare gerarchia di eccezioni custom:

```dart
abstract class ErmesException implements Exception {
  final String message;
  final Object? cause;
  ErmesException(this.message, [this.cause]);
}

class ErmesNetworkException extends ErmesException { ... }
class ErmesSerializationException extends ErmesException { ... }
class ErmesStorageException extends ErmesException { ... }
class ErmesValidationException extends ErmesException { ... }
```

---

### 4. Reconnect Logic Incompleta

**File**: `ermes_connection.dart`

```dart
if (_reconnectAttempts >= _maxReconnectAttempts) {
  throw Exception('Maximum reconnection attempts exceeded');
}
_reconnectAttempts++;
await _signalingHandler.clearConnection(_connectionId);
_reconnectAttempts = 0;  // Reset immediato - vanifica lo scopo
return _repository;  // Ritorna vecchio repository invariato
```

**Azione**: Implementare logica di reconnect completa con backoff esponenziale.

---

### 5. File con Nome TODO

**File**: `packages/iermes/lib/src/signaling_interface/i_ermes_TODO.dart`

**Azione**: Rinominare quando finalizzato o rimuovere se non necessario.

---

## Test e Documentazione

### Copertura Test

| Package | Test | Stato |
|---------|------|-------|
| `types` | 0 | CRITICO |
| `iermes` | Solo contratti | OK |
| `ermes_core` | Solo integration | INSUFFICIENTE |
| `ermes_signaling` | Nessuno (errore sintassi) | CRITICO |
| `ermes_storage` | Minimali | INSUFFICIENTE |
| `ermes_test` | 20+ test per id_handler | OK |

**Azioni**:
1. Aggiungere unit test per `ermes_types` (Freezed types, serialization)
2. Aggiungere unit test per `ermes_core` (ErmesService, chunking, message assembly)
3. Aumentare copertura `ermes_storage`
4. Implementare test per signaling dopo fix sintassi

---

### Documentazione Mancante

**README mancanti**:
- `packages/ermes_core/README.md`
- `packages/ermes_storage/README.md`

**API documentation mancante per**:
- Algoritmo chunking di `ErmesService`
- Strategia message assembly di `ErmesReadRepo`
- Logica frammentazione di `ErmesSendRepo`
- Processo handshake signaling

---

## Performance

### 1. ObservableList O(n^2)

**File**: `ermes_read_repo.dart`

```dart
// ObservableList.shift() usa removeAt(0) su List
// O(n) per ogni messaggio -> O(n^2) per buffer grandi
```

**Soluzione**: Usare `Queue` invece di `List`:

```dart
import 'dart:collection';

class ObservableQueue<T> {
  final Queue<T> _queue = Queue<T>();

  T removeFirst() => _queue.removeFirst(); // O(1)
}
```

---

### 2. Buffer Messaggi Illimitato

- Default buffer size: 100 messaggi
- Nessun limite configurato su dimensione messaggio

**Rischio**: Esaurimento memoria

**Azione**:
- Implementare limite massimo dimensione messaggio
- Aggiungere configurazione per buffer size
- Implementare backpressure

---

### 3. UUID Generation

```dart
// const Uuid() creato per ogni istanza ErmesSendRepo
```

**Azione**: Riutilizzare istanza Uuid o usare factory singleton.

---

### 4. Nessun Connection Pooling

Ogni connessione peer crea un nuovo `ShspInstance` completo.

**Azione**: Implementare pool di connessioni per peer contattati frequentemente.

---

## Architettura e Organizzazione

### 1. Dipendenze Circolari

```
ermes_core <--> ermes_signaling
```

**Problema**: Accoppiamento stretto, problemi di inizializzazione.

**Soluzione**:
- Estrarre interfacce comuni in `iermes`
- Applicare Dependency Inversion Principle
- Considerare event-based communication

---

### 2. Struttura Directory Inconsistente

Alcuni package usano `lib/src/implementation/`, altri struttura flat.

**Azione**: Standardizzare organizzazione:
```
lib/
  src/
    models/
    services/
    repositories/
    factories/
    utils/
```

---



## Gestione Dipendenze

### 1. Version Mismatch UUID

```yaml
# Commento menziona uuid: ^13.0.0
uuid: ^4.5.1  # Versione effettiva
```

**Azione**: Verificare quale versione e corretta e aggiornare.

---

### 2. Dipendenze Mancanti

| Tipo | Suggerimento |
|------|--------------|
| Logging | `logging` o `logger` |
| Error Reporting | `sentry_dart` |
| Crypto | `crypto` (per SHA-256) |
| Metrics | `prometheus_client` |

---

### 3. Dipendenze Custom Non Verificabili

- `work_db`
- `shsp_*` packages

**Rischio**: Single point of failure se non mantenuti.

**Azione**: Documentare fonte e stato manutenzione.

---

## Piano di Azione

### Priorita 1 - IMMEDIATO (Blocca sviluppo)

- [ ] Fix errore sintassi `ermes_signaling_handler.dart:106`
- [ ] Implementare hash SHA-256 invece di hashCode generico
- [ ] Completare 11 metodi non implementati

### Priorita 2 - URGENTE (1-2 settimane)

- [ ] Risolvere dipendenza circolare ermes_core <-> ermes_signaling
- [ ] Aggiungere test per ermes_types package
- [ ] Implementare gerarchia eccezioni custom
- [ ] Risolvere tutti i TODO o creare issue

### Priorita 3 - ALTA (2-4 settimane)

- [ ] Implementare serializzazione messaggi
- [ ] Aggiungere validazione input e bounds checking
- [ ] Implementare logging framework
- [ ] Completare documentazione API

### Priorita 4 - MEDIA (1-2 mesi)

- [ ] Ottimizzare ObservableList (usare Queue)
- [ ] Implementare saveState/loadState per persistenza
- [ ] Aggiungere crittografia storage
- [ ] Connection pooling

### Priorita 5 - BASSA (Ongoing)

- [ ] Standardizzare organizzazione codice
- [ ] Aumentare copertura test al 80%+
- [ ] Code review e refactoring continuo
- [ ] Monitoraggio e metriche

---

## Note Finali

Il progetto ha una **solida architettura di base** con:
- Buona separazione delle responsabilita
- Pattern interface-driven ben applicato
- Documentazione eccellente per le interfacce

Tuttavia, richiede **interventi critici** prima dell'uso in produzione:
1. Fix compilazione
2. Sicurezza (hash, crittografia)
3. Completamento implementazioni
4. Test coverage

Una volta risolti i problemi critici, il progetto avra una base solida per lo sviluppo futuro.
