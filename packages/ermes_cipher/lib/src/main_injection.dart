import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'ermes_peer_cipher.dart';
import 'factories/ermes_cipher_factories.dart';
import 'key_exchange/ecdh_key_exchange_service.dart';
import 'key_exchange/ermes_peer_key_exchange.dart';

/// Connects the ermes_cipher graph to [RegistryManager].
///
/// Every call is independent: registering under a different [key] never
/// overwrites a previous call, so several graphs can live side by side.
mixin MainInjectionErmesCipherMixin {
  /// Called right before anything is connected. Override to customize.
  void beforeRegisterAllSingletonsErmesCipher({String key = 'default'}) {}

  /// Connects every ermes_cipher singleton under [key].
  void registerAllSingletonsErmesCipher({String key = 'default'}) {
    beforeRegisterAllSingletonsErmesCipher(key: key);
    RegistryManager.instance
      ..connectInstance<IErmesPeerCipher, ErmesPeerCipher>(
        () => ErmesPeerCipher.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IErmesPeerKeyExchange, ErmesPeerKeyExchange>(
        () => ErmesPeerKeyExchange.dependencyInjectionFactory(key: key),
        key: key,
      );
    afterRegisterAllSingletonsErmesCipher(key: key);
  }

  /// Called right after everything is connected. Override to customize.
  void afterRegisterAllSingletonsErmesCipher({String key = 'default'}) {}

  /// Called right before the async variant connects anything.
  Future<void> beforeRegisterAllSingletonsErmesCipherAsync({
    String key = 'default',
  }) async {}

  /// Async twin of [registerAllSingletonsErmesCipher] — required when the
  /// default ECDH key pair has to be generated, which is asynchronous.
  Future<void> registerAllSingletonsErmesCipherAsync({
    String key = 'default',
  }) async {
    await beforeRegisterAllSingletonsErmesCipherAsync(key: key);
    registerAllSingletonsErmesCipher(key: key);
    await afterRegisterAllSingletonsErmesCipherAsync(key: key);
  }

  /// Called right after the async variant finishes connecting.
  Future<void> afterRegisterAllSingletonsErmesCipherAsync({
    String key = 'default',
  }) async {}
}

/// Ready-to-use injector for the ermes_cipher stack.
///
/// On top of the classes carrying a generated `dependencyInjectionFactory`, it
/// supplies the two inputs that graph resolves but does not own: this peer's
/// [IKeyExchange] key pair and the symmetric algorithm ciphers are derived
/// with.
///
/// Use [registerAllSingletonsErmesCipherAsync] — the sync variant cannot
/// generate the default key pair.
class ErmesCipherInjector with MainInjectionErmesCipherMixin {
  /// Creates an injector, optionally reusing an existing [keyExchange] key
  /// pair and overriding the [symmetricAlgorithm].
  const ErmesCipherInjector({
    this.keyExchange,
    this.symmetricAlgorithm,
  });

  /// This peer's key pair. A fresh P-256 ECDH pair is generated when null.
  final IKeyExchange? keyExchange;

  /// Symmetric algorithm ciphers are derived with; defaults to AES.
  final CryptoAlgorithm? symmetricAlgorithm;

  @override
  Future<void> beforeRegisterAllSingletonsErmesCipherAsync({
    String key = 'default',
  }) async {
    final exchange =
        keyExchange ?? await ECDHKeyExchangeService.generateNewService();
    RegistryManager.instance
      ..setInstance<CryptoAlgorithm>(
        symmetricAlgorithm ?? defaultSymmetricValue,
        key: key,
      )
      ..setInstance<IKeyExchange>(exchange, key: key);
  }
}
