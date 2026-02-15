import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:crypto/crypto.dart';

class KeyInfo {
  KeyInfo(this.key, this.start, this.expiration);
  String key;
  DateTime start;
  DateTime expiration;
}

@includeInBarrelFile
class DataEncrypted {
  DataEncrypted(this.keyId, this.encryptedData);
  Digest keyId;
  List<int> encryptedData;
}
