import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  _Wrap(this.value);
  final T value;
}

/// Registry-based variant of initialPointMessageControl.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
void initialPointMessageControlRegistry({String key = 'default'}) {
  final repo = ErmesMessageControlFactory.createRepository();
  RegistryAccess.register<_Wrap<IErmesMessageControlRepository>>(
    key,
    _Wrap(repo),
  );
  final service = ErmesMessageControlServiceDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesMessageControlService>>(
    key,
    _Wrap(service),
  );
}

/// Retrieve IErmesMessageControlService from registry by key.
IErmesMessageControlService getIErmesMessageControlServiceFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesMessageControlService>>(key).value;
