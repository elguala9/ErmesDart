
import 'package:iermes/iermes.dart';

import 'ermes_service.dart';
import 'ermes_service_versioning.dart';

/// Factory per ErmesService
/// Tradotto da: ErmesServiceFactory.ts

/// Factory for creating [ErmesService] instances.
class ErmesServiceFactory {
  /// Private constructor to prevent instantiation.
  ErmesServiceFactory._();

  /// Creates an [ErmesService] wiring buffering, transport, ID generation,
  /// storage, and optional missing-message control parameters. A non-null
  /// [versionNegotiation] enables RFC 7.1 version negotiation.
  static ErmesService createService(
    int? maxBuffer,
    int? maxByte,
    IErmesRepository repository,
    IIdHandlerService idHandler,
    CallbackOnDataArrived? callbackOnDataArrived,
    IErmesStorageAndCaching<MessageType>? ermesStorageAndCaching,
    IErmesMessageControlService? ermesMessageControlService,
    int? missingMessagesCheckIntervalMs,
    int? missingMessagesThreshold, {
    ErmesVersionNegotiationOptions? versionNegotiation,
  }) => ErmesService(
    maxBuffer: maxBuffer,
    maxByte: maxByte,
    repository: repository,
    idHandler: idHandler,
    callbackOnDataArrived: callbackOnDataArrived,
    ermesMessageControlService: ermesMessageControlService,
    missingMessagesCheckIntervalMs: missingMessagesCheckIntervalMs,
    missingMessagesThreshold: missingMessagesThreshold,
    versionNegotiation: versionNegotiation,
  );
}
