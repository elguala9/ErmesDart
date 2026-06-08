
/// Interface for encrypting/decrypting data at rest in storage repositories.
///
/// Implementations can use any encryption algorithm (e.g., AES-256-CBC).
/// The [encrypt] method is called before writing to the underlying store,
/// and [decrypt] is called after reading from it.
abstract class IStorageEncryptionService {
  /// Encrypt [data] and return the encrypted form.
  /// The returned map will be stored as-is in the repository.
  Map<String, dynamic> encrypt(Map<String, dynamic> data);

  /// Decrypt [data] that was previously encrypted by [encrypt].
  /// Returns the original plaintext map.
  Map<String, dynamic> decrypt(Map<String, dynamic> data);
}
