# Guida Locale: work_db e shsp

Questa guida spiega come usare i pacchetti `work_db` e `shsp` nel progetto ErmesDart basato su esempi reali dal codice.

---

## 📦 work_db - Database In-Memory

### Cos'è?

`work_db` è un database in-memoria leggero per Dart, usato nel progetto per l'archiviazione persistente di messaggi. Fornisce operazioni CRUD atomiche con suddivisione per collection.

### Installazione

```yaml
# pubspec.yaml
dependencies:
  work_db: ^1.0.0
```

### API Principale

```dart
// Interfaccia principale di work_db
interface IWorkDb {
  // Crea o aggiorna un item
  Future<void> createOrUpdate(ItemWithId item);

  // Recupera un item per ID e collection
  Future<ItemWithId?> retrieve(ItemId id);

  // Elimina un item
  Future<bool> delete(ItemId id);

  // Pulisce una collection
  Future<void> clearCollection(String collection);

  // Pulisce l'intero database
  Future<void> clearDatabase();

  // Elenca tutti gli ID di una collection
  Future<List<String>> listIds(String collection);
}
```

### Utilizzo in ErmesStorageRepository

Nel progetto, `work_db` è usato in [ermes_storage_repository.dart](../packages/ermes_storage/lib/src/storage_implementation/ermes_storage_repository.dart) per salvare i messaggi:

```dart
class ErmesStorageRepository<DataJson extends MessageType>
    extends IErmesStorageRepository<DataJson> {
  
  final IWorkDb _db;
  final String _collection;

  // Salvare un messaggio
  @override
  Future<void> store(DataJson data) async {
    final id = _extractId(data);  // Estrai ID dal messaggio
    final serialized = _toMap(data);  // Serializza a Map

    // Crea o aggiorna con work_db
    await _db.createOrUpdate(
      ItemWithId(
        id: id.toString(),
        collection: _collection,  // Raggruppamento logico
        item: serialized,
      ),
    );
  }

  // Recuperare un messaggio
  @override
  Future<DataJson?> retrieve(IdType id) async {
    final result = await _db.retrieve(
      ItemId(id: id.toString(), collection: _collection),
    );

    if (result != null) {
      // Deserializza da Map a MessageType
      return MessageType.fromJson(result.item as Map) as DataJson;
    }
    return null;
  }

  // Eliminare un messaggio
  @override
  Future<bool> delete(IdType id) async {
    return await _db.delete(
      ItemId(id: id.toString(), collection: _collection),
    );
  }

  // Svuotare l'intera collection
  @override
  Future<void> clear() async {
    await _db.clearCollection(_collection);
  }

  // Elenca tutti gli ID
  @override
  Future<List<IdType>> listOfIds() async {
    final ids = await _db.listIds(_collection);
    return ids.map(int.parse).toList();  // Converti a IdType (int)
  }
}
```

### Esempio di Test

Nel progetto vediamo come work_db è inizializzato nei test:

```dart
import 'package:work_db/work_db.dart';

void main() async {
  // Crea un database in-memoria usando il nuovo Factory Pattern
  final factory = WorkDbFactory();
  final db = factory.create(MemoryWorkDbFactoryInput());

  testStorageRepository<MessageType>(
    'ErmesStorageRepository',
    () => ErmesStorageRepository<MessageType>(db, 'test_messages'),
  );
}
```

### Struttura dei Dati

- **ItemWithId**: Contenitore per salvare dati
  ```dart
  ItemWithId(
    id: '123',
    collection: 'messages',
    item: {'msg': 'data'},
  )
  ```

- **ItemId**: Identificatore per recuperare/eliminare
  ```dart
  ItemId(
    id: '123',
    collection: 'messages',
  )
  ```

---

## 🔌 shsp - Secure Handshake Signaling Protocol

### Cos'è?

`shsp` è un protocollo per la comunicazione P2P sicura e il setup della connessione WebRTC. Include:
- **shsp_interfaces**: Definisce le interfacce
- **shsp_implementations**: Implementazioni concrete
- **shsp_types**: Type definitions

### Pacchetti nel Progetto

```yaml
# pubspec.yaml (ermes_core)
dependencies:
  shsp_interfaces: ^1.0.0
  shsp_implementations: ^1.0.1
  shsp_types: ^1.0.1
```

