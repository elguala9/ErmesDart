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
  /// Returns a List<int> decrypted
  List<int> decrypt(DataEncrypted data);

  /// Encrypt the data
  ///
  /// Returns a List<int> encrypted
  DataEncrypted encrypt(List<int> data);

  void addEncryptCipher(ICipher cipher);
  void addDecryptCipher(ICipher cipher);

  void removeDecryptCipher(Digest id);
  void removeEncryptCipher(Digest id);
  void clearOldEncryptCipher();
  void clearOldDecryptCipher();

}
