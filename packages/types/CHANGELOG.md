# Changelog

All notable changes to the ermes_types package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-24

### Added
- Initial release of ermes_types package
- Core message types (MessageData, ChunkMessage, ServiceMessage)
- Message type union with Freezed support
- Signaling types for WebRTC connections
  - SignalData, Signal, ReusableOffer, ReusableAnswer
  - SignalInfoOffer, SignalInfoAnswer with ISignalInfo interface
  - Response types (Response, OfferResponse, AnswerResponse)
- Generic pagination support (PaginationDto)
- Comprehensive type aliases for Ermes protocol
- Callback type definitions for message handling
- JSON serialization support for all types
- Full test coverage for all types
- Complete documentation and usage examples

### Changed
- Migrated from TypeScript to Dart
- Adapted TypeScript interfaces to Dart abstract classes and Freezed
- Converted TypeScript union types to Freezed union types
- Replaced simple-peer types with generic peer placeholder

### Technical Details
- Uses Freezed for immutable data classes
- Uses json_serializable for JSON support
- Zero runtime dependencies (only dev dependencies)
- 100% test coverage