### Componenti Principali

#### 1. **IShspPeer** - Rappresentazione di un peer

```dart
abstract class IShspPeer {
  String get id;
  IShspContract get contract;
  Future<void> sendMessage(Uint8List data);
  void onMessage(Function(Uint8List) callback);
}
```

Usato in [ErmesRepository](../packages/ermes_core/lib/src/ermes_repository.dart):

```dart
class ErmesRepository extends ShspInstance implements IErmesRepository {
  final IShspPeer remotePeer;
  final IShspSocket socket;

  void send(SerializableDataType data) {
    // Usa ShspPeer per inviare
    sendMessage(data);  // Ereditato da ShspInstance
  }
}
```

#### 2. **IShspSocket** - Connessione WebSocket

```dart
abstract class IShspSocket {
  String get url;
  Future<void> connect();
  Future<void> disconnect();
  void send(Uint8List data);
  void onData(Function(Uint8List) callback);
}
```

Passato a ErmesRepository per la comunicazione sottostante:

```dart
ErmesRepository(
  remotePeer: ShspPeer(...),
  socket: ShspWebSocket(url: 'ws://localhost:8080'),
  remotePeerId: IdAccountType('peer-123'),
  signalHandler: mySignalHandler,
)
```

#### 3. **IShspContract** - Configurazione della comunicazione

```dart
class IShspContract {
  final String version;
  final int maxPayloadSize;
  final int timeout;
}
```

Esempio di utilizzo nei test:

```dart
final contract = IShspContract(
  version: '1.0.0',
  maxPayloadSize: 65536,  // 64KB
);
final peer = ShspPeer(
  id: 'local-peer',
  contract: contract,
);
```

#### 4. **IErmesSignalingHandler** - Gestione del segnaling

```dart
abstract class IErmesSignalingHandler<SocketType> {
  Future<Signal> createSignal();
  Future<String> createSignalString();
  SignalData parseSignalString(String signal);
  void setSignal(Signal signal);
  void setSignalString(String signalString);
}
```

Usato per scambio di segnali SDP/ICE tra peer:

```dart
class MySignalHandler implements IErmesSignalingHandler<IShspPeer> {
  @override
  Future<Signal> createSignal() async {
    // Crea un'offerta WebRTC (SDP)
    return Signal(
      type: 'offer',
      sdp: await generateSdpOffer(),
    );
  }

  @override
  void setSignal(Signal signal) {
    // Riceve risposta dal peer remoto
    _localPeer.setRemoteDescription(signal.sdp);
  }
}
```

### Flusso di Connessione

```
1. Creazione Peer:
   ShspPeer(id: 'peer1', contract: contract)

2. Creazione Socket:
   ShspWebSocket(url: 'ws://server:8080')

3. Handshake Signaling:
   - peer1 chiama signalHandler.createSignal() → SDP Offer
   - Server invia offer a peer2
   - peer2 riceve e chiama signalHandler.setSignal(offer)
   - peer2 genera risposta → SDP Answer
   - Server invia answer a peer1
   - peer1 riceve e chiama signalHandler.setSignal(answer)

4. Connessione Stabilita:
   - Entrambi i peer possono inviare/ricevere dati via WebRTC
   - socket.send(data) invia dati
   - onData(callback) riceve dati
```

### Utilizzo in ErmesDart

In [ErmesRepository](../packages/ermes_core/lib/src/ermes_repository.dart):

```dart
class ErmesRepository extends ShspInstance implements IErmesRepository {
  ErmesRepository({
    required super.remotePeer,      // IShspPeer
    required super.socket,           // IShspSocket
    required this.remotePeerId,
    required this.signalHandler,    // IErmesSignalingHandler
    this.timeoutMs = 30000,
  });

  @override
  void send(SerializableDataType data) {
    if (_closed || !_connected) {
      throw StateError('Connection not available');
    }
    
    _onDataSendingCallback?.call(data);
    sendMessage(data);  // Usa ShspPeer
    _onDataSentCallback?.call(data);
  }

  @override
  Future<void> waitForConnect([int? timeoutMs]) async {
    // Attende che ShspPeer sia pronto
    // Implementa retry con timeout
  }

  @override
  void destroy({bool force = false}) {
    _closed = true;
    close();  // Chiude ShspPeer connection
  }
}
```

