import '../interfaces/iermes_caching.dart';

/// Repository in-memoria con capacità massima e politica FIFO/LIFO
class ErmesCachingRepository<D> extends IErmesCachingRepository<D> {
  final Map<dynamic, D> _buffer = {};
  final int maxBuffer;

  ErmesCachingRepository(this.maxBuffer);

  @override
  Future<void> store(D data) async {
    // Se l'elemento esiste già, lo togliamo per reinserirlo (aggiornamento)
    if (data is Map && data.containsKey('id')) {
      final id = data['id'];
      if (_buffer.containsKey(id)) {
        _buffer.remove(id);
      }
    }

    // Assumi che data abbia un campo 'id'
    final id = (data as dynamic).id;
    _buffer[id] = data;

    // Se superiamo la capacità, rimuoviamo il più vecchio (prima chiave inserita)
    if (numberOfElements() > maxBuffer) {
      final oldestKey = _buffer.keys.first;
      _buffer.remove(oldestKey);
    }
  }

  @override
  Future<D?> retrieve(dynamic id) async {
    return _buffer[id];
  }

  @override
  Future<bool> delete(dynamic id) async {
    return _buffer.remove(id) != null;
  }

  @override
  Future<void> clear() async {
    _buffer.clear();
  }

  @override
  int numberOfElements() {
    return _buffer.length;
  }

  @override
  Future<List<dynamic>> listOfIds() async {
    return _buffer.keys.toList();
  }

  @override
  Future<void> destroy() async {
    await clear();
  }
}
