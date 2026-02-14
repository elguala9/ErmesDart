import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/interfaces/i_cipher.dart';


// The encrypt and decrypt instance for a single peer
// the implementaion should store the keys
@includeInBarrelFile
abstract class IErmesPeerCipher {
  /// Decrypt the data
  ///
  /// Returns a List<int> decrypted
  List<int> decrypt(List<int> data);

  /// Encrypt the data
  ///
  /// Returns a List<int> encrypted
  List<int> encrypt(List<int> data);

  void addCipher(ICipher cipher);

}