---

## 🔗 Interazione work_db + shsp

Nel sistema Ermes completo:

```
┌─────────────────────────────────┐
│     Applicazione User           │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  IErmesService (Business Logic) │
│  - Chunking                     │
│  - Compressione                 │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ IErmesRepository (Transport)    │
│ - send/receive via WebRTC       │
│ - Extend ShspInstance           │
│  Uses: IShspPeer, IShspSocket   │
└────────────┬────────────────────┘
             │
             ▼
    ┌─────────────────┐
    │  shsp Protocol  │
    │  (WebRTC)       │
    └────────┬────────┘
             │
             ▼ (Peer Remoto)
    ┌─────────────────┐
    │  Remote Peer    │
    └────────┬────────┘
             │
             ▼
┌─────────────────────────────────┐
│ IErmesStorageAndCaching         │
│ - Caching (in-memory)           │
│ - Storage (work_db)             │
└─────────────────────────────────┘
```

### Esempio Completo

```dart
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:work_db/work_db.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

void main() async {
  // 1. Inizializza database (work_db)
  final factory = WorkDbFactory();
  final db = factory.create(MemoryWorkDbFactoryInput());

  // 2. Configura storage e caching
  final storageRepo = ErmesStorageRepository<MessageType>(
    db,
    'messages',
  );
  
  final cachingRepo = ErmesCachingRepository<MessageType>(100);
  
  final storageAndCaching = ErmesStorageAndCaching(
    storageRepo,
    cachingRepo,
    maxNumberOfElementCached: 100,
    cachingMode: CachingMode.fifo,
  );

  // 3. Configura comunicazione (shsp)
  final contract = IShspContract(
    version: '1.0.0',
    maxPayloadSize: 65536,
  );
  
  final localPeer = ShspPeer(
    id: 'my-peer',
    contract: contract,
  );
  
  final socket = ShspWebSocket(
    url: 'ws://server:8080',
  );

  // 4. Crea repository Ermes
  final repo = ErmesRepository(
    remotePeer: localPeer,
    socket: socket,
    remotePeerId: IdAccountType('remote-peer'),
    signalHandler: MySignalHandler(),
  );

  // 5. Crea service Ermes
  final idHandler = IdHandlerService(
    IdHandlerRepository(),
  );

  final service = ErmesService(
    repository: repo,
    idHandler: idHandler,
    ermesStorageAndCaching: storageAndCaching,
  );

  // 6. Usa il service
  service.onMessage((msg) {
    print('Messaggio ricevuto: $msg');
  });

  // Invia dati
  await service.send(myData);

  // Recupera dal storage
  final stored = await storageRepo.retrieve(messageId);
  
  // Cleanup
  await service.close();
}

class MySignalHandler implements IErmesSignalingHandler<IShspPeer> {
  @override
  Future<Signal> createSignal() async {
    return Signal(type: 'offer', sdp: 'mock-sdp');
  }

  // ... implementare altri metodi ...
}
```

---

## 🧪 Esempi di Test Concreti

### Test di work_db

```dart
// test/storage_test.dart
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_types/ermes_types.dart';

void main() {
  group('ErmesStorageRepository con work_db', () {
    late IWorkDb db;
    late ErmesStorageRepository<MessageType> storage;

    setUp(() {
      final factory = WorkDbFactory();
      db = factory.create(MemoryWorkDbFactoryInput());
      storage = ErmesStorageRepository(db, 'test_collection');
    });

    test('salvare e recuperare un messaggio', () async {
      // Crea un messaggio di test
      final message = MessageType.data(
        message: ErmesMessage(
          id: 1,
          version: 1,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          data: Uint8List.fromList([1, 2, 3]),
        ),
      );

      // Salva
      await storage.store(message);
      expect(storage.numberOfElements(), equals(1));

      // Recupera
      final retrieved = await storage.retrieve(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.when(
        data: (msg) => msg.id,
        chunk: (msg) => msg.id,
        service: (msg) => msg.id,
      ), equals(1));
    });

    test('eliminare un messaggio', () async {
      final message = MessageType.data(
        message: ErmesMessage(
          id: 2,
          version: 1,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          data: Uint8List.fromList([4, 5, 6]),
        ),
      );

      await storage.store(message);
      expect(storage.numberOfElements(), equals(1));

      final deleted = await storage.delete(2);
      expect(deleted, isTrue);
      expect(storage.numberOfElements(), equals(0));
    });

    test('listare tutti gli ID', () async {
      // Salva 3 messaggi
      for (int i = 1; i <= 3; i++) {
        final message = MessageType.data(
          message: ErmesMessage(
            id: i,
            version: 1,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            data: Uint8List.fromList([i]),
          ),
        );
        await storage.store(message);
      }

      final ids = await storage.listOfIds();
      expect(ids.length, equals(3));
      expect(ids.contains(1), isTrue);
      expect(ids.contains(2), isTrue);
      expect(ids.contains(3), isTrue);
    });
  });
}
```

