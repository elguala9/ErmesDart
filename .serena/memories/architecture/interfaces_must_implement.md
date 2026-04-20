# Interfacce Critiche da Implementare

## 1. **IErmesRepository** (Core Messaging Layer)
**Location**: `packages/iermes/lib/src/standard_interface/i_ermes.dart`

**Responsabilità**: Trasmissione dati grezza verso peer

**Metodi obbligatori**:
- `void send(SerializableDataType data)` - Invia dati al peer
- `void addOnMessageDataListener()` / `removeOnMessageDataListener()` / `clearOnMessageDataListeners()` - Gestione listener
- `void destroy({bool force = false})` - Chiude connessione
- `IdAccountType get remotePeerId` - ID del peer remoto
- `bool isClosed()`, `bool isClosing()`, `bool isOpen()` (ereditato da IErmesPrivate)

**Implementazioni Note**:
- `ErmesRepository` (packages/ermes_core/lib/src/ermes_repository.dart)

---

## 2. **IErmesService** (High-Level Service Layer)
**Location**: `packages/iermes/lib/src/standard_interface/i_ermes.dart`

**Responsabilità**: Comunicazione a livello messaggio con chunking, reliability, key exchange

**Metodi obbligatori**:
- `Future<void> send(TypeOfDataExternal message)` - Invia messaggio
- `void sendNewKey({...})` - Scambia chiavi di crittografia
- `void sendAcknowledge()` - Invia acknowledge al peer
- `void startMissingMessagesCheck(int intervalMs)` - Timer periodico
- `void stopMissingMessagesCheck()` - Ferma timer
- `Future<void> checkAndRequestMissingMessages()` - Check basato su soglia
- Listener manager (onMessageData, onDataSending, onDataSent, onNewKey, onRemoteClose)
- `void close()` - Chiude connessione
- `void setRepository(IErmesRepository repository)` - Cambia repository
- Metodi da IErmesPrivate: `isClosed()`, `isClosing()`, `isOpen()`

**Implementazioni Note**:
- `ErmesService` (packages/ermes_core/lib/src/ermes_service.dart)

---

## 3. **IErmesPeer** (P2P Facade)
**Location**: `packages/iermes/lib/src/standard_interface/i_ermes_peer.dart`

**Responsabilità**: Interfaccia semplificata per messaggistica P2P con queue offline

**Metodi obbligatori**:
- `bool isConnected()` - Stato connessione
- `Future<void> dispose({bool flushBeforeClose = true})` - Cleanup
- `Future<void> send(TypeOfDataExternal data)` - Invia (queue se offline)
- Listener manager (onMessage, onDisconnect)
- `IdAccountType get remotePeerId` - ID del peer remoto

**Implementazioni Note**:
- `ErmesPeer` (packages/ermes_core/lib/src/ermes_peer.dart)

---

## 4. **IOrcErmes** (Orchestrator Multi-Peer)
**Location**: `packages/iermes/lib/src/standard_interface/i_orc_ermes.dart`

**Responsabilità**: Gestione di molteplici connessioni Ermes

**Metodi obbligatori**:
- `Future<void> send(TypeOfDataExternal data, IdPeer peer)` - Invia a peer specifico
- `Future<void> onMessage(CallbackOnDataArrivedFrom callback)` - Ricevi da qualsiasi peer
- `Future<void> openConnection(IdPeer peer)` - Apri connessione
- `Future<void> closeConnection(IdPeer peer)` - Chiudi connessione
- `Future<void> destroy({bool force = false})` - Destroy
- `Future<void> save()` - Salva stato
- `Future<List<IdPeer>> getConnections()` - Lista peer connessi
- `Future<void> onDisconnect(void Function(IdPeer peer) callback)` - Callback disconnect

**Implementazioni Note**:
- `OrcErmes` (packages/ermes_core/lib/src/orc_ermes.dart)

---

## 5. **IErmesSignalingHandler<SocketType>** (Peer Signaling)
**Location**: `packages/iermes/lib/src/signaling_interface/i_ermes_signaling_handler.dart`

