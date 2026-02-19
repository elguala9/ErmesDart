import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';
import 'package:iermes/iermes.dart';

import 'exceptions.dart';

/// Wrapper that associates a cipher with its unique digest ID
class _CipherEntry {
  _CipherEntry(this.cipher, this.digestId);
  final ICipher cipher;
  final Digest digestId;

  bool get isExpired {
    final expiration = cipher.expirationDate;
    return expiration != null && expiration.isBefore(DateTime.now());
  }
}

/// Implements IErmesPeerCipher with separate encryption and decryption ciphers.
///
/// This class manages two separate lists of ciphers:
/// - Encryption ciphers: Always uses the first valid cipher (index 0)
/// - Decryption ciphers: Indexed by digest for fast lookup
///
/// Ciphers are automatically removed when they expire.
@includeInBarrelFile
class ErmesPeerCipher implements IErmesPeerCipher {
  /// Creates a new ErmesPeerCipher.
  ErmesPeerCipher();

  // List of ciphers for encryption (ordered by validity)
  final List<_CipherEntry> _encryptCiphers = [];

  // Map of ciphers for decryption (indexed by digest hex string)
  final Map<String, _CipherEntry> _decryptCiphers = {};

  @override
  DataEncrypted encrypt(Uint8List data) {
    _cleanupExpiredEncryptCiphers();

    if (_encryptCiphers.isEmpty) {
      throw CipherException('No encryption cipher available');
    }

    final selectedEntry = _encryptCiphers[0];
    final encryptedData = Uint8List.fromList(selectedEntry.cipher.encrypt(data));

    return DataEncrypted(selectedEntry.digestId, encryptedData);
  }

  @override
  Uint8List decrypt(DataEncrypted data) {
    _cleanupExpiredDecryptCiphers();

    // Convert Digest bytes to hex string for stable key lookup
    final keyBytes = data.keyId.bytes;
    final keyHex =
        keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final entry = _decryptCiphers[keyHex];

    if (entry == null) {
      throw CipherException(
        'Decryption cipher not found for key $keyHex '
        '(available: ${_decryptCiphers.keys.toList()})',
      );
    }

    try {
      return Uint8List.fromList(entry.cipher.decrypt(data.encryptedData));
    } catch (e) {
      throw CipherException(
        'Decryption failed for key $keyHex: $e',
      );
    }
  }

  @override
  void addEncryptCipher(ICipher cipher) {
    final digestId = cipher.keyId;
    final entry = _CipherEntry(cipher, digestId);
    _encryptCiphers.add(entry);
    _sortEncryptCiphers();
  }

  @override
  void addDecryptCipher(ICipher cipher) {
    final digestId = cipher.keyId;
    final entry = _CipherEntry(cipher, digestId);
    // Use bytes converted to hex string for stable key lookup
    final keyBytes = digestId.bytes;
    final keyHex =
        keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _decryptCiphers[keyHex] = entry;
  }

  @override
  void removeDecryptCipher(Digest id) {
    // Use bytes converted to hex string for stable key lookup
    final keyBytes = id.bytes;
    final keyHex =
        keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _decryptCiphers.remove(keyHex);
  }

  @override
  void removeEncryptCipher(Digest id) {
    _encryptCiphers.removeWhere((e) => e.digestId == id);
  }


  @override
  void clearOldEncryptCipher() {
    _cleanupExpiredEncryptCiphers();
  }

  @override
  void clearOldDecryptCipher() {
    _cleanupExpiredDecryptCiphers();
  }

  /// Removes expired ciphers from encryption list
  void _cleanupExpiredEncryptCiphers() {
    _encryptCiphers.removeWhere((e) => e.isExpired);
  }

  /// Removes expired ciphers from decryption map
  void _cleanupExpiredDecryptCiphers() {
    _decryptCiphers.removeWhere((_, entry) => entry.isExpired);
  }

  /// Sorts encryption ciphers by expiration date (latest valid first)
  void _sortEncryptCiphers() {
    _encryptCiphers.sort((a, b) {
      final aExp = a.cipher.expirationDate ?? DateTime(2099);
      final bExp = b.cipher.expirationDate ?? DateTime(2099);
      return bExp.compareTo(aExp);
    });
  }

}
