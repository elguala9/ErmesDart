import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';

import '../../iermes.dart';

/// Holds a cryptographic key together with its validity window and algorithm.
class KeyInfo {
  /// Creates key information with its validity window and algorithm.
  KeyInfo(this.key, this.start, this.expiration, this.alg);
  /// The key material as a string.
  String key;
  /// Moment from which the key becomes valid.
  DateTime start;
  /// Moment at which the key expires.
  DateTime expiration;
  /// Algorithm this key is intended for.
  CryptoAlgorithm alg;
}

/// Pairs encrypted payload bytes with the identifier of the key used.
class DataEncrypted {
  /// Creates an encrypted data container.
  DataEncrypted(this.keyId, this.encryptedData);
  /// Digest identifying the key used for encryption.
  Digest keyId;
  /// The resulting encrypted bytes.
  Uint8List encryptedData;
}

/// Persistable symmetric key entry associated with a peer.
class StorageSymmetricKeyType implements StorageType {
  /// Creates a storable symmetric key entry for a peer.
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

  /// Rebuilds an entry from its JSON representation, validating required fields.
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

  /// Moment at which the stored key expires.
  final DateTime expiration;
  /// The stored key material.
  final String key;
  /// Identifier of the peer this key belongs to.
  final IdPeer idPeer;

  /// Storage identifier derived from the peer id.
  @override
  IdType get id => int.parse(idPeer);

  /// Serializes this entry to its JSON representation.
  @override
  Map<String, dynamic> toJson() => {
    'expiration': expiration.toIso8601String(),
    'key': key,
    'idPeer': idPeer,
  };

  /// JSON view of this entry, equivalent to [toJson].
  @override
  Map<String, dynamic> get json => toJson();
}
