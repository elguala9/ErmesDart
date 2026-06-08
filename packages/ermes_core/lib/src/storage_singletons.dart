import 'package:ermes_storage/ermes_storage.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Resolves the message-root storage/caching handler from the DI container.
///
/// The instance is registered by the init layer (`ermes_core_init`); this
/// accessor only *resolves* it, so `ermes_core` can reach the singleton
/// without depending on `ermes_core_init` (which would be a circular
/// dependency, since `ermes_core_init` depends on `ermes_core`).
ErmesStorageAndCachingMessagesHandlerBaseMessageRoot
    getErmesStorageAndCachingMessagesHandlerBaseMessageRoot() =>
        SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>();

/// Resolves the message-type storage/caching handler from the DI container.
///
/// See [getErmesStorageAndCachingMessagesHandlerBaseMessageRoot] for why this
/// resolution lives in `ermes_core` rather than `ermes_core_init`.
ErmesStorageAndCachingMessagesHandlerBaseMessageType
    getErmesStorageAndCachingMessagesHandlerBaseMessageType() =>
        SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageType>();
