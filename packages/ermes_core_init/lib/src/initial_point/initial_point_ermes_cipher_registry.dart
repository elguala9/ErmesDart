import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'package:ermes_cipher/src/generated/ecdh_key_exchange_service_di.dart';
import 'package:ermes_cipher/src/generated/ermes_peer_cipher_di.dart';
import 'package:ermes_cipher/src/generated/ermes_peer_key_exchange_di.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  final T value;
  _Wrap(this.value);
}

/// Registry-based variant of initialPointErmesCipher.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
Future<void> initialPointErmesCipherRegistry({String key = 'default'}) async {
  final peerCipher = ErmesPeerCipherDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesPeerCipher>>(
    key,
    _Wrap(peerCipher),
  );

  final peerKeyExchange = ErmesPeerKeyExchangeDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesPeerKeyExchange>>(
    key,
    _Wrap(peerKeyExchange),
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
  RegistryAccess.register<_Wrap<IKeyExchange>>(
    key,
    _Wrap(keyExchange),
  );

  final service = ECDHKeyExchangeServiceDI.initializeWithParametersDI(
    SymmetricAlgorithm.aes,
  );
  RegistryAccess.register<_Wrap<IECDHKeyExchangeService>>(
    key,
    _Wrap(service),
  );
}

/// Retrieve IErmesPeerCipher from registry by key.
IErmesPeerCipher getIErmesPeerCipherFromRegistry({String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesPeerCipher>>(key).value;

/// Retrieve IErmesPeerKeyExchange from registry by key.
IErmesPeerKeyExchange getIErmesPeerKeyExchangeFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesPeerKeyExchange>>(key).value;

/// Retrieve IKeyExchange from registry by key.
IKeyExchange getIKeyExchangeFromRegistry({String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IKeyExchange>>(key).value;

/// Retrieve IECDHKeyExchangeService from registry by key.
IECDHKeyExchangeService getIECDHKeyExchangeServiceFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IECDHKeyExchangeService>>(key).value;
