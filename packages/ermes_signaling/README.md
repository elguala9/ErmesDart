# Ermes Signaling

Implementation of the signaling layer for the Ermes peer-to-peer messaging system.

## Overview

`ermes_signaling` provides the core signaling functionality for Ermes, enabling peer discovery and WebRTC connection establishment through Nostr-based signaling.

## Features

- **Book Management** (`ErmesBookRepository`) - Contact/peer management with pagination support
- **Signaling Server** (`ErmesSignalingServer`) - Peer discovery using Nostr protocol
- **Signaling Repository** (`ErmesSignalingRepository`) - Coordination between server and signal handler
- **Signaling Service** (`ErmesSignalingService`) - Service layer above repository
- **Reconnection Handler** (`ErmesSignalingReconnector`) - Automatic reconnection with retry logic
- **Factories** - Factory classes for creating signaling components

## Installation

Add `ermes_signaling` as a path dependency in your `pubspec.yaml`:

```yaml
dependencies:
  ermes_signaling:
    path: ../ermes_signaling
```

## Dependencies

- `iermes` - Interfaces for Ermes system
- `nostr_signaling` - Nostr-based signaling library
- `stun_shsp` - STUN and SHSP protocol support

## Usage

### Creating Signaling Components

```dart
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

// Create a Nostr signaling instance
final nostrSignaling = NostrSignalingFactory.create(
  pubkey: 'your-public-key-hex',
  privkey: 'your-private-key-hex',
);
await nostrSignaling.connect();

// Create an Ermes signaling server wrapping Nostr
final server = ErmesSignalingServerFactory.createServer(
  nostrSignaling,
  accountId,
);

// Create signaling components using factory
final (repository, service) = ErmesSignalingFactory.createBoth(
  signalingServer: server,
  signalHandler: handler,
);
```

### Managing Contacts

```dart
final bookRepository = ErmesBookFactories.createRepository();

// Add a contact
bookRepository.setAccount(
  AccountInfo(
    account: 'peer-id',
    info: BookData(peerId: 'peer-id', name: 'Contact Name', timestamp: now),
  ),
);

// Retrieve contact
final contact = bookRepository.getAccount('peer-id');

// List contacts with pagination
final paginated = bookRepository.getAccountList('', 10);
```

## Architecture

The signaling layer follows a repository pattern:

- **Server** (`IErmesSignalingServer`) - Low-level Nostr signaling interaction
- **Repository** (`IErmesSignalingRepository`) - Coordinates server and signal handler
- **Service** (`IErmesSignalingService`) - High-level API for clients

## License

See LICENSE file in the root of the repository.
