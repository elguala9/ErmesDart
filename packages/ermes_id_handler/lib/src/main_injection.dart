import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

import 'handlers/id_handler_repository.dart';
import 'handlers/id_handler_service.dart';
import 'storage/id_handler_storage_repository.dart';
import 'storage/id_handler_storage_service.dart';

/// Default directory the ID counter is persisted into.
const String defaultIdHandlerDataPath = './id_handler';

/// Connects the ermes_id_handler graph to [RegistryManager].
///
/// Every call is independent: registering under a different [key] never
/// overwrites a previous call, so several graphs can live side by side.
///
/// Mix this into your own class (or extend [ErmesIdHandlerInjector]) to hook
/// into the before/after steps, or override [registerAllSingletonsIdHandler]
/// entirely.
mixin MainInjectionIdHandlerMixin {
  /// Called right before anything is connected. Override to customize.
  void beforeRegisterAllSingletonsIdHandler({String key = 'default'}) {}

  /// Connects every ermes_id_handler singleton under [key].
  void registerAllSingletonsIdHandler({String key = 'default'}) {
    beforeRegisterAllSingletonsIdHandler(key: key);
    RegistryManager.instance
      ..connectInstance<IIdHandlerStorageRepository,
          IdHandlerStorageRepository>(
        () => IdHandlerStorageRepository.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IIdHandlerStorageService, IdHandlerStorageService>(
        () => IdHandlerStorageService.dependencyInjectionFactory(key: key),
        key: key,
      )
      ..connectInstance<IIdHandlerService, IdHandlerService>(
        () => IdHandlerService.dependencyInjectionFactory(key: key),
        key: key,
      );
    afterRegisterAllSingletonsIdHandler(key: key);
  }

  /// Called right after everything is connected. Override to customize.
  void afterRegisterAllSingletonsIdHandler({String key = 'default'}) {}

  /// Called right before the async variant connects anything.
  Future<void> beforeRegisterAllSingletonsIdHandlerAsync({
    String key = 'default',
  }) async {}

  /// Async twin of [registerAllSingletonsIdHandler], so this package composes
  /// with the injectors that genuinely need to await work.
  Future<void> registerAllSingletonsIdHandlerAsync({
    String key = 'default',
  }) async {
    await beforeRegisterAllSingletonsIdHandlerAsync(key: key);
    registerAllSingletonsIdHandler(key: key);
    await afterRegisterAllSingletonsIdHandlerAsync(key: key);
  }

  /// Called right after the async variant finishes connecting.
  Future<void> afterRegisterAllSingletonsIdHandlerAsync({
    String key = 'default',
  }) async {}
}

/// Ready-to-use injector for the ermes_id_handler stack.
///
/// On top of the classes carrying a generated `dependencyInjectionFactory`, it
/// supplies the two inputs that graph resolves but does not own: the work_db
/// instance behind the storage repository, and the in-memory ID repository
/// that actually generates the counters.
class ErmesIdHandlerInjector with MainInjectionIdHandlerMixin {
  /// Creates an injector persisting the counter under [dataPath].
  const ErmesIdHandlerInjector({
    this.dataPath = defaultIdHandlerDataPath,
    this.max,
    this.start,
  });

  /// Directory the work_db instance stores the ID counter in.
  final String dataPath;

  /// Maximum ID value handed out before the counter wraps to zero.
  final int? max;

  /// Initial counter value.
  final int? start;

  @override
  void beforeRegisterAllSingletonsIdHandler({String key = 'default'}) {
    RegistryManager.instance
      ..connectInstance<IWorkDbSync, ClientWorkDb>(
        () => WorkDbFactory().create(
          IoWorkDbFactoryInput(dataPath: dataPath),
        ),
        key: key,
      )
      ..connectInstance<IIdHandlerRepository, IdHandlerRepository>(
        _createRepository,
        key: key,
      );
  }

  IdHandlerRepository _createRepository() {
    final maxValue = max;
    final startValue = start;
    if (maxValue == null && startValue == null) {
      return IdHandlerRepository();
    }
    if (maxValue == null) {
      return IdHandlerRepository(start: startValue!);
    }
    if (startValue == null) {
      return IdHandlerRepository(max: maxValue);
    }
    return IdHandlerRepository(max: maxValue, start: startValue);
  }
}
