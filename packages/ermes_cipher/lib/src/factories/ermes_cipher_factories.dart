import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';

import '../ermes_peer_cipher.dart';


/// Creates an ErmesPeerCipher instance for managing peer-to-peer encryption.
///
/// The returned cipher manages separate encrypt and decrypt cipher lists.
/// Use [addEncryptCipher] and [addDecryptCipher] to add ciphers as needed.
@includeInBarrelFile
IErmesPeerCipher createErmesPeerCipher() => ErmesPeerCipher();

/// Creates a symmetric cipher based on KeyInfo.
///
/// Takes a KeyInfo containing the key material, algorithm type, and validity
/// dates, and returns an ISymmetricCipher instance configured accordingly.
///
/// Supported algorithms via CryptoAlgorithm enum:
/// - AES (with configurable modes)
/// - DES
///
/// Throws [Exception] if the algorithm is not supported.
@includeInBarrelFile
ISymmetricCipher createCipher(KeyInfo keyInfo) =>
    generateSymmetric(keyInfo.key, keyInfo.alg, keyInfo.expiration);

/// Creates a signer based on KeyInfo.
///
/// Takes a KeyInfo containing the key material and algorithm type,
/// and returns a signer instance configured accordingly.
///
/// Supported algorithms via CryptoAlgorithm enum:
/// - HMAC (general purpose with symmetric key)
/// - EdDSA / Ed25519 (modern asymmetric signature)
/// - ECDSA (Elliptic Curve DSA with P-256/384/521 curves)
/// - RSA (RSA-PSS or RSA-PKCS1v15)
///
/// Throws [Exception] if the algorithm is not supported or if key format
/// is invalid.
@includeInBarrelFile
ISign createSigner(KeyInfo keyInfo) {

  // HMAC-based signing (symmetric key)
  if (keyInfo.alg == SymmetricAlgorithm.hmac) {
    final input = InputHMACSign(
      parent: InputSymmetricSign(
        parent: InputSign(
          parent: InputExpirationBase(expirationDate: keyInfo.expiration),
        ),
        key: keyInfo.key,
      ),
    );
    return HMACSign(input);
  }

  throw Exception('Signer algorithm not supported: ${keyInfo.alg}');
}

/// Generates a symmetric cipher with the given key and algorithm.
///
/// Takes a key (String or bytes) and algorithm type, and optional expiration
/// parameters, returning an ISymmetricCipher instance configured accordingly.
///
/// Supported algorithms via CryptoAlgorithm enum:
/// - AES
/// - DES
///
/// Throws [Exception] if the algorithm is not supported.
@includeInBarrelFile
ISymmetricCipher generateSymmetric(
  dynamic key,
  CryptoAlgorithm alg,
  [DateTime? expirationDate,
  int? expirationTimes,]
) {
  final inputCipher = InputCipher(
    parent: InputExpirationBase(
      expirationDate: expirationDate,
      expirationTimes: expirationTimes,
    ),
  );

  // Convert bytes to hex string if needed
  final keyString = key is String ? key : _bytesToHexString(key);

  final inputSymmetricCipher =
      InputSymmetricCipher(parent: inputCipher, key: keyString);
  if (alg == SymmetricAlgorithm.aes) {
    final inputAESCipher = InputAESCipher(parent: inputSymmetricCipher);
    return AESCipher.createFull(inputAESCipher);
  }
  if (alg == SymmetricAlgorithm.des) {
    final inputDESCipher = InputDESCipher(parent: inputSymmetricCipher);
    return DESCipher(inputDESCipher);
  }

  throw Exception('Algorithm not found');
}

/// Convert bytes to hex string
String _bytesToHexString(dynamic bytes) {
  if (bytes is String) return bytes;
  if (bytes is List<int>) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  throw Exception('Invalid key type');
}
