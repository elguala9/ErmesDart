# Ermes Signaling

Implementation of the signaling layer for the Ermes peer-to-peer messaging system.

## Overview

`ermes_signaling` provides the core signaling functionality for Ermes, enabling peer discovery and WebRTC connection establishment through blockchain-based signaling contracts.

## Features

- **Book Management** (`ErmesBookRepository`) - Contact/peer management with pagination support
- **Signaling Server** (`ErmesSignalingServer`) - WebRTC peer discovery using blockchain contracts
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
- `ermes_types` - Type definitions for Ermes
- `signaling_contract_sdk` - Blockchain signaling contract SDK
- `web3dart` - Ethereum/Web3 interaction

## Usage

### Creating Signaling Components

```dart
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';

// Create a signaling server
final server = ErmesSignalingServerFactory.createServer(contract, accountId);

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
await bookRepository.setAccount(
  'peer-id',
  BookInput(name: 'Contact Name'),
);

// Retrieve contact
final contact = await bookRepository.getAccount('peer-id');

// List contacts with pagination
final paginated = await bookRepository.getAccountList('', 10);
```

## Architecture

The signaling layer follows a repository pattern:

- **Server** (`IErmesSignalingServer`) - Low-level blockchain contract interaction
- **Repository** (`IErmesSignalingRepository`) - Coordinates server and signal handler
- **Service** (`IErmesSignalingService`) - High-level API for clients

## License

See LICENSE file in the root of the repository.
