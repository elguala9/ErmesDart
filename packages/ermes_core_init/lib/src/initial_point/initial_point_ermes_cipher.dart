import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

void initialPointErmesCipher() {
  final peerCipher = ErmesPeerCipherDI.initializeDI();
  SingletonDIAccess.addInstanceAs<IErmesPeerCipher, ErmesPeerCipherDI>(
    peerCipher,
  );

  final peerKeyExchage = ErmesPeerKeyExchangeDI.initializeDI();
  SingletonDIAccess
      .addInstanceAs<IErmesPeerKeyExchange, ErmesPeerKeyExchangeDI>(
    peerKeyExchage,
  );
}
