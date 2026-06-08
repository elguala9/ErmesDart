import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

Future<void> initialPointErmesCipher() async {
  final peerCipher = ErmesPeerCipherDI.initializeDI();
  SingletonDIAccess.addInstanceAs<IErmesPeerCipher, ErmesPeerCipherDI>(
    peerCipher,
  );

  final peerKeyExchage = ErmesPeerKeyExchangeDI.initializeDI();
  SingletonDIAccess
      .addInstanceAs<IErmesPeerKeyExchange, ErmesPeerKeyExchangeDI>(
    peerKeyExchage,
  );

  final keyExchange =
      await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
  SingletonDIAccess.addInstance<IKeyExchange>(keyExchange);
}
