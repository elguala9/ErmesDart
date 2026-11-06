import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'exceptions.dart';

/// Whether [cipher] has passed its expiration date.
bool _isExpired(ICipher cipher) {
  final expiration = cipher.expirationDate;
  return expiration != null && expiration.isBefore(DateTime.now());
}

/// Hex form of a key digest, used as a stable map key.
String _hex(Digest id) =>
    id.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Implements IErmesPeerCipher with separate encryption and decryption ciphers.
///
/// Outbound encryption uses a single explicit "current key" pointer, distinct
/// from the set of registered keys (RFC §7.4): a rotated-in key can be
/// registered without becoming current, so the `newkey` frame announcing it
/// is still encrypted under the previous key. Decryption ciphers are indexed
/// by digest. Expired ciphers are removed on access.
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

  /// Outbound ciphers, keyed by digest hex, in registration order.
  final Map<String, ICipher> _encryptCiphers = {};

  /// Digest hex of the current outbound cipher, if any.
  String? _currentEncrypt;

  /// Ciphers available for decryption, keyed by digest hex string.
  final Map<String, ICipher> _decryptCiphers = {};

  /// Encrypts [data] with the current outbound cipher and tags it with
  /// the cipher's key digest.
  @override
  DataEncrypted encrypt(Uint8List data) {
    final cipher = _currentCipher();
    final encrypted = Uint8List.fromList(cipher.encrypt(data));
    return DataEncrypted(cipher.keyId, encrypted);
  }

  /// Decrypts [data] using the decryption cipher matching its key digest.
  @override
  Uint8List decrypt(DataEncrypted data) {
    _cleanupExpiredDecryptCiphers();
    final keyHex = _hex(data.keyId);
    final cipher = _decryptCiphers[keyHex];
    if (cipher == null) {
      throw CipherException(
        'Decryption cipher not found for key $keyHex '
        '(available: ${_decryptCiphers.keys.toList()})',
      );
    }
    try {
      return Uint8List.fromList(cipher.decrypt(data.encryptedData));
    } catch (e) {
      throw CipherException('Decryption failed for key $keyHex: $e');
    }
  }

  /// Whether a non-expired current outbound cipher is available.
  @override
  bool get hasEncryptCipher {
    _cleanupExpiredEncryptCiphers();
    return _currentEncrypt != null;
  }

  @override
  Digest get currentEncryptKeyId => _currentCipher().keyId;

  /// Registers an outbound [cipher] (replacing one with the same key id) and,
  /// when [makeCurrent] is true, moves the current-key pointer to it.
  @override
  void addEncryptCipher(ICipher cipher, {bool makeCurrent = true}) {
    final keyHex = _hex(cipher.keyId);
    _encryptCiphers
      ..remove(keyHex)
      ..[keyHex] = cipher;
    if (makeCurrent || _currentEncrypt == null) {
      _currentEncrypt = keyHex;
    }
  }

  @override
  void setCurrentEncryptCipher(Digest id) {
    final keyHex = _hex(id);
    if (!_encryptCiphers.containsKey(keyHex)) {
      throw CipherException('Encryption cipher not found for key $keyHex');
    }
    _currentEncrypt = keyHex;
  }

  /// Adds a decryption [cipher], indexed by its key id for fast lookup.
  @override
  void addDecryptCipher(ICipher cipher) {
    _decryptCiphers[_hex(cipher.keyId)] = cipher;
  }

  /// Removes the decryption cipher associated with key [id], if present.
  @override
  void removeDecryptCipher(Digest id) => _decryptCiphers.remove(_hex(id));

  /// Removes the encryption cipher with key [id]. If it was current, the
  /// pointer falls back to the most recently registered remaining key.
  @override
  void removeEncryptCipher(Digest id) {
    _encryptCiphers.remove(_hex(id));
    _repairPointer();
  }

  /// Purges expired ciphers from the encryption set.
  @override
  void clearOldEncryptCipher() => _cleanupExpiredEncryptCiphers();

  /// Purges expired ciphers from the decryption map.
  @override
  void clearOldDecryptCipher() => _cleanupExpiredDecryptCiphers();

  ICipher _currentCipher() {
    _cleanupExpiredEncryptCiphers();
    final cipher = _encryptCiphers[_currentEncrypt];
    if (cipher == null) {
      throw CipherException('No encryption cipher available');
    }
    return cipher;
  }

  void _repairPointer() {
    if (!_encryptCiphers.containsKey(_currentEncrypt)) {
      _currentEncrypt =
          _encryptCiphers.isEmpty ? null : _encryptCiphers.keys.last;
    }
  }

  void _cleanupExpiredEncryptCiphers() {
    _encryptCiphers.removeWhere((_, c) => _isExpired(c));
    _repairPointer();
  }

  void _cleanupExpiredDecryptCiphers() {
    _decryptCiphers.removeWhere((_, c) => _isExpired(c));
  }
}
