import 'dart:typed_data';


import 'package:cryptdart/interfaces/i_cipher.dart';
import 'package:crypto/crypto.dart';

import '../types/common/cipher_types.dart';


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

  void addEncryptCipher(ICipher cipher);
  void addDecryptCipher(ICipher cipher);

  void removeDecryptCipher(Digest id);
  void removeEncryptCipher(Digest id);
  void clearOldEncryptCipher();
  void clearOldDecryptCipher();

}
