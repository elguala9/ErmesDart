/// Cipher-related errors
library;

import 'package:iermes/iermes.dart';

class CipherException extends ErmesException {
  CipherException(super.message, [super.cause]);

  @override
  String get tag => 'CipherException';
}

/// Exception thrown when no valid encryption key is available
class NoValidKeyException extends CipherException {
  NoValidKeyException() : super('No valid encryption key available');
}

/// Exception thrown when decryption fails with all available keys
class DecryptionFailedException extends CipherException {
  DecryptionFailedException([Object? cause])
    : super('Decryption failed', cause);
}

/// Exception thrown when an unsupported algorithm is requested
class UnsupportedAlgorithmException extends CipherException {
  UnsupportedAlgorithmException(String algorithm)
    : super('Algorithm $algorithm is not supported');
}
