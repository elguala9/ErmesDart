import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Calculates SHA-256 hash of data for integrity verification.
///
/// Returns the hash as a hexadecimal string (64 chars for SHA-256).
///
/// Example:
/// ```dart
/// final data = Uint8List.fromList([1, 2, 3, 4]);
/// final hash = calculateHashSync(data);
/// print(hash); // e.g., "c2e5160b6c62b92f94e79e56e7f86d0e123456789..."
/// ```
String calculateHashSync(Uint8List data) {
  final digest = sha256.convert(data);
  return digest.toString();
}

/// Verifies data integrity by comparing the provided data against an expected hash.
///
/// Returns true if the hash of the data matches the expected hash,
/// false otherwise.
///
/// Example:
/// ```dart
/// final data = Uint8List.fromList([1, 2, 3, 4]);
/// final hash = calculateHashSync(data);
/// assert(verifyHash(data, hash) == true);
/// assert(verifyHash(Uint8List.fromList([1, 2, 3, 5]), hash) == false);
/// ```
bool verifyHash(Uint8List data, String expectedHash) {
  final actualHash = calculateHashSync(data);
  return actualHash == expectedHash;
}
