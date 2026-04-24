import 'package:ermes_storage/ermes_storage.dart';
import 'package:singleton_manager/singleton_manager.dart';

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
