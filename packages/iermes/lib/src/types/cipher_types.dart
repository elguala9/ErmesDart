import 'dart:typed_data';


import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';



class KeyInfo {
  KeyInfo(this.key, this.start, this.expiration, this.alg);
  String key;
  DateTime start;
  DateTime expiration;
  CryptoAlgorithm alg;
}

class DataEncrypted {
  DataEncrypted(this.keyId, this.encryptedData);
  Digest keyId;
  Uint8List encryptedData;
}
