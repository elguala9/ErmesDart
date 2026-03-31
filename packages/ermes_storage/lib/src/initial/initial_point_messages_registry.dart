import 'package:singleton_manager/singleton_manager.dart';

import '../../ermes_storage.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  final T value;
  _Wrap(this.value);
}

/// Registry-based variant of initialPointErmesStorage.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
void initialPointErmesStorageRegistry({String key = 'default'}) {
  RegistryAccess.register<
      _Wrap<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>>(
    key,
    _Wrap(ErmesStorageAndCachingMessagesHandlerBaseMessageRoot()),
  );

  RegistryAccess.register<
      _Wrap<ErmesStorageAndCachingMessagesHandlerBaseMessageType>>(
    key,
    _Wrap(ErmesStorageAndCachingMessagesHandlerBaseMessageType()),
  );
}

/// Retrieve ErmesStorageAndCachingMessagesHandlerBaseMessageRoot from
/// registry by key.
ErmesStorageAndCachingMessagesHandlerBaseMessageRoot
    getErmesStorageAndCachingMessagesHandlerBaseMessageRootFromRegistry(
        {String key = 'default'}) =>
        RegistryAccess
            .getInstance<
                _Wrap<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>>(
              key,
            )
            .value;

/// Retrieve ErmesStorageAndCachingMessagesHandlerBaseMessageType from
/// registry by key.
ErmesStorageAndCachingMessagesHandlerBaseMessageType
    getErmesStorageAndCachingMessagesHandlerBaseMessageTypeFromRegistry(
        {String key = 'default'}) =>
        RegistryAccess
            .getInstance<
                _Wrap<ErmesStorageAndCachingMessagesHandlerBaseMessageType>>(
              key,
            )
            .value;