**Responsabilità**: Gestione handshake e signaling tra peer

**Metodi obbligatori**:
- `Future<ISignalErmes> createSignal([IdAccountType? remotePeerId])` - Crea segnale
- `Future<void> processSignal(ISignalErmes signal, IdAccountType from, SocketReadyCallback<SocketType> callback)` - Elabora segnale
- `Future<void> onSocketReady(IdAccountType from, SocketReadyCallback<SocketType> callback)` - Callback socket ready
- `Future<SocketDto<SocketType>> getSocket(IdAccountType of)` - Ottieni socket
- `Future<bool> isSocketReady(IdAccountType of)` - Check socket ready
- `Future<void> clearConnection(IdAccountType remotePeerId)` - Clear soft
- `Future<void> softClearConnection(IdAccountType remotePeerId)` - Clear distruttivo
- `Future<List<IdAccountType>> getAllPeerIds()` - Lista tutti peer
- `Future<SocketDto<SocketType>> waitForConnect(IdAccountType peerId, int ms)` - Aspetta connessione
- `Future<void> destroy()` - Destroy

---

## 6. **IErmesStorageAndCaching<DataJson>** (Persistence)
**Location**: `packages/iermes/lib/src/storage_interface/i_ermes_storage_and_caching.dart`

**Responsabilità**: Storage e caching persistente

**Metodi obbligatori**:
- `Future<void> flush()` - Flush operazioni in sospeso
- Tutti i metodi da `IErmesStorageAndCachingReserved<DataJson>`:
  - Save/load messages
  - Caching operations
  - Batch operations

**Implementazioni Note**:
- Implementazioni di base in `packages/ermes_storage/`

---

## 7. **IIdHandlerRepository** & **IIdHandlerService** (ID Generation)
**Location**: `packages/iermes/lib/src/standard_interface/i_id_handler.dart`

**Responsabilità**: Generazione IDs univoci progressivi

**Metodi obbligatori**:
- `IdType getNewId()` - Nuovo ID incrementale
- `void setCounter(IdType counter)` - Setta counter
- `IdType getCurrent()` - ID corrente senza incremento
- `void reset()` - Reset counter

**Implementazioni Note**:
- `IdHandlerRepository`, `IdHandlerService` in ermes_core

---

## 8. **IErmesConnection** & **IErmesConnectionsHandler** (Connection Management)
**Location**: `packages/iermes/lib/src/standard_interface/i_ermes_connection*.dart`

**Responsabilità**: Ciclo vita connessioni singole e multiple

**Metodi obbligatori**:
- Connection state management (create, open, close, destroy)
- Socket management
- Peer identification

---

## 9. **IErmesMessageControl** (Message Retransmission)
**Location**: `packages/iermes/lib/src/standard_interface/i_ermes_message_control.dart`

**Responsabilità**: Tracciamento messaggi, richiesta di quelli mancanti

**Metodi obbligatori**:
- Tracking di IDs ricevuti/mancanti
- Identificazione gap
- Supporto per ritrasmissione

---

## Pattern Chiave da Seguire

### ✅ SEMPRE Implementare
1. **Tutti i metodi dell'interfaccia** - Nessuna eccezione
2. **Listener management** - add/remove/clear pattern per tutti i callback
3. **Lifecycle methods** - destroy/close con flush support
4. **Error handling** - Exceptions appropriate per errori, non silent fails
5. **Async where needed** - Future<T> per operazioni I/O

### ❌ NON Fare
1. **Non lasciare metodi con `throw UnimplementedError()`** - Implementa sempre
2. **Non aggiungere listener senza remove** - Sempre fornire remove/clear
3. **Non ignorare async/await** - Completa tutte le operazioni prima di ritornare
4. **Non rompere contratti** - Se interfaccia dice `Future<T>`, ritorna sempre `Future<T>`

### 🔧 Test Requirements
- **Per ogni interfaccia**: test coverage di tutti i metodi pubblici
- **No mocks**: usa implementazioni reali nei test
- **Isolation**: ogni test deve essere indipendente (singleton cleanup)
