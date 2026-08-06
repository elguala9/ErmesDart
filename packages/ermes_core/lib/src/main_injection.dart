import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'ermes_connections_handler.dart';
import 'orc_ermes.dart';

/// Connects the ermes_core graph to [RegistryManager].
///
/// Every call is independent: registering under a different [key] never
/// overwrites a previous call, so several graphs can live side by side.
///
/// [OrcErmes] resolves the whole signaling stack plus the IPv4 SHSP socket, so
/// the ermes_signaling and stun_shsp graphs must already be registered under
/// the same [key]. It also resolves an optional `IKeyExchange`, without which
/// it falls back to running unencrypted.
mixin MainInjectionErmesCoreMixin {
  /// Called right before anything is connected. Override to customize.
  void beforeRegisterAllSingletonsErmesCore({String key = 'default'}) {}

  /// Connects every ermes_core singleton under [key].
  void registerAllSingletonsErmesCore({String key = 'default'}) {
    beforeRegisterAllSingletonsErmesCore(key: key);
    RegistryManager.instance
      // OrcErmes resolves the connections handler by its concrete type while
      // the rest of the stack asks for the interface. The interface entry
      // resolves the concrete one so both share a single handler.
      ..connectInstance<ErmesConnectionsHandler, ErmesConnectionsHandler>(
        () => ErmesConnectionsHandler.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IErmesConnectionsHandler, ErmesConnectionsHandler>(
        () => RegistryManager.instance
            .getInstance<ErmesConnectionsHandler>(key: key),
        key: key,
      )
      ..connectInstance<IOrcErmes<BookData>, OrcErmes>(
        () => OrcErmes.dependencyInjectionFactory(key: key),
        key: key,
      );
    afterRegisterAllSingletonsErmesCore(key: key);
  }

  /// Called right after everything is connected. Override to customize.
  void afterRegisterAllSingletonsErmesCore({String key = 'default'}) {}

  /// Called right before the async variant connects anything.
  Future<void> beforeRegisterAllSingletonsErmesCoreAsync({
    String key = 'default',
  }) async {}

  /// Async twin of [registerAllSingletonsErmesCore], so this package composes
  /// with the injectors that genuinely need to await work.
  Future<void> registerAllSingletonsErmesCoreAsync({
    String key = 'default',
  }) async {
    await beforeRegisterAllSingletonsErmesCoreAsync(key: key);
    registerAllSingletonsErmesCore(key: key);
    await afterRegisterAllSingletonsErmesCoreAsync(key: key);
  }

  /// Called right after the async variant finishes connecting.
  Future<void> afterRegisterAllSingletonsErmesCoreAsync({
    String key = 'default',
  }) async {}
}

/// Ready-to-use injector for the ermes_core stack.
///
/// ermes_core owns no external inputs of its own — everything [OrcErmes] needs
/// comes from the signaling, cipher and STUN/SHSP graphs — so this is the bare
/// mixin host. Compose it with those injectors (see `ermes_core_init`) rather
/// than using it alone.
class ErmesCoreInjector with MainInjectionErmesCoreMixin {
  /// Creates the injector.
  const ErmesCoreInjector();
}
