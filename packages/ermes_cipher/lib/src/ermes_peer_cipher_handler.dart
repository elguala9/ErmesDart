import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';
import 'package:iermes/iermes.dart';

import '../ermes_cipher.dart';
import 'exceptions.dart';



/// Singleton handler per gestire le istanze di ErmesPeerCipher.
/// Estende GenericObjectManager per fornire un mapping peerId -> ErmesPeerCipher
@includeInBarrelFile
class ErmesPeerCipherHandler
    extends GenericObjectManager<String, ErmesPeerCipher> {
  static final ErmesPeerCipherHandler _instance =
      ErmesPeerCipherHandler._();

  ErmesPeerCipherHandler._();

  /// Ottiene l'istanza singleton
  factory ErmesPeerCipherHandler() => _instance;
}
