import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../ermes_cipher.dart';



/// Singleton handler per gestire le istanze di ErmesPeerCipher.
/// Estende GenericObjectManager per fornire un mapping
/// peerId -> ErmesPeerCipher
@includeInBarrelFile
class ErmesPeerCipherHandler
    extends GenericObjectManager<String, ErmesPeerCipher> {

  /// Ottiene l'istanza singleton
  factory ErmesPeerCipherHandler() => _instance;

  ErmesPeerCipherHandler._();
  static final ErmesPeerCipherHandler _instance =
      ErmesPeerCipherHandler._();
}
