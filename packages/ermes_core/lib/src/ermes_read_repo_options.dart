import 'package:iermes/iermes.dart';

/// Cache used to deduplicate incoming messages by their integrity hash.
typedef ErmesDeduplicationCache = IGenericCachingRepository<String, bool>;

/// Configuration for `ErmesReadRepo`.
class ErmesReadRepoOptions {
  const ErmesReadRepoOptions({
    this.maxBufferSize,
    this.maxMessageSize,
    this.callbackOnDataArrived,
    this.callbackOnMessageProcessed,
  });

  final int? maxBufferSize;
  final int? maxMessageSize;
  final CallbackOnDataArrived? callbackOnDataArrived;
  final Future<void> Function()? callbackOnMessageProcessed;
}
