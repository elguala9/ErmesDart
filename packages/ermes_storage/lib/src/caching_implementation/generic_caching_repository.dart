import 'package:iermes/iermes.dart';

/// In-memory cache repository keyed by an arbitrary ID and data type, evicting
/// the oldest entry when the maximum buffer size is exceeded.
class GenericCachingRepository<TId, TData>
    implements IGenericCachingRepository<TId, TData> {
  /// Creates a repository holding at most [maxBuffer] elements.
  GenericCachingRepository([this.maxBuffer = 1000]);

  /// Maximum number of elements retained before the oldest is evicted.
  final int maxBuffer;
  final Map<TId, TData> _buffer = {};

  /// Stores [data] under [id], evicting the oldest entry if the buffer is full.
  @override
  Future<void> store(TId id, TData data) async {
    _buffer.remove(id);
    _buffer[id] = data;
    if (_buffer.length > maxBuffer) {
      _buffer.remove(_buffer.keys.first);
    }
  }

  /// Returns the element stored under [id], or null if absent.
  @override
  Future<TData?> retrieve(TId id) async => _buffer[id];

  /// Removes the element under [id], returning true if one was present.
  @override
  Future<bool> delete(TId id) async => _buffer.remove(id) != null;

  /// Removes all cached elements.
  @override
  Future<void> clear() async => _buffer.clear();

  /// Returns the number of cached elements.
  @override
  int numberOfElements() => _buffer.length;

  /// Returns the IDs of all cached elements.
  @override
  Future<List<TId>> listOfIds() async => _buffer.keys.toList();

  /// Releases the repository, clearing all cached elements.
  @override
  Future<void> destroy() async => _buffer.clear();
}
