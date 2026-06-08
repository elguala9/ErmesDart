import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';

import '../../iermes.dart';

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

class StorageSymmetricKeyType implements StorageType {
  factory StorageSymmetricKeyType({
    required DateTime expiration,
    required String key,
    required IdPeer idPeer
  }) =>
      StorageSymmetricKeyType._(
        expiration: expiration,
        key: key,
        idPeer: idPeer
      );

  factory StorageSymmetricKeyType.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('expiration')) {
      throw const FormatException('Missing required field: expiration');
    }
    if (!json.containsKey('key')) {
      throw const FormatException('Missing required field: key');
    }
    if (!json.containsKey('idPeer')) {
      throw const FormatException('Missing required field: idPeer');
    }

    return StorageSymmetricKeyType(
      expiration: DateTime.parse(json['expiration'] as String),
      key: json['key'] as String,
      idPeer: json['idPeer'] as String,
    );
  }

  StorageSymmetricKeyType._({
    required this.expiration,
    required this.key,
    required this.idPeer
  });

  final DateTime expiration;
  final String key;
  final IdPeer idPeer;

  @override
  IdType get id => int.parse(idPeer);

  @override
  Map<String, dynamic> toJson() => {
    'expiration': expiration.toIso8601String(),
    'key': key,
    'idPeer': idPeer,
  };

  @override
  Map<String, dynamic> get json => toJson();
}
