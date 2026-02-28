
import 'package:iermes/iermes.dart';

import 'ecdh_key_exchange_service.dart';

/// Utility class for ECDH key operations
///
/// Provides convenient methods for creating, loading, and saving ECDH keys
/// with serialization support.

class ECDHKeyUtilities {
  ECDHKeyUtilities._(); // Private constructor to prevent instantiation

  /// Load an ECDH key exchange service from serialized string
  ///
  /// Expected format: JSON with publicKey, privateKey, and expirationDate
  /// Example: `{"publicKey":"...","privateKey":"...","expirationDate":"..."}`
  ///
  /// Throws [FormatException] if the format is invalid
  static IECDHKeyExchangeService loadFromString(String serialized) =>
      ECDHKeyExchangeService.deserialize(serialized);

  /// Save an ECDH key exchange service to a serialized string
  ///
  /// The returned string can be stored and later restored with [loadFromString]
  /// Format: JSON with publicKey, privateKey, and expirationDate
  static String saveToString(IECDHKeyExchangeService key) =>
      key.serialize();

  /// Generate a new ECDH key exchange service with random material
  ///
  /// Creates a new P-256 key pair using cryptdart's ECDH implementation.
  /// Returns an [IECDHKeyExchangeService] ready for use or storage.
  ///
  /// Example:
  /// ```dart
  /// final service = await ECDHKeyUtilities.generateNewKey();
  /// final serialized = ECDHKeyUtilities.saveToString(service);
  /// ```
  static Future<IECDHKeyExchangeService> generateNewKey() =>
      ECDHKeyExchangeService.generateNew();
}
