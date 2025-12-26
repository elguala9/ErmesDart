import '../interfaces/iermes_caching.dart';

/// Repository in-memoria con capacità massima e politica FIFO/LIFO
class ErmesCachingRepository<D> extends IErmesCachingRepository<D> {
  ErmesCachingRepository(this.maxBuffer);
  final Map<dynamic, D> _buffer = {};
  final int maxBuffer;

  @override
  Future<void> store(D data) async {
    // Estrai l'ID dal dato
    dynamic id;
    if (data is Map) {
      if (!data.containsKey('id')) {
        throw Exception('Data must have an id property');
      }
      id = data['id'];
    } else {
      // Prova ad accedere come getter per oggetti non-Map
      id = (data as dynamic).id;
    }

    // Se l'elemento esiste già, lo togliamo per reinserirlo (aggiornamento)
    if (_buffer.containsKey(id)) {
      _buffer.remove(id);
    }

    _buffer[id] = data;

    // Se superiamo la capacità, rimuoviamo il più vecchio (prima chiave inserita)
    if (numberOfElements() > maxBuffer) {
      final oldestKey = _buffer.keys.first;
      _buffer.remove(oldestKey);
    }
  }

  @override
  Future<D?> retrieve(dynamic id) async => _buffer[id];

  @override
  Future<bool> delete(dynamic id) async => _buffer.remove(id) != null;

  @override
  Future<void> clear() async {
    _buffer.clear();
  }

  @override
  int numberOfElements() => _buffer.length;

  @override
  Future<List<dynamic>> listOfIds() async => _buffer.keys.toList();

  @override
  Future<void> destroy() async {
    await clear();
  }
}
