import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'cipher_helpers.dart';
import 'decrypt_key_ring.dart';
import 'exceptions.dart';

/// Implements IErmesPeerCipher with separate encryption and decryption ciphers.
///
/// Outbound encryption uses a single explicit "current key" pointer, distinct
/// from the set of registered keys (RFC section 7.4): a rotated-in key can be
/// registered without becoming current, so the `newkey` frame announcing it
/// is still encrypted under the previous key. Expired outbound ciphers are
/// removed on access; decryption keys are never evicted by wall clock, only
/// by count (see [DecryptKeyRing]).
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
  final DecryptKeyRing _decryptCiphers = DecryptKeyRing();

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
  Uint8List decrypt(DataEncrypted data) =>
      _decryptCiphers.decrypt(digestHex(data.keyId), data.encryptedData);

  @override
  bool isIdInKeyBounds(Digest keyId, IdType messageId) =>
      _decryptCiphers.isIdInBounds(digestHex(keyId), messageId);

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
    final keyHex = digestHex(cipher.keyId);
    _encryptCiphers
      ..remove(keyHex)
      ..[keyHex] = cipher;
    if (makeCurrent || _currentEncrypt == null) {
      _currentEncrypt = keyHex;
    }
  }

  @override
  void setCurrentEncryptCipher(Digest id) {
    final keyHex = digestHex(id);
    if (!_encryptCiphers.containsKey(keyHex)) {
      throw CipherException('Encryption cipher not found for key $keyHex');
    }
    _currentEncrypt = keyHex;
  }

  /// Adds a decryption [cipher] valid for message ids in
  /// [[startMessage], [endMessage]] (null = open-ended). Evicts the oldest
  /// decryption key when the retention bound is exceeded.
  @override
  void addDecryptCipher(
    ICipher cipher, {
    IdType? startMessage,
    IdType? endMessage,
  }) =>
      _decryptCiphers.add(
        digestHex(cipher.keyId),
        cipher,
        startMessage: startMessage,
        endMessage: endMessage,
      );

  /// Removes the decryption cipher associated with key [id], if present.
  @override
  void removeDecryptCipher(Digest id) => _decryptCiphers.remove(digestHex(id));

  /// Removes the encryption cipher with key [id]. If it was current, the
  /// pointer falls back to the most recently registered remaining key.
  @override
  void removeEncryptCipher(Digest id) {
    _encryptCiphers.remove(digestHex(id));
    _repairPointer();
  }

  /// Purges expired ciphers from the encryption set.
  @override
  void clearOldEncryptCipher() => _cleanupExpiredEncryptCiphers();

  /// Applies the count-based retention bound to the decryption keys.
  /// Never evicts by wall clock (RFC section 7.4).
  @override
  void clearOldDecryptCipher() => _decryptCiphers.trim();

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
    _encryptCiphers.removeWhere((_, c) => isCipherExpired(c));
    _repairPointer();
  }
}
