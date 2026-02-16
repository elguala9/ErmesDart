import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'serializable_ecdh_private_key.dart';

/// Utility class for ECDH key operations
///
/// Provides convenient methods for creating, loading, and saving ECDH keys
/// with serialization support.
@includeInBarrelFile
class ECDHKeyUtilities {
  ECDHKeyUtilities._(); // Private constructor to prevent instantiation

  /// Create an ECDH private key from existing key material
  ///
  /// Parameters:
  ///   - `privateKeyBytes`: The private key bytes (P-256: 32 bytes)
  ///   - `publicKeyBytes`: The public key bytes (P-256: 65 bytes)
  ///
  /// Throws [ArgumentError] if any key bytes are empty
  static SerializableECDHPrivateKey createFromBytes({
    required List<int> privateKeyBytes,
    required List<int> publicKeyBytes,
  }) =>
      SerializableECDHPrivateKey.fromBytes(
        privateKeyBytes: privateKeyBytes,
        publicKeyBytes: publicKeyBytes,
      );

  /// Load an ECDH private key from serialized string
  ///
  /// Expected format: "base64(privateKey):base64(publicKey)"
  ///
  /// Throws [FormatException] if the format is invalid
  static SerializableECDHPrivateKey loadFromString(String serialized) =>
      SerializableECDHPrivateKey.deserialize(serialized);

  /// Save an ECDH private key to a serialized string
  ///
  /// The returned string can be stored and later restored with [loadFromString]
  /// Format: "base64(privateKey):base64(publicKey)"
  static String saveToString(SerializableECDHPrivateKey key) =>
      key.serialize();

  /// Generate a new ECDH private key with random material
  ///
  /// Creates a new P-256 key pair using cryptdart's ECDH implementation.
  /// Returns a [SerializableECDHPrivateKey] ready for use or storage.
  ///
  /// Example:
  /// ```dart
  /// final newKey = await ECDHKeyUtilities.generateNewKey();
  /// final serialized = ECDHKeyUtilities.saveToString(newKey);
  /// ```
  static Future<SerializableECDHPrivateKey> generateNewKey() =>
      SerializableECDHPrivateKey.generateNew();
}
