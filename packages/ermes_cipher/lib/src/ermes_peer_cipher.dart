import 'dart:typed_data';


import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'exceptions.dart';

/// Wrapper that associates a cipher with its unique digest ID
class _CipherEntry {
  /// Pairs a [cipher] with the [digestId] that identifies it.
  _CipherEntry(this.cipher, this.digestId);
  /// The underlying cipher used for encryption or decryption.
  final ICipher cipher;
  /// Digest identifying the key this cipher was derived from.
  final Digest digestId;

  /// Whether the wrapped cipher has passed its expiration date.
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
@dependencyInjectable
class ErmesPeerCipher implements IErmesPeerCipher {
  /// Creates a new ErmesPeerCipher.
  ErmesPeerCipher();

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ErmesPeerCipher.dependencyInjectionFactory({
    // ignore: avoid_unused_constructor_parameters
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) =>
      ErmesPeerCipher(); // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Ciphers available for encryption, ordered by validity.
  // List of ciphers for encryption (ordered by validity)
  final List<_CipherEntry> _encryptCiphers = [];

  /// Ciphers available for decryption, keyed by digest hex string.
  // Map of ciphers for decryption (indexed by digest hex string)
  final Map<String, _CipherEntry> _decryptCiphers = {};

  /// Encrypts [data] with the current encryption cipher and tags it with
  /// the cipher's key digest.
  @override
  DataEncrypted encrypt(Uint8List data) {
    _cleanupExpiredEncryptCiphers();

    if (_encryptCiphers.isEmpty) {
      throw CipherException('No encryption cipher available');
    }

    final selectedEntry = _encryptCiphers[0];
    final encryptedData = Uint8List.fromList(
      selectedEntry.cipher.encrypt(data),
    );

    return DataEncrypted(selectedEntry.digestId, encryptedData);
  }

  /// Decrypts [data] using the decryption cipher matching its key digest.
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

  /// Whether at least one non-expired encryption cipher is available.
  @override
  bool get hasEncryptCipher {
    _cleanupExpiredEncryptCiphers();
    return _encryptCiphers.isNotEmpty;
  }

  /// Adds an encryption [cipher], replacing any existing one with the same
  /// key id to avoid duplicates.
  @override
  void addEncryptCipher(ICipher cipher) {
    final digestId = cipher.keyId;
    // A key is identified by its keyId: re-adding the same key (e.g. the same
    // shared secret re-derived on a fresh signal) must not stack duplicates,
    // so replace any existing entry with the same id instead of appending.
    _encryptCiphers
      ..removeWhere((e) => e.digestId == digestId)
      ..add(_CipherEntry(cipher, digestId));
    _sortEncryptCiphers();
  }

  /// Adds a decryption [cipher], indexed by its key id for fast lookup.
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

  /// Removes the decryption cipher associated with key [id], if present.
  @override
  void removeDecryptCipher(Digest id) {
    // Use bytes converted to hex string for stable key lookup
    final keyBytes = id.bytes;
    final keyHex =
        keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _decryptCiphers.remove(keyHex);
  }

  /// Removes any encryption cipher associated with key [id].
  @override
  void removeEncryptCipher(Digest id) {
    _encryptCiphers.removeWhere((e) => e.digestId == id);
  }


  /// Purges expired ciphers from the encryption list.
  @override
  void clearOldEncryptCipher() {
    _cleanupExpiredEncryptCiphers();
  }

  /// Purges expired ciphers from the decryption map.
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
