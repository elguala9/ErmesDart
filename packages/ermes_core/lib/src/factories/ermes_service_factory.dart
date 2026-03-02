
import 'package:iermes/iermes.dart';

import '../ermes_service.dart';

/// 9️⃣ Factory per ErmesService
/// Tradotto da: ErmesServiceFactory.ts

class ErmesServiceFactory {
  ErmesServiceFactory._();

  
  static ErmesService createService(
    int? maxBuffer,
    int? maxByte,
    IErmesRepository repository,
    IIdHandlerService idHandler,
    CallbackOnDataArrived? callbackOnDataArrived,
    IErmesStorageAndCaching<MessageType>? ermesStorageAndCaching,
    IErmesMessageControlService? ermesMessageControlService,
    int? missingMessagesCheckIntervalMs,
    int? missingMessagesThreshold,
  ) => ErmesService(
    maxBuffer: maxBuffer,
    maxByte: maxByte,
    repository: repository,
    idHandler: idHandler,
    callbackOnDataArrived: callbackOnDataArrived,
    ermesMessageControlService: ermesMessageControlService,
    missingMessagesCheckIntervalMs: missingMessagesCheckIntervalMs,
    missingMessagesThreshold: missingMessagesThreshold,
  );
}
