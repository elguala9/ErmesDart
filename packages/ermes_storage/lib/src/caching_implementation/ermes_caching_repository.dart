
import 'package:iermes/iermes.dart';

/// Repository in-memoria con capacità massima e politica FIFO/LIFO

class ErmesCachingRepository<D extends StorageType>
    extends IErmesCachingRepository<D> {
  ErmesCachingRepository(this.maxBuffer);
  final Map<IdType, D> _buffer = {};
  final int maxBuffer;

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

  @override
  Future<D?> retrieve(IdType id) async => _buffer[id];

  @override
  Future<bool> delete(IdType id) async => _buffer.remove(id) != null;

  @override
  Future<void> clear() async {
    _buffer.clear();
  }

  @override
  int numberOfElements() => _buffer.length;

  @override
  Future<List<IdType>> listOfIds() async =>
      _buffer.keys.toList();

  /// Extract ID from StorageType
  IdType _extractId(D data) => data.id;

  @override
  Future<void> destroy() async {
    await clear();
  }
}
