
import 'package:iermes/iermes.dart';

/// Repository in-memoria con capacità massima e politica FIFO/LIFO

class ErmesCachingRepository<D extends StorageType>
    extends IErmesCachingRepository<D> {
  /// Creates a caching repository holding at most [maxBuffer] elements.
  ErmesCachingRepository(this.maxBuffer);
  final Map<IdType, D> _buffer = {};
  /// Maximum number of elements retained before the oldest is evicted.
  final int maxBuffer;

  /// Stores [data], updating an existing entry and evicting the oldest if full.
  @override
  Future<void> store(D data) async {
    final id = _extractId(data);

    // Se l'elemento esiste già, lo togliamo per reinserirlo (aggiornamento)
    if (_buffer.containsKey(id)) {
      _buffer.remove(id);
    }

    _buffer[id] = data;

    // Se superiamo la capacità, rimuoviamo il più vecchio
    if (numberOfElements() > maxBuffer) {
      final oldestKey = _buffer.keys.first;
      _buffer.remove(oldestKey);
    }
  }

  /// Returns the cached element for [id], or null if absent.
  @override
  Future<D?> retrieve(IdType id) async => _buffer[id];

  /// Removes the element for [id], returning true if one was present.
  @override
  Future<bool> delete(IdType id) async => _buffer.remove(id) != null;

  /// Removes all cached elements.
  @override
  Future<void> clear() async {
    _buffer.clear();
  }

  /// Returns the number of cached elements.
  @override
  int numberOfElements() => _buffer.length;

  /// Returns the IDs of all cached elements.
  @override
  Future<List<IdType>> listOfIds() async =>
      _buffer.keys.toList();

  /// Extract ID from StorageType
  IdType _extractId(D data) => data.id;

  /// Releases the repository, clearing all cached elements.
  @override
  Future<void> destroy() async {
    await clear();
  }
}
