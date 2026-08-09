import 'package:iermes/iermes.dart';

/// Cache used to deduplicate incoming messages by their integrity hash.
typedef ErmesDeduplicationCache = IGenericCachingRepository<String, bool>;

/// Configuration for `ErmesReadRepo`.
class ErmesReadRepoOptions {
  /// Creates read-repository options with optional buffer/size limits and
  /// processing callbacks.
  const ErmesReadRepoOptions({
    this.maxBufferSize,
    this.maxMessageSize,
    this.callbackOnDataArrived,
    this.callbackOnMessageProcessed,
  });

  /// Maximum number of buffered not-yet-read messages.
  final int? maxBufferSize;
  /// Maximum allowed reassembled message size.
  final int? maxMessageSize;
  /// Callback invoked when application data arrives.
  final CallbackOnDataArrived? callbackOnDataArrived;
  /// Callback awaited after each message is processed.
  final Future<void> Function()? callbackOnMessageProcessed;
}
