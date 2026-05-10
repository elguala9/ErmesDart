# Coverage Report — ErmesDart

## Riassunto per package

| Package | Copertura | Stato |
|---|---|---|
| `iermes` | ~60% | Interfacce - molte classi dati/testo non testate |
| `ermes_cipher` | ~98% | Eccellente |
| `ermes_storage` | ~98% | Eccellente |
| `ermes_id_handler` | ~100% | Completa |
| `ermes_message_control` | ~95% | Solo `destroy()` non esplicitamente testato |
| `ermes_signaling` | ~50% | Divario significativo in handler e handshake |
| `ermes_core` | ~70% | Diverse lacune in factory, listener management |
| `ermes_core_init` | ~50% | Signaling/Core init non testati |
| `ermes_test` | N/A | Suite di test centralizzata - 531 test |
| `ermes_test_with_mock` | N/A | 5 file di test con mock |

---

## 1. `ermes_signaling` — Lacune principali

### Classi con ZERO test

| Classe | File | Descrizione |
|---|---|---|
| `ErmesAsyncHandshake` | `handshake/ermes_handshake.dart` | Intero handshake asincrono |
| `ErmesHandshakeHandler` | `handshake/ermes_handshake_handler.dart` | Gestore handshake |
| `ErmesSignalingFactory` | `factories/ermes_signaling_factory.dart` | Factory methods |
| `ErmesSignalingServerFactory` | `factories/ermes_signaling_server_factory.dart` | `createFromKeys()`, `createFromConfig()` |
| `ErmesBookFactories` | `factories/ermes_book_factories.dart` | Factory book |
| `_FallbackStunResponse` | `ermes_signaling_handler.dart` | Classe privata |

### `ErmesSignalingHandler` — 12/13 metodi NON testati

- `ErmesSignalingHandler()` costruttore semplice
- `setCustomStunServer()`
- `clearConnection()`
- `createSignal()` — chiamato indirettamente ma mai testato direttamente
- `onSocketReady()`
- `processSignal()` — flusso core, mai testato direttamente
- `handshake()` — mai testato
- `isSocketReady()`, `getSocket()`, `softClearConnection()`, `getAllPeerIds()`, `waitForConnect()`

### `ErmesSignalingServer` — 8/11 metodi NON testati

- `fromKeys()` (richiede relay Nostr reale)
- `fromConfig()`
- `getSignal()`, `setSignal()`, `onSignal()`
- `onError()`, `onClose()`, `removeAllListeners()`

### `ErmesSignalingService` — 2/7 metodi NON testati

- `getSignal()`, `sendSignal()`

### `ErmesSignalingRepository` — 4/9 metodi NON testati

- `sendSignal()`, `getSignal()`, `getSignalOwner()`, `compareSignalMessage()`

### `ErmesBookServiceBase` — 4/10 metodi NON testati

- `updateAccount()`, `getAccountList()`, `destroy()`, `getPeerInfo()`

### `ErmesBookRepository` — `getPeerInfo()` non testato

### `SignalErmes` — `secondsIntervalOpening`, `signal` getter non testati

### `SignalErmesRaw` — `getSignal()` non testato

---

## 2. `ermes_core` — Lacune principali

### Classi con ZERO test

| Classe | File | Descrizione |
|---|---|---|
| `ErmesFactory` | `factories/ermes_factory.dart` | Factory repository/service (non usata nei test) |
| `ErmesIdHandlerFactoryHelper` | `factories/ermes_id_handler_factory_helper.dart` | Helper factory statico |
| `OrcErmesAdvancedFactory` | `factories/orc_ermes_advanced_factory.dart` | Factory avanzata con STUN |
| `ShspSocketFactoryHelper` | `factories/shsp_socket_factory_helper.dart` | 6 metodi statici mai testati |
| `ShspSocketHandler` | `shsp_socket_handler_singleton.dart` | Gestore socket singleton |
| `ShspSocketHandlerSingleton` | `shsp_socket_handler_singleton.dart` | Singleton socket handler |

### `ErmesService` — listener management NON testato

