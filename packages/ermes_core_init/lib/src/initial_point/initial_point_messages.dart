import 'package:singleton_manager/singleton_manager.dart';

import 'package:ermes_storage/ermes_storage.dart';

void initialPointErmesStorage(){

  SingletonDIAccess.addInstance<
      ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>(
    ErmesStorageAndCachingMessagesHandlerBaseMessageRoot(),
  );

  SingletonDIAccess.addInstance<
      ErmesStorageAndCachingMessagesHandlerBaseMessageType>(
    ErmesStorageAndCachingMessagesHandlerBaseMessageType(),
  );
}


ErmesStorageAndCachingMessagesHandlerBaseMessageRoot
    getErmesStorageAndCachingMessagesHandlerBaseMessageRoot() =>
        SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageRoot>();

ErmesStorageAndCachingMessagesHandlerBaseMessageType
    getErmesStorageAndCachingMessagesHandlerBaseMessageType() =>
        SingletonDIAccess
            .get<ErmesStorageAndCachingMessagesHandlerBaseMessageType>();
