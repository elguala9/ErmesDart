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

/// ERMES version negotiation failure (RFC ermes-protocol section 7.1).
///
/// Permanent and non-retryable: the connection MUST NOT exchange application
/// data and MUST NOT be re-attempted with the same peer configuration. It is
/// distinct from SHSP transport failures, which may be healthy meanwhile.
/// Thrown as-is when the peer never announces its version in time.
class ErmesVersionNegotiationException extends ErmesException {
  ErmesVersionNegotiationException(super.message, [super.cause]);

  /// Always false: negotiation failures must never be retried.
  bool get isRetryable => false;

  @override
  String get tag => 'ErmesVersionNegotiationException';
}

/// The peers advertised different majors (X): their envelope wire shapes
/// cannot interoperate (RFC ermes-protocol section 7.1). Non-retryable.
class ErmesVersionMismatchException extends ErmesVersionNegotiationException {
  ErmesVersionMismatchException(super.message, [super.cause]);

  @override
  String get tag => 'ErmesVersionMismatchException';
}

/// Symmetric NAT or UDP-blocked network detected (RFC ermes-protocol
/// section 5). Permanent and non-retryable: SHSP cannot traverse it, and
/// ERMES defines no relay fallback, so the peer is unsupported.
class ErmesSymmetricNatException extends ErmesException {
  ErmesSymmetricNatException(super.message, [super.cause]);

  /// Always false: this condition must never be retried.
  bool get isRetryable => false;

  @override
  String get tag => 'ErmesSymmetricNatException';
}
