
import 'package:cryptdart/interfaces/i_simmetric.dart';

import '../../iermes.dart';
import '../types/common/cipher_types.dart';

/// Interface for peer key exchange with asymmetric encryption
///
/// Handles the preparation of key material for secure peer-to-peer
/// communication:
/// - Serializes the local key for transmission
/// - Encrypts the shared symmetric key with the peer's public key
///
/// Does NOT handle actual data transmission - only preparation and
/// serialization.
abstract class IErmesPeerKeyExchange {
  /// Prepare encrypted symmetric key for transmission
  ///
  /// Encrypts the locally-generated symmetric key using the peer's public key,
  /// so that only the peer can decrypt it with their private key.
  ///
  /// Returns [DataEncrypted] containing:
  /// - keyId: The digest of the encryption key used
  /// - encryptedData: The encrypted symmetric key material
  DataEncrypted prepareEncryptedSymmetricKey(ISymmetricCipher symmetric);


  /// Deserialize from a serialized key exchange state
  ///
  /// Restores a previously serialized key exchange. Must match the format
  /// produced by [serialize].
  ISymmetricCipher deserialize(DataEncrypted encryptedInfo);
}
