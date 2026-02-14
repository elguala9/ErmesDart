import 'package:barrel_files_annotation/barrel_files_annotation.dart';

/// Base exception for all cipher-related errors
@includeInBarrelFile
class CipherException implements Exception {
  CipherException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'CipherException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Exception thrown when no valid encryption key is available
@includeInBarrelFile
class NoValidKeyException extends CipherException {
  NoValidKeyException() : super('No valid encryption key available');
}

/// Exception thrown when decryption fails with all available keys
@includeInBarrelFile
class DecryptionFailedException extends CipherException {
  DecryptionFailedException([Object? cause])
    : super('Decryption failed', cause);
}

/// Exception thrown when an unsupported algorithm is requested
@includeInBarrelFile
class UnsupportedAlgorithmException extends CipherException {
  UnsupportedAlgorithmException(String algorithm)
    : super('Algorithm $algorithm is not supported');
}