### Test di shsp

```dart
// test/shsp_test.dart
import 'package:test/test.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

// Use shsp_implementations factory to create concrete implementations
// import 'package:shsp_implementations/shsp_implementations.dart';

void main() {
  group('ErmesRepository con shsp', () {
    late ShspPeer localPeer;
    late IShspContract contract;

    setUp(() {
      contract = IShspContract(
        version: '1.0.0',
        maxPayloadSize: 65536,
      );

      // Use the shsp_implementations factory to create concrete peers/sockets
      // final factory = ShspImplementationsFactory();
      // localPeer = factory.createPeer(ShspPeerInput(id: 'test-peer', contract: contract));
      // For tests you can also mock or provide a lightweight implementation.
    });

    test('peer deve avere ID', () {
      expect(localPeer.id, equals('test-peer'));
    });

    test('contract deve avere configurazione', () {
      expect(contract.version, equals('1.0.0'));
      expect(contract.maxPayloadSize, equals(65536));
    });

    test('repository deve implementare IErmesRepository', () {
      expect(localPeer, isNotNull);
      // Verificare che implementa l'interfaccia
    });
  });
}
```

---

## 🔍 Debugging e Troubleshooting

### work_db

**Problema**: "Collection not found"
```dart
// work_db è case-sensitive per collection names
final repo = ErmesStorageRepository(db, 'messages');
// ✅ Corretta sintassi
// ❌ Sbagliata: 'Messages' (maiuscoletto)
```

**Problema**: "Item already exists"
```dart
// work_db.createOrUpdate() sostituisce automaticamente
await db.createOrUpdate(ItemWithId(
  id: '123',
  collection: 'msgs',
  item: newData,
));
// Se '123' esiste, viene sovrascritto (OK)
```

### shsp

**Problema**: "IShspSocket connection timeout"
```dart
final socket = ShspWebSocket(url: 'ws://localhost:8080');
// Verifica che:
// 1. URL è corretto
// 2. Server è in ascolto
// 3. CORS è configurato (se cross-origin)
```

**Problema**: "Signal parsing failed"
```dart
// Verifica che parseSignalString() riceva formato JSON valido
final handler = MySignalHandler();
final signal = await handler.createSignal();
// signal deve essere serializzabile a JSON
```

---

## 📚 Risorse Aggiuntive

- [ermes_storage/README.md](../packages/ermes_storage/README.md) - Dettagli storage
- [ermes_core/src/ermes_repository.dart](../packages/ermes_core/lib/src/ermes_repository.dart) - Utilizzo shsp
- [ermes_test/test/suite/](../packages/ermes_test/test/suite/) - Esempi di test
- [work_db Pub.dev](https://pub.dev/packages/work_db) - Documentazione work_db
- [WebRTC Protocol](https://webrtc.org/getting-started/overview) - Background su shsp/WebRTC

---

## ✅ Checklist di Integrazione

Quando integri work_db e shsp nel tuo progetto:

- [ ] Aggiungi dipendenze a `pubspec.yaml`
- [ ] Inizializza WorkDB (memoria o persistente)
- [ ] Configura IShspContract con settings appropriati
- [ ] Crea ShspPeer con ID univoco
- [ ] Implementa IErmesSignalingHandler per il tuo caso d'uso
- [ ] Testa connessione con unit test
- [ ] Configura error handling e retry logic
- [ ] Monitora performance e memory usage

---

**Nota**: Questa guida è generata dal codice attuale del progetto ErmesDart (gennaio 2026).
I link ai file sono relativi alla directory radice del workspace.