- `removeOnDataSentListener()`, `clearOnDataSentListeners()`
- `addOnRemoteCloseListener()`, `removeOnRemoteCloseListener()`, `clearOnRemoteCloseListeners()`
- `sendNewKey()` — chiamato solo da `_checkKeyRotation()` (non testato)
- `sendAcknowledge()` — presente ma mai invocato nei test

### `ErmesPeer` — listener e key rotation NON testati

- `addOnMessageListener()`, `removeOnMessageListener()`, `clearOnMessageListeners()`
- `addOnDisconnectListener()`, `removeOnDisconnectListener()`
- `_startKeyRotationTimer()`, `_onMessageSent()`, `_checkKeyRotation()`

### `ErmesRepository` — metodi NON testati

- `removeOnMessageDataListener()`, `clearOnMessageDataListeners()`
- `isClosing()`, `isOpen()`

### `ErmesSendRepo` — listener e resend NON testati

- `sendMessageType()`, `sendAgain()`, `sendRootMessage()` (privati)
- Listener callbacks: add/remove/clear per `OnMessageSending` e `OnMessageSent`
- `callbackOnDataSending` getter/setter, `callbackOnDataSended` getter/setter

### `ErmesReadRepo` — listener NON testati

- `addServiceMessageListener()`, `removeServiceMessageListener()`
- `removeOnDataArrivedListener()`, `clearOnDataArrivedListeners()`
- `messageDataCallback` getter/setter

### `OrcErmes` — flusso completo non testato

- `openConnection()` testato solo per validazione input (hex format)
- `send()` testato solo per "peer not connected"
- `_handlePeerDisconnect()`, `_peerInfoFromSignal()` mai testati

---

## 3. `ermes_core_init` — Lacune principali

### Funzioni con ZERO test

| Funzione | File |
|---|---|
| `initialPointErmesCore()` | `initial_point_ermes_core.dart` |
| `getIOrcErmes()` | `initial_point_ermes_core.dart` |
| `initialPointErmesCoreRegistry({key})` | `initial_point_ermes_core_registry.dart` |
| `getIOrcErmesFromRegistry({key})` | `initial_point_ermes_core_registry.dart` |
| `initialPointErmesSignaling()` | `initial_point_ermes_signaling.dart` |
| `initialPointErmesSignalingPartial()` | `initial_point_ermes_signaling.dart` |
| Tutte le 8 funzioni | `initial_point_ermes_signaling_registry.dart` |

---

## 4. `iermes` (interfacce) — Lacune principali

### Interfacce interamente NON testate

| Interfaccia | File |
|---|---|
| `ISignalErmes`, `ISignalErmesRaw`, `IErmesSignalingServer` | `i_ermes_signaling_server.dart` |
| `IErmesSignalingHandler` | `i_ermes_signaling_handler.dart` |
| `_IErmesSignalingPrivate`, `IErmesSignalingRepository`, `IErmesSignalingService` | `i_ermes_signaling.dart` |
| `IErmesSignalingTODO` | `i_ermes_todo.dart` |
| `IErmesHandshake`, `IErmesHandshakeHandler` | `i_ermes_handshake.dart`, `i_ermes_handshake_handler.dart` |
| `IErmesIceRepository`, `_IErmesIcePrivate` | `i_ermes_ice_deprecated.dart` |

### Classi dati interamente NON testate

| Classe | File |
|---|---|
| `SignalData`, `Signal`, `_SignalData`, `_SignalString` | `types/signaling_types.dart` |
| `Response`, `OfferResponse`, `AnswerResponse` | `types/signaling_types.dart` |
| `ISignalInfo`, `SignalInfoOffer`, `SignalInfoAnswer`, `SignalInfo` | `types/signaling_types.dart` |
| `CallbackOnMessageReceived` | `types/ermes_types.dart` |
| `ErmesServiceInputGeneric` | `types/ermes_input.dart` |
| `OnSignalCreateSocketCallbackInput` | `types/ermes_callback.dart` |
| `MessageDataGeneric`, `ChunkMessageGeneric`, `ChunkInfo` | `types/ermes/messages.dart` |
| `SocketDto` | `types/callback_type_aliases.dart` |
| `GenericObjectManager` | `managers/generic_object_manager.dart` |
| `IPeerStorageInstance`, `IErmesStorageAndCachingMessagesHandlerBase` | `i_ermes_storage_and_caching_messages_handler.dart` |
| `PaginationDtoExtensions` | `types/pagination_types.dart` |

