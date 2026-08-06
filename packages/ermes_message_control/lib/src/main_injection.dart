import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'ermes_message_control_repository.dart';
import 'ermes_message_control_service.dart';

/// Connects the ermes_message_control graph to [RegistryManager].
///
/// Every call is independent: registering under a different [key] never
/// overwrites a previous call, so several graphs can live side by side.
mixin MainInjectionMessageControlMixin {
  /// Called right before anything is connected. Override to customize.
  void beforeRegisterAllSingletonsMessageControl({String key = 'default'}) {}

  /// Connects every ermes_message_control singleton under [key].
  void registerAllSingletonsMessageControl({String key = 'default'}) {
    beforeRegisterAllSingletonsMessageControl(key: key);
    RegistryManager.instance.connectInstance<IErmesMessageControlService,
        ErmesMessageControlService>(
      () => ErmesMessageControlService.dependencyInjectionFactory(key: key),
      key: key,
    );
    afterRegisterAllSingletonsMessageControl(key: key);
  }

  /// Called right after everything is connected. Override to customize.
  void afterRegisterAllSingletonsMessageControl({String key = 'default'}) {}

  /// Called right before the async variant connects anything.
  Future<void> beforeRegisterAllSingletonsMessageControlAsync({
    String key = 'default',
  }) async {}

  /// Async twin of [registerAllSingletonsMessageControl], so this package
  /// composes with the injectors that genuinely need to await work.
  Future<void> registerAllSingletonsMessageControlAsync({
    String key = 'default',
  }) async {
    await beforeRegisterAllSingletonsMessageControlAsync(key: key);
    registerAllSingletonsMessageControl(key: key);
    await afterRegisterAllSingletonsMessageControlAsync(key: key);
  }

  /// Called right after the async variant finishes connecting.
  Future<void> afterRegisterAllSingletonsMessageControlAsync({
    String key = 'default',
  }) async {}
}

/// Ready-to-use injector for the ermes_message_control stack.
///
/// On top of the service carrying a generated `dependencyInjectionFactory`, it
/// supplies the repository that service tracks state in, and optionally the
/// options controlling how often that state is persisted.
class ErmesMessageControlInjector with MainInjectionMessageControlMixin {
  /// Creates an injector, optionally overriding how many ID-change events pass
  /// between automatic save-state calls.
  const ErmesMessageControlInjector({this.frequencyIdSaveState});

  /// Number of ID-change events between automatic state saves.
  final int? frequencyIdSaveState;

  @override
  void beforeRegisterAllSingletonsMessageControl({String key = 'default'}) {
    final registry = RegistryManager.instance
      ..connectInstance<IErmesMessageControlRepository,
          ErmesMessageControlRepository>(
        ErmesMessageControlRepository.new,
        key: key,
      );

    final frequency = frequencyIdSaveState;
    if (frequency != null) {
      registry.setInstance<ErmesMessageControlServiceOpts>(
        ErmesMessageControlServiceOpts(frequencyIdSaveState: frequency),
        key: key,
      );
    }
  }
}
