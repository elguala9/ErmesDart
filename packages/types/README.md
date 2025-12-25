# Ermes Types

Type definitions and data structures for the Ermes messaging system.

## Overview

This package provides all the core types, enums, and data structures used throughout the Ermes messaging protocol. It's designed to be a pure types package with no external dependencies (except for code generation tools).

## Features

### Core Message Types

- **MessageData**: Base data messages for simple data transfer
- **ChunkMessage**: Support for splitting large data into chunks
- **ServiceMessage**: Control and coordination messages
- **MessageType**: Union type for all message kinds

### Signaling Types

WebRTC signaling support for peer-to-peer connections:

- **SignalData**: SDP offer/answer structures
- **ReusableOffer/Answer**: Enriched signaling with metadata
- **SignalInfo**: Polymorphic signal information

### Pagination

Generic pagination support with cursor-based navigation:

- **PaginationDto**: Flexible pagination with any cursor type
- Built-in helpers for checking page state

### Type Safety

All types are implemented using [Freezed](https://pub.dev/packages/freezed) for:

- Immutability
- Union types
- Pattern matching
- Copy-with functionality
- JSON serialization

## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  ermes_types:
    path: ../types
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Message Types

```dart
import 'package:ermes_types/ermes_types.dart';
import 'dart:typed_data';

// Create a simple data message
final message = MessageData(
  id: 1,
  data: Uint8List.fromList([1, 2, 3, 4]),
);

// Create a chunk message for large data
final chunk = ChunkMessage(
  id: 1,
  data: Uint8List.fromList([1, 2, 3]),
  refId: 'large-file-123',
  index: 0,
  roof: 10, // 10 total chunks
);

// Create a service message
const serviceMsg = ServiceMessage(
  id: 2,
  reason: ServiceReasons.completed,
  arrayChunkInfo: [
    ChunkInfo(chunkId: 1, index: [0, 1, 2]),
  ],
);
```

### Message Type Union

```dart
// Use pattern matching with message types
void handleMessage(MessageType messageType) {
  messageType.when(
    data: (msg) => print('Received data message: ${msg.id}'),
    chunk: (msg) => print('Received chunk ${msg.index}/${msg.roof}'),
    service: (msg) => print('Service message: ${msg.reason}'),
  );
}

// Or use map for transformations
final messageId = messageType.map(
  data: (msg) => msg.message.id,
  chunk: (msg) => msg.message.id,
  service: (msg) => msg.message.id,
);
```

### Pagination

```dart
// Create a paginated result
final page = PaginationDto<String, int>(
  cursor: 0,
  pageSize: 10,
  totalItems: 100,
  eof: false,
  items: ['item1', 'item2', 'item3'],
  nextCursor: 10,
);

// Use helper methods
if (page.hasMore) {
  print('More pages available');
}

print('Current page has ${page.itemCount} items');

// Navigate to next page
final nextPage = page.copyWith(
  cursor: page.nextCursor,
  items: fetchNextItems(),
  nextCursor: page.nextCursor + 10,
);
```

### Signaling Types

```dart
// Create an offer
const offer = SignalInfoOffer(
  signalData: SignalData(
    type: 'offer',
    sdp: 'v=0\r\no=- 123...',
  ),
  reusableOffer: ReusableOffer(
    sdp: 'v=0\r\no=- 123...',
    offerId: 'offer-abc-123',
  ),
);

// Check signal type
if (offer.isOffer()) {
  final offerInfo = offer.getOfferInfo();
  print('Offer ID: ${offerInfo.offerId}');
}

// Create an answer
const answer = SignalInfoAnswer(
  signalData: SignalData(
    type: 'answer',
    sdp: 'v=0\r\no=- 456...',
  ),
  reusableAnswer: ReusableAnswer(
    answerId: 'answer-xyz-789',
    connectionId: 'conn-123',
    offerId: 'offer-abc-123',
    targetPeer: 'peer-456',
  ),
);
```

### Callbacks

```dart
// Define message handlers
CallbackOnMessageData onData = (MessageData message) {
  print('Received data: ${message.data.length} bytes');
};

CallbackOnDataArrivedFrom onDataFrom = (Uint8List data, String peerId) {
  print('Received ${data.length} bytes from peer $peerId');
};

// Service message handler
CallbackServiceMessage onService = (ServiceMessage message) {
  switch (message.reason) {
    case ServiceReasons.completed:
      print('Transfer completed');
      break;
    case ServiceReasons.sendAgain:
      print('Retransmission requested');
      break;
    case ServiceReasons.closing:
      print('Connection closing');
      break;
  }
};
```

### JSON Serialization

All types support JSON serialization:

```dart
// Serialize to JSON
final message = MessageData(id: 1, data: Uint8List(10));
final json = message.toJson();

// Deserialize from JSON
final restored = MessageData.fromJson(json);

// Works with union types too
const messageType = MessageType.service(
  ServiceMessage(id: 1, reason: ServiceReasons.completed),
);
final typeJson = messageType.toJson();
final restoredType = MessageType.fromJson(typeJson);
```

## Architecture

### Design Principles

1. **Immutability**: All types are immutable using Freezed
2. **Type Safety**: Strong typing with union types where appropriate
3. **Extensibility**: Generic types support custom data structures
4. **Serialization**: Built-in JSON support for all types
5. **Zero Dependencies**: Only dev dependencies for code generation

### Type Hierarchy

```
MessageWithId (interface)
├── MessageData
├── ChunkMessage
└── ServiceMessage

MessageType (union)
├── data(MessageData)
├── chunk(ChunkMessage)
└── service(ServiceMessage)

ISignalInfo (interface)
├── SignalInfoOffer
└── SignalInfoAnswer
```

## Code Generation

This package uses code generation for Freezed classes. After making changes to the types, run:

```bash
# From the package directory
dart run build_runner build --delete-conflicting-outputs

# Or watch for changes
dart run build_runner watch --delete-conflicting-outputs
```

## Testing

Run tests with:

```bash
dart test
```

The package includes comprehensive tests for all types.

## Constants

### Message Value Enum

```dart
enum MessageValue {
  base,    // Base message
  chunk,   // Chunk message
  service, // Service message
}
```

### Service Reasons

```dart
ServiceReasons.completed  // 'c' - Transfer completed
ServiceReasons.sendAgain  // 's' - Retransmission requested
ServiceReasons.closing    // 'x' - Connection closing
```

### Size Constants

```dart
maxHeader = 81  // Maximum header size in bytes
```

## Type Aliases

The package provides convenient type aliases:

- `TypeOfData` / `TypeOfDataExternal` - Uint8List
- `IdPeer` - String (peer identifier)
- `IdType` - int (message identifier)
- `IdChunkType` - String (chunk identifier)
- `ChunkIndexType` - int (chunk index)
- `SerializableDataType` - Uint8List

## Migration from TypeScript

This package is a direct port of the TypeScript `ermes-types` package with the following adaptations:

- TypeScript union types → Freezed union types
- TypeScript interfaces → Abstract classes or Freezed
- Type aliases → Dart typedefs
- Optional fields → Nullable types
- Generics → Dart generics with proper constraints

## Contributing

See the main [CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

## License

LGPL-3.0-or-later
