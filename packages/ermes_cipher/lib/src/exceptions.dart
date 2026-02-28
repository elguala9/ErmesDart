import 'package:barrel_files_annotation/barrel_files_annotation.dart';

/// Base exception for all cipher-related errors

class CipherException implements Exception {
  CipherException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final suffix = cause != null ? ' (cause: $cause)' : '';
    return 'CipherException: $message$suffix';
  }
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
