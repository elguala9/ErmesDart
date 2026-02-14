import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:iermes/src/encryption/i_ermes_crypt_collection.dart';
import 'package:iermes/src/encryption/i_ermes_peer_cipher.dart';

import '../ermes_crypt_collection.dart';
import '../ermes_peer_cipher.dart';

/// Creates an ErmesPeerCipher instance with the specified algorithm
/// and optional initial keys.
@includeInBarrelFile
IErmesPeerCipher createErmesPeerCipher({
  required CryptoAlgorithm algorithm,
  List<KeyInfo>? initialKeys,
}) =>
    ErmesPeerCipher(
      algorithm: algorithm,
      initialKeys: initialKeys,
    );

/// Creates an ErmesCryptCollection for managing encrypt/decrypt instances
@includeInBarrelFile
IErmesCryptCollection createErmesCryptCollection(
  CryptoAlgorithm defaultAlgorithm,
) =>
    ErmesCryptCollection(defaultAlgorithm);
