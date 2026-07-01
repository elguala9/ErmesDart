/// Cipher-related errors
library;

import 'package:iermes/iermes.dart';

/// Base exception for all cipher-related failures in this package.
class CipherException extends ErmesException {
  /// Creates a cipher exception with a [message] and an optional [cause].
  CipherException(super.message, [super.cause]);

  /// Short identifier used to categorize this exception.
  @override
  String get tag => 'CipherException';
}

/// Exception thrown when no valid encryption key is available
class NoValidKeyException extends CipherException {
  /// Creates the exception with a fixed no-valid-key message.
  NoValidKeyException() : super('No valid encryption key available');
}

/// Exception thrown when decryption fails with all available keys
class DecryptionFailedException extends CipherException {
  /// Creates the exception, optionally wrapping the underlying [cause].
  DecryptionFailedException([Object? cause])
    : super('Decryption failed', cause);
}

/// Exception thrown when an unsupported algorithm is requested
class UnsupportedAlgorithmException extends CipherException {
  /// Creates the exception naming the unsupported [algorithm].
  UnsupportedAlgorithmException(String algorithm)
    : super('Algorithm $algorithm is not supported');
}
