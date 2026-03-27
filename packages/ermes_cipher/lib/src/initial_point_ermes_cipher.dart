import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'generated/ecdh_key_exchange_service_di.dart';
import 'generated/ermes_peer_cipher_di.dart';
import 'generated/ermes_peer_key_exchange_di.dart';

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

  // Generate a key pair and register it as IKeyExchange before DI injection
  final keyPair = await ECDHKeyExchange.generateKeyPair();
  final keyExchange = ECDHKeyExchange(
    InputECDHKeyExchange(
      parent: InputKeyExchangeBase(
        algorithm: KeyExchangeAlgorithm.ecdh,
        expirationDate: DateTime.now().add(const Duration(hours: 24)),
      ),
      publicKey: keyPair['publicKey']!,
      privateKey: keyPair['privateKey']!,
      curve: ECCKeyUtils.secp256r1,
    ),
  );
  SingletonDIAccess.addInstanceAs<IKeyExchange, ECDHKeyExchange>(keyExchange);

  final service = ECDHKeyExchangeServiceDI.initializeWithParametersDI(
    SymmetricAlgorithm.aes,
  );
  SingletonDIAccess
      .addInstanceAs<IECDHKeyExchangeService, ECDHKeyExchangeServiceDI>(
    service,
  );
}
