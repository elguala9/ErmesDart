import 'package:ermes_storage/ermes_storage.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Registers the message-root and message-type storage/caching handlers.
///
/// `ErmesSendRepo` and `ErmesReadRepo` resolve these at `openConnection` time
/// through `ermes_core`'s `getErmesStorageAndCachingMessagesHandlerBase*`
/// accessors.
///
/// Idempotent: each handler is only registered when absent, so it is safe to
/// call from both test setup and [ErmesInjector] without clobbering an instance
/// a test already put in place.
void registerErmesStorageHandlers({String key = 'default'}) {
  final registry = RegistryManager.instance;

  if (registry.getInstanceNullable<
      ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(key: key) == null) {
    registry.setInstance<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(
      ErmesStorageAndCachingMessagesHandlerBaseMessageRoot(),
      key: key,
    );
  }

  if (registry.getInstanceNullable<
      ErmesStorageAndCachingMessagesHandlerBaseMessageType>(key: key) == null) {
    registry.setInstance<ErmesStorageAndCachingMessagesHandlerBaseMessageType>(
      ErmesStorageAndCachingMessagesHandlerBaseMessageType(),
      key: key,
    );
  }
}
