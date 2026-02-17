import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/interfaces/i_cipher.dart';
import 'package:cryptdart/interfaces/i_simmetric.dart';

/// Interface for serializable ECDH private key
///
/// Represents a P-256 elliptic curve private key with serialization
/// capabilities. Implementations should provide secure key material handling
/// and serialization/deserialization.
@includeInBarrelFile
abstract class IECDHKeyExchangeService {

  /// Serialize to string format for storage/transmission
  ///
  /// Returns a string representation suitable for storage or transmission.
  /// The format is implementation-specific but must be consistent for
  /// deserialization.
  String serialize();

  /// Generate a new ISymmetric for encryption
  ISymmetric generateISymmetric(String serialization);

  /// Generate ECDH key exchange service from serialized string
  ///
  /// Factory method that deserializes a previously serialized key exchange service.
  /// Implementations should provide this static method to restore key material
  /// from a serialized format. Throws [FormatException] if deserialization fails.
  static IECDHKeyExchangeService generateFromSerialize(String serialization) {
    throw UnimplementedError('Subclasses must implement generateFromSerialize');
  }

 
}
