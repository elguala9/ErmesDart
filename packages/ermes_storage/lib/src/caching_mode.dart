enum CachingMode { lifo, fifo }

class ErmesCachingServiceOptions {
  ErmesCachingServiceOptions({
    required this.maxNumberOfElementCached,
    required this.cachingMode,
  });

  final int maxNumberOfElementCached;
  final CachingMode cachingMode;

  ErmesCachingServiceOptions copyWith({
    int? maxNumberOfElementCached,
    CachingMode? cachingMode,
  }) => ErmesCachingServiceOptions(
    maxNumberOfElementCached:
        maxNumberOfElementCached ?? this.maxNumberOfElementCached,
    cachingMode: cachingMode ?? this.cachingMode,
  );
}
