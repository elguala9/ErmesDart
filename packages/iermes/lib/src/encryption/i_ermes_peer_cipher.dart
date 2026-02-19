import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/interfaces/i_cipher.dart';
import 'package:crypto/crypto.dart';

import '../types/cipher_types.dart';


// The encrypt and decrypt instance for a single peer
// the implementaion should store the keys
@includeInBarrelFile
abstract class IErmesPeerCipher {
  /// Decrypt the data
  ///
  /// Returns decrypted Uint8List
  Uint8List decrypt(DataEncrypted data);

  /// Encrypt the data
  ///
  /// Returns encrypted data as DataEncrypted
  DataEncrypted encrypt(Uint8List data);

  void addEncryptCipher(ICipher cipher);
  void addDecryptCipher(ICipher cipher);

  void removeDecryptCipher(Digest id);
  void removeEncryptCipher(Digest id);
  void clearOldEncryptCipher();
  void clearOldDecryptCipher();

}
