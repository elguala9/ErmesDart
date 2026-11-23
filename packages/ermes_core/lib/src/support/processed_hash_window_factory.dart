import 'processed_hash_window.dart';

/// Input for [ProcessedHashWindowFactory.create].
class ProcessedHashWindowInput {
  /// Creates the input; null fields fall back to the RFC defaults.
  const ProcessedHashWindowInput({this.retention, this.nowMs});

  /// How long a processed hash is remembered (default 3600 s, RFC 10.2).
  final Duration? retention;

  /// Clock in ms since epoch (default wall clock).
  final int Function()? nowMs;
}

/// Factory for [ProcessedHashWindow] instances.
class ProcessedHashWindowFactory {
  ProcessedHashWindowFactory._();

  /// Creates a fresh, empty window.
  static ProcessedHashWindow create(ProcessedHashWindowInput input) =>
      ProcessedHashWindow(retention: input.retention, nowMs: input.nowMs);
}
