import 'dart:typed_data';


import 'package:cryptdart/interfaces/i_cipher.dart';
import 'package:crypto/crypto.dart';

import '../types/common/cipher_types.dart';
import '../types/common/type_aliases.dart';


// The encrypt and decrypt instance for a single peer
// the implementaion should store the keys
abstract class IErmesPeerCipher {
  /// Decrypt the data
  ///
  /// Returns decrypted Uint8List
  Uint8List decrypt(DataEncrypted data);

  /// Encrypt the data
  ///
  /// Returns encrypted data as DataEncrypted
  DataEncrypted encrypt(Uint8List data);

  /// Whether at least one non-expired encryption cipher is registered, i.e.
  /// [encrypt] would succeed. Lets the send path fall back to plaintext while a
  /// peer link has only a decrypt cipher (e.g. mid ECDH handshake, or right
  /// after a peer's `newKey` is registered for decryption but no encrypt key is
  /// set yet).
  bool get hasEncryptCipher;

  /// Registers [cipher] as an outbound key. When [makeCurrent] is true
  /// (default) it also becomes the current outbound key used by [encrypt].
  /// Registering with `makeCurrent: false` keeps the current key unchanged,
  /// so a rotated-in key can be prepared before its `newkey` is delivered.
  void addEncryptCipher(ICipher cipher, {bool makeCurrent = true});

  /// Moves the current outbound key pointer to the registered key [id].
  /// Throws when no encrypt cipher with that id is registered.
  void setCurrentEncryptCipher(Digest id);

  /// Key id of the current outbound key. Throws when none is set.
  Digest get currentEncryptKeyId;

  /// Registers [cipher] for decryption, valid for inner message ids in
  /// [[startMessage], [endMessage]] (RFC section 7.4). A null bound is
  /// open-ended, so keys registered without bounds (initial ECDH key, legacy
  /// peers) accept any id.
  void addDecryptCipher(
    ICipher cipher, {
    IdType? startMessage,
    IdType? endMessage,
  });

  /// Whether [messageId] lies within the bounds of decrypt key [keyId].
  /// Throws when no decrypt key with that id is registered.
  bool isIdInKeyBounds(Digest keyId, IdType messageId);

  void removeDecryptCipher(Digest id);
  void removeEncryptCipher(Digest id);
  void clearOldEncryptCipher();
  /// Applies the retention bound to decryption keys (keeps the most recent
  /// ones, evicting the oldest). Never evicts by wall clock: `start` and
  /// `expiration` are advisory on the receiver (RFC section 7.4).
  void clearOldDecryptCipher();

}
