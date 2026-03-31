import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

import '../../ermes_id_handler.dart';
import '../generated/id_handler_service_di.dart';
import '../generated/id_handler_storage_repository_di.dart';
import '../generated/id_handler_storage_service_di.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  final T value;
  _Wrap(this.value);
}

/// Registry-based variant of initialPointIdHandler.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
void initialPointIdHandlerRegistry({
  String key = 'default',
  String dataPath = './id_handler',
}) {
  final input = IoWorkDbFactoryInput(dataPath: dataPath);
  final db = WorkDbFactory().create(input);
  final repoStorage =
      IdHandlerStorageRepositoryDI.initializeWithParametersDI(db);
  RegistryAccess.register<_Wrap<IIdHandlerStorageRepository>>(
    key,
    _Wrap(repoStorage),
  );
  final serviceStorage = IdHandlerStorageServiceDI.initializeDI();
  RegistryAccess.register<_Wrap<IIdHandlerStorageService>>(
    key,
    _Wrap(serviceStorage),
  );
  final repo = IdHandlerRepository();
  RegistryAccess.register<_Wrap<IIdHandlerRepository>>(
    key,
    _Wrap(repo),
  );
  final service = IdHandlerServiceDI.initializeDI();
  RegistryAccess.register<_Wrap<IIdHandlerService>>(
    key,
    _Wrap(service),
  );
}

/// Retrieve IIdHandlerStorageRepository from registry by key.
IIdHandlerStorageRepository getIIdHandlerStorageRepositoryFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IIdHandlerStorageRepository>>(key).value;

/// Retrieve IIdHandlerStorageService from registry by key.
IIdHandlerStorageService getIIdHandlerStorageServiceFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IIdHandlerStorageService>>(key).value;

/// Retrieve IIdHandlerRepository from registry by key.
IIdHandlerRepository getIIdHandlerRepositoryFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IIdHandlerRepository>>(key).value;

/// Retrieve IIdHandlerService from registry by key.
IIdHandlerService getIIdHandlerServiceFromRegistry({String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IIdHandlerService>>(key).value;
