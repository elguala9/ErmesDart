import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:iermes/src/encryption/i_ermes_crypt_collection.dart';
import 'package:iermes/src/encryption/i_ermes_peer_cipher.dart';
import 'package:crypto/crypto.dart';


import 'ermes_crypt_collection.dart';
import 'exceptions.dart';
import 'key_selector.dart';

/// Implements IErmesPeerCipher with multi-key support and key rotation.
///
/// This class manages a pool of KeyInfo objects and automatically selects
/// the appropriate key for encryption/decryption based on validity
/// timestamps.
@includeInBarrelFile
class ErmesPeerCipher implements IErmesPeerCipher {
  /// Creates a new ErmesPeerCipher with the specified algorithm
  /// and optional initial keys.
  ErmesPeerCipher({
    required CryptoAlgorithm algorithm,
    List<ICipher>? initialCipher,
  })  : _algorithm = algorithm,
        _cipher = initialCipher ?? List<ICipher>.empty();

  final CryptoAlgorithm _algorithm;
  final List<ICipher> _cipher;

  // Cache of encrypt/decrypt objects for performance
  final Map<Digest, ICipher> _encryptCache = {};
  final Map<Digest, ICipher> _decryptCache = {};

  @override
  List<int> encrypt(List<int> data) {
    final selectedKey = KeySelector.selectForEncryption(_keys, DateTime.now());

    if (selectedKey == null) {
      throw CipherException('No encryption key available');
    }

    final encryptor = _getEncrypt(selectedKey);
    return encryptor.encrypt(data);
  }

  @override
  List<int> decrypt(List<int> data) {
    final selectedKey = KeySelector.selectForDecryption(_keys, DateTime.now());

    if (selectedKey == null) {
      throw CipherException('No decryption key available');
    }

    final decryptor = _getDecrypt(selectedKey);

    try {
      return decryptor.decrypt(data);
    } on Object catch (e) {
      // Fallback: try with other keys (handles clock drift)
      return _attemptDecryptWithOtherKeys(data, selectedKey, e);
    }
  }

  @override
  void addCipher(ICipher cipher) {
    _cipher.add(cipher);
    _cleanupOldKeys();
  }

  /// Removes expired keys (older than 24 hours) and cleans up cache
  void _cleanupOldKeys() {
    final now = DateTime.now();
    final oldThreshold = now.subtract(const Duration(hours: 24));

    // Remove keys expired more than 24 hours ago
    _cipher.removeWhere((k) => k.expirationDate.isBefore(oldThreshold));

    // Clean up cache for removed keys
    final validKeyStrings = _cipher.map((k) => k.key).toSet();
    _encryptCache.removeWhere((k, _) => !validKeyStrings.contains(k));
    _decryptCache.removeWhere((k, _) => !validKeyStrings.contains(k));
  }
}
