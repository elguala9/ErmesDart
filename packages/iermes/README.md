# IErmes - Ermes Interfaces

Interfaces and abstract classes for implementing the Ermes messaging system.

## Overview

This package provides all the interface definitions needed to implement the Ermes protocol. It defines contracts for:

- **Standard Interfaces**: Core messaging, connections, and ID handling
- **Signaling Interfaces**: WebRTC signaling and peer discovery
- **Storage Interfaces**: Message persistence and caching
- **Input Types**: Configuration objects for various components

## Features

### Standard Interfaces

#### Core Messaging (`i_ermes.dart`)
- `IErmesRepository`: Low-level data transmission over WebRTC
- `IErmesService`: High-level message handling with chunking and reliability
- `IErmesPrivate`: Common connection lifecycle methods

#### Connection Management
- `IErmesConnection`: Single peer connection management
- `IErmesConnectionsHandler`: Multi-peer connection orchestration
- `IOrcErmes`: High-level orchestrator for managing multiple peers

#### ID Management
- `IIdHandler`: Unique ID generation for messages
- `IIdHandlerFactory`: Factory for creating ID handlers
- `IIdHandlerStorage`: Persistent storage for ID counters

#### Message Control
- `IErmesMessageControl`: Track message delivery and request retransmissions
- Detect missing messages and manage reliability

#### WebRTC Integration
- `IErmesIce`: WebRTC ICE (Interactive Connectivity Establishment) operations
- `IErmesFactory`: Factory for creating Ermes instances

### Signaling Interfaces

#### Core Signaling
- `IErmesSignaling`: Send and receive WebRTC signaling data
- `IErmesSignalingServer`: Interface to a signaling server
- `IErmesSignalingHandler`: Manage WebRTC peer connections

#### Account Management
- `IErmesBook`: Directory of peers/accounts with metadata
- Pagination support for large peer lists

#### Factory
- `IErmesSignalingFactory`: Create signaling instances

### Storage Interfaces

#### Message Storage
- `IErmesStorage`: Persistent message storage (disk/database)
- `IErmesCaching`: Temporary message caching (memory)
- `IErmesStorageAndCaching`: Combined interface with flush support

### Input Types

#### Configuration Objects
- `ErmesServiceInput`: Configure Ermes service instances
- `IdHandlerInput`: Configure ID handlers
- `ErmesWebrtcRepositoryInput`: Configure WebRTC settings

## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  iermes:
    path: ../iermes
  ermes_types:
    path: ../types
```

## Usage

### Implementing a Repository

```dart
import 'package:iermes/iermes.dart';
import 'package:ermes_types/ermes_types.dart';

class MyErmesRepository implements IErmesRepository {
  bool _closed = false;
  bool _connected = false;
  CallbackOnDataRepository? _onMessageCallback;

  @override
  bool isClosed() => _closed;

  @override
  bool isConnected() => _connected;

  @override
  Future<void> waitForConnect([int? timeoutMs]) async {
    // Wait for connection to establish
    // Implement timeout logic if needed
  }

  @override
  Future<void> waitForClose([int? timeoutMs]) async {
    // Wait for connection to close
  }

  @override
  void send(SerializableDataType data) {
    if (_closed) throw StateError('Connection closed');
    // Send data over WebRTC
  }

  @override
  void onMessage(CallbackOnDataRepository callback) {
    _onMessageCallback = callback;
  }

  @override
  void destroy(bool force) {
    _closed = true;
    // Clean up resources
  }
}
```

### Implementing a Service

```dart
class MyErmesService implements IErmesService {
  final IErmesRepository _repository;
  CallbackOnDataArrived? _onDataArrivedCallback;

  MyErmesService(this._repository);

  @override
  bool isClosed() => _repository.isClosed();

  @override
  bool isConnected() => _repository.isConnected();

  @override
  Future<void> waitForConnect([int? timeoutMs]) =>
      _repository.waitForConnect(timeoutMs);

  @override
  Future<void> waitForClose([int? timeoutMs]) =>
      _repository.waitForClose(timeoutMs);

  @override
  void onMessage(CallbackOnDataArrived callback) {
    _onDataArrivedCallback = callback;
  }

  @override
  void onDataSending(CallbackOnDataSending callback) {
    // Register callback for data sending events
  }

  @override
  void onDataSent(CallbackOnDataSent callback) {
    // Register callback for data sent events
  }

  @override
  void send(TypeOfDataExternal message) {
    // Process message (chunking, encoding, etc.)
    // Then send via repository
    _repository.send(message);
  }

  @override
  void close() {
    _repository.destroy(false);
  }

  @override
  void setRepository(IErmesRepository repository) {
    // Switch to new repository while preserving state
  }
}
```

### Using a Factory

```dart
class MyErmesFactory implements IErmesFactory<MyPeerType> {
  @override
  Future<IErmesRepository> createRepository(
    IdAccountType remotePeerId,
    IErmesSignalingHandler<MyPeerType> ermesSignalingHandler,
  ) async {
    // Create and configure repository
    final repo = MyErmesRepository();
    
    // Set up WebRTC connection via signaling
    final socket = await ermesSignalingHandler.waitForConnect(
      remotePeerId,
      30000, // 30 second timeout
    );
    
    // Configure repository with socket
    repo.setSocket(socket.socket);
    
    return repo;
  }

