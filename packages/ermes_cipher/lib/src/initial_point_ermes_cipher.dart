import 'package:cryptdart/types/crypto_algorithm.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'generated/ecdh_key_exchange_service_di.dart';
import 'generated/ermes_peer_cipher_di.dart';
import 'generated/ermes_peer_key_exchange_di.dart';

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

  final service = ECDHKeyExchangeServiceDI.initializeWithParametersDI(
    SymmetricAlgorithm.aes,
  );
  SingletonDIAccess
      .addInstanceAs<IECDHKeyExchangeService, ECDHKeyExchangeServiceDI>(
    service,
  );
}
