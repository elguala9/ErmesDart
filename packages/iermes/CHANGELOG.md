# Changelog

All notable changes to the iermes package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (breaking)
- `IErmesPrivate.isClosed()` is now the getter
  `IErmesPrivate.isConnectionClosed`.

  `IErmesRepository` implementations extend shsp's `ShspInstance`, which since
  shsp 1.10.1 carries an `isClosed` getter of its own (via
  `IdempotentCloseMixin`) meaning "close() was called on this peer". Keeping
  the old name forced a choice between a compile error (method vs. getter) and
  silently overriding shsp's state — and the override made a freshly built
  repository report itself closed, so shsp refused to send the handshake that
  would have opened it.

  The two concepts are genuinely different: a repository that has not finished
  its handshake is unusable but not closed. They now have separate names.

  Migration: `repository.isClosed()` / `service.isClosed()` becomes
  `repository.isConnectionClosed` / `service.isConnectionClosed`.

## [1.0.0] - 2024-12-24

### Added
- Initial release of iermes package
- Standard interfaces for Ermes communication
  - `IErmes`: Core repository and service interfaces
  - `IErmesConnection`: Connection management
  - `IErmesConnectionsHandler`: Multi-peer management
  - `IErmesFactory`: Factory for creating instances
  - `IErmesIce`: WebRTC ICE operations
  - `IErmesMessageControl`: Message tracking and reliability
  - `IIdHandler`: ID generation
  - `IIdHandlerFactory`: ID handler factory
  - `IIdHandlerStorage`: ID persistence
  - `IOrcErmes`: High-level orchestrator
- Signaling interfaces for WebRTC
  - `IErmesBook`: Account/peer directory
  - `IErmesSignaling`: Signaling operations
  - `IErmesSignalingFactory`: Signaling factory
  - `IErmesSignalingHandler`: Peer connection management
  - `IErmesSignalingServer`: Signaling server interface
- Storage interfaces for message persistence
  - `IErmesStorage`: Persistent storage
  - `IErmesCaching`: Temporary caching
  - `IErmesStorageAndCaching`: Combined interface
  - `IErmesStorageReserved`: Base storage operations
- Input/configuration types
  - `ErmesServiceInput`: Service configuration
  - `IdHandlerInput`: ID handler configuration
  - `ErmesWebrtcRepositoryInput`: WebRTC configuration
- Comprehensive documentation
- Usage examples for all interfaces

### Changed
- Migrated from TypeScript to Dart
- Converted TypeScript interfaces to Dart abstract classes
- Adapted callback types to Dart function types
- Updated async patterns to use Dart Futures

### Technical Details
- Zero runtime dependencies (only dev dependencies)
- Depends on ermes_types package for type definitions
- Full documentation with examples
- Dart-style naming conventions (snake_case for files)