  @override
  IErmesService createService(IErmesRepository ermesRepository) {
    return MyErmesService(ermesRepository);
  }
}
```

### Implementing ID Handler

```dart
class MyIdHandler implements IIdHandlerRepository {
  int _counter;
  final int _max;

  MyIdHandler({int start = 0, int? max})
      : _counter = start,
        _max = max ?? 9007199254740991; // JavaScript's MAX_SAFE_INTEGER

  @override
  IdType getNewId() {
    if (_counter >= _max) {
      throw StateError('ID counter exceeded maximum');
    }
    return _counter++;
  }

  @override
  void reset() {
    _counter = 0;
  }

  @override
  void setCounter(IdType counter) {
    _counter = counter;
  }

  @override
  IdType getCurrent() => _counter;
}
```

### Implementing Storage

```dart
class MyErmesStorage implements IErmesStorageRepository<MessageType> {
  final Map<IdType, MessageType> _storage = {};

  @override
  Future<void> store(MessageType data) async {
    final id = data.map(
      data: (msg) => msg.message.id,
      chunk: (msg) => msg.message.id,
      service: (msg) => msg.message.id,
    );
    _storage[id] = data;
  }

  @override
  Future<MessageType?> retrieve(IdType id) async {
    return _storage[id];
  }

  @override
  Future<bool> delete(IdType id) async {
    return _storage.remove(id) != null;
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  int numberOfElements() => _storage.length;

  @override
  Future<List<IdType>> listOfIds() async {
    return _storage.keys.toList();
  }

  @override
  Future<void> destroy() async {
    _storage.clear();
  }
}
```

### Using Configuration Objects

```dart
// Configure ID handler
final idHandlerInput = IdHandlerRepositoryInput(
  start: 0,
  max: 1000000,
);
final idHandler = idHandlerFactory.createRepository(idHandlerInput);

// Configure service
final serviceInput = ErmesServiceInput(
  repository: myRepository,
  idHandler: myIdHandler,
  maxByte: 16384, // 16KB chunks
  maxBuffer: 1048576, // 1MB buffer
  ermesStorageAndCaching: myStorage,
  missingMessagesCheckIntervalMs: 5000, // Check every 5 seconds
  missingMessagesThreshold: 3, // Consider missing after 3 checks
);
```

## Architecture

### Layer Separation

The interfaces are organized into layers:

1. **Repository Layer**: Low-level data transport
   - Direct WebRTC communication
   - Raw byte handling
   - Connection management

2. **Service Layer**: High-level messaging
   - Message chunking for large data
   - Reliability and retransmission
   - Message tracking

3. **Orchestration Layer**: Multi-peer management
   - Multiple connections
   - Peer discovery
   - Connection lifecycle

### Interface Hierarchy

```
IErmesPrivate (base connection lifecycle)
├── IErmesRepository (raw data transport)
│   └── IErmesIceRepository (+ WebRTC operations)
└── IErmesService (message handling)

IErmesConnection (single peer management)
└── IErmesConnectionsHandler (multi-peer management)
    └── IOrcErmes (orchestrator)

IIdHandlerPrivate (base ID generation)
├── IIdHandlerRepository (with counter control)
└── IIdHandlerService (simple generation)

IErmesStorageAndCachingReserved (base storage ops)
├── IErmesStorage (persistent storage)
├── IErmesCaching (temporary caching)
└── IErmesStorageAndCaching (combined with flush)
```

## Design Patterns

### Factory Pattern
Use factories to create instances with proper dependencies:
- `IErmesFactory`: Create repository and service instances
- `IIdHandlerFactory`: Create ID handlers
- `IErmesSignalingFactory`: Create signaling instances

### Repository Pattern
Separate data access from business logic:
- Repository handles low-level transport
- Service handles high-level messaging
- Storage/caching handles persistence

### Observer Pattern
Use callbacks for event handling:
- `onMessage`: Data arrival
- `onDataSending`/`onDataSent`: Send events
- `onSignal`: Signaling events

## Testing

Implement mock versions of interfaces for testing:

```dart
class MockRepository implements IErmesRepository {
  final List<SerializableDataType> sentData = [];
  CallbackOnDataRepository? _callback;

  @override
  void send(SerializableDataType data) {
    sentData.add(data);
  }

  @override
  void onMessage(CallbackOnDataRepository callback) {
    _callback = callback;
  }

  // Simulate receiving data
  void simulateReceive(SerializableDataType data) {
    _callback?.call(data);
  }

  @override
  bool isClosed() => false;

  @override
  bool isConnected() => true;

  @override
  Future<void> waitForConnect([int? timeoutMs]) async {}

  @override
  Future<void> waitForClose([int? timeoutMs]) async {}

  @override
  void destroy(bool force) {}
}
```

## Migration from TypeScript

This package is a direct port of the TypeScript `iermes` package:

- TypeScript `interface` → Dart `abstract class`
- Optional parameters use Dart's nullable types
- Callbacks use Dart's `typedef` for function types
- Async operations use `Future<T>`
- Generic constraints are maintained

## Best Practices

1. **Always implement all methods**: Abstract classes require full implementation
2. **Handle errors gracefully**: Use try-catch for async operations
3. **Resource cleanup**: Always implement `destroy()` methods properly
4. **Type safety**: Leverage Dart's strong typing system
5. **Documentation**: Document your implementations thoroughly

## Contributing

See the main [CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

## License

LGPL-3.0-or-later
