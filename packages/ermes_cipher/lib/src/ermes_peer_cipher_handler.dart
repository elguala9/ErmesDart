
import 'package:iermes/iermes.dart';

import '../ermes_cipher.dart';



/// Singleton handler per gestire le istanze di ErmesPeerCipher.
/// Estende GenericObjectManager per fornire un mapping
/// peerId -> ErmesPeerCipher

class ErmesPeerCipherHandler
    extends GenericObjectManager<String, ErmesPeerCipher> {

  /// Ottiene l'istanza singleton
  factory ErmesPeerCipherHandler() => _instance;

  /// Private constructor enforcing the singleton pattern.
  ErmesPeerCipherHandler._();
  /// The single shared instance of the handler.
  static final ErmesPeerCipherHandler _instance =
      ErmesPeerCipherHandler._();
}
