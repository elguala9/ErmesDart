import 'package:ermes_storage/ermes_storage.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Registers the message-root and message-type storage/caching handlers in
/// the singleton DI container.
///
/// Idempotent: each handler is only registered if not already present, so it
/// is safe to call from both test setup and [initialPointErmesCore] without
/// triggering a duplicate-registration error.
void initialPointErmesStorage(){

  if (!SingletonDIAccess
      .exists<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>()) {
    SingletonDIAccess.addInstance<
        ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(
      ErmesStorageAndCachingMessagesHandlerBaseMessageRoot(),
    );
  }

  if (!SingletonDIAccess
      .exists<ErmesStorageAndCachingMessagesHandlerBaseMessageType>()) {
    SingletonDIAccess.addInstance<
        ErmesStorageAndCachingMessagesHandlerBaseMessageType>(
      ErmesStorageAndCachingMessagesHandlerBaseMessageType(),
    );
  }
}


ErmesStorageAndCachingMessagesHandlerBaseMessageRoot
    getErmesStorageAndCachingMessagesHandlerBaseMessageRoot() =>
        SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>();

ErmesStorageAndCachingMessagesHandlerBaseMessageType
    getErmesStorageAndCachingMessagesHandlerBaseMessageType() =>
        SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageType>();