### Metodi su classi testate che NON hanno test diretto

- `MessageRoot`: `copyWith()`, `==`/`hashCode`/`toString`
- `MessageRootStorage`: `fromMessageRoot()`, `copyWith()`, `toMessageRoot()`, `==`/`hashCode`/`toString`
- `PaginationDto`: `copyWith()`, `==`/`hashCode`/`toString`
- `MessageData`: `copyWith()`, `==`/`hashCode`/`toString`
- `ChunkMessage`: `copyWith()`, `==`/`hashCode`/`toString`
- `InternalMessage`: `copyWith()`, `==`/`hashCode`/`toString`
- `MessageType`: `getId()`, `asData()`, `asChunk()`, `asService()`
- `ServiceMessageArrayRequest`: `copyWith()`
- `ServiceMessageNewKey`: `copyWith()`
- `ServiceReasons`: tutte le costanti statiche
- `IErmesPeerCipher`: `clearOldEncryptCipher()`, `clearOldDecryptCipher()`
- `IErmesService`: `startMissingMessagesCheck()`, `stopMissingMessagesCheck()`, listener management
- `IErmesConnectionsHandler`: `saveState()`, `loadState()`

---

## 5. Test placeholder/TODO nei test esistenti

| File | Linea | TODO |
|---|---|---|
| `ermes_test/test/src/multi_peer/multi_peer_scenarios.dart` | 14 | Scenari complessi: group chat, file transfer, disconnessione/riconnessione |
| `ermes_test/test/src/multi_peer/three_peer_tests.dart` | 14 | Topologie mesh e star |
| `ermes_test/test/src/multi_peer/n_peer_tests.dart` | 11 | Test con 5, 10, ecc. peer |
| `ermes_signaling/test/ermes_signaling_service_test.dart` | 163 | `getLastSignal()` |
| `ermes_core/lib/src/ermes_send_repo.dart` | 251 | Future: message tracking and confirmations |
| `ermes_id_handler/lib/src/handlers/id_handler_service.dart` | 26 | Gestione async dello storage update |

---

## 6. Priorità suggerite

### Alta priorità (core functionality non testata)

1. **`ErmesSignalingHandler`** — 12/13 metodi non testati (processSignal, handshake, createSignal sono il cuore del signaling)
2. **`ErmesSignalingServer`** — 8/11 metodi non testati (setSignal, getSignal, onSignal)
3. **Handshake layer** — `ErmesAsyncHandshake` + `ErmesHandshakeHandler`: zero test
4. **`ErmesSendRepo.sendAgain()`** — meccanismo di ritrasmissione mai testato
5. **`ErmesService.sendNewKey()`** — rotazione chiavi mai testata
6. **Scenari multi-peer** — group chat, topologie mesh/star, N peer (>3)

### Media priorità

7. **Listener management** su `ErmesService`, `ErmesPeer`, `ErmesSendRepo`, `ErmesReadRepo`
8. **`initialPointErmesSignaling()`** + `initialPointErmesCore()` — init mai testati
9. **`OrcErmes` flusso completo** — openConnection/send con peer reale
10. **`OrcErmesAdvancedFactory`** — factory avanzata con STUN

### Bassa priorità

11. **`copyWith()` / `==` / `hashCode` / `toString`** su classi dati
12. **`toString()`, `fromString()`, `toJson()`** su signaling types
13. **`PaginationDtoExtensions`** — utility extension

---

## 7. Cose che funzionano bene (completa copertura)

- `ermes_cipher`: 100% API pubblica testata
- `ermes_storage`: 100% API pubblica testata (10 file di test)
- `ermes_id_handler`: 100% API pubblica testata
- `ermes_message_control`: ~95% testato
- `SerializationRegistry`: completo
- `ChunkHandler`: completo
- `ObservableQueue`: completo
- `HashUtils`: completo
- `ErmesSignalingReconnector`: completo
- `ErmesBookRepository`: completo (tranne `getPeerInfo`)
