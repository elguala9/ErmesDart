import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  _Wrap(this.value);
  final T value;
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

  final keyExchange =
      await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
  RegistryAccess.register<_Wrap<IKeyExchange>>(
    key,
    _Wrap<IKeyExchange>(keyExchange),
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
