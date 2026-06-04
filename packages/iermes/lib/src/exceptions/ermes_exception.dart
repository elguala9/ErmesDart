library;

/// Base class for all Ermes exceptions.
///
/// All custom exceptions in the Ermes ecosystem must extend this class
/// so callers can catch a single root type.
abstract class ErmesException implements Exception {
  ErmesException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  /// Short tag used in [toString]; subclasses override with their own name.
  String get tag => 'ErmesException';

  @override
  String toString() {
    final suffix = cause != null ? ' (cause: $cause)' : '';
    return '$tag: $message$suffix';
  }
}

/// Network / transport layer failures (connection refused, timeout, etc.).
class ErmesNetworkException extends ErmesException {
  ErmesNetworkException(super.message, [super.cause]);

  @override
  String get tag => 'ErmesNetworkException';
}

/// Serialization / deserialization failures (malformed payloads, etc.).
class ErmesSerializationException extends ErmesException {
  ErmesSerializationException(super.message, [super.cause]);

  @override
  String get tag => 'ErmesSerializationException';
}

/// Persistent / cache storage failures.
class ErmesStorageException extends ErmesException {
  ErmesStorageException(super.message, [super.cause]);

  @override
  String get tag => 'ErmesStorageException';
}

/// Input validation failures (bounds checking, malformed identifiers, etc.).
class ErmesValidationException extends ErmesException {
  ErmesValidationException(super.message, [super.cause]);

  @override
  String get tag => 'ErmesValidationException';
}
