import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import '../ermes_service.dart';

/// 9️⃣ Factory per ErmesService
/// Tradotto da: ErmesServiceFactory.ts
@includeInBarrelFile
class ErmesServiceFactory {
  ErmesServiceFactory._();

  @includeInBarrelFile
  static ErmesService createService(
    int? maxBuffer,
    int? maxByte,
    IErmesRepository repository,
    IIdHandlerService idHandler,
    CallbackOnDataArrived? callbackOnDataArrived,
    IErmesStorageAndCaching? ermesStorageAndCaching,
    IErmesMessageControlService? ermesMessageControlService,
    int? missingMessagesCheckIntervalMs,
    int? missingMessagesThreshold,
  ) => ErmesService(
    maxBuffer: maxBuffer,
    maxByte: maxByte,
    repository: repository,
    idHandler: idHandler,
    callbackOnDataArrived: callbackOnDataArrived,
    ermesStorageAndCaching: ermesStorageAndCaching,
    ermesMessageControlService: ermesMessageControlService,
    missingMessagesCheckIntervalMs: missingMessagesCheckIntervalMs,
    missingMessagesThreshold: missingMessagesThreshold,
  );
}
