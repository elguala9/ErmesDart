/// Eviction ordering used by the cache: last-in-first-out or
/// first-in-first-out.
enum CachingMode { lifo, fifo }

/// Configuration options for the caching service.
class ErmesCachingServiceOptions {
  /// Creates options with a maximum cache size and eviction mode.
  ErmesCachingServiceOptions({
    required this.maxNumberOfElementCached,
    required this.cachingMode,
  });

  /// Maximum number of elements retained in the cache.
  final int maxNumberOfElementCached;
  /// Eviction mode applied when the cache is full.
  final CachingMode cachingMode;

  /// Returns a copy of these options overriding the given fields.
  ErmesCachingServiceOptions copyWith({
    int? maxNumberOfElementCached,
    CachingMode? cachingMode,
  }) => ErmesCachingServiceOptions(
    maxNumberOfElementCached:
        maxNumberOfElementCached ?? this.maxNumberOfElementCached,
    cachingMode: cachingMode ?? this.cachingMode,
  );
}
