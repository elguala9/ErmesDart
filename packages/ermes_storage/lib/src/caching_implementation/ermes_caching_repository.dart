import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:iermes/iermes.dart';

/// Repository in-memoria con capacità massima e politica FIFO/LIFO
@includeInBarrelFile
class ErmesCachingRepository<D extends MessageType>
    extends IErmesCachingRepository<D> {
  ErmesCachingRepository(this.maxBuffer);
  final Map<dynamic, D> _buffer = {};
  final int maxBuffer;

  @override
  Future<void> store(D data) async {
    final id = _extractId(data);
    if (id == null) {
      throw Exception('Data must have an id property');
    }

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
  Future<List<IdType>> listOfIds() async {
    final ids = _buffer.keys.toList();
    return ids.map((id) => id as IdType).toList();
  }

  /// Extract ID from MessageType union or other types
  /// Extract ID from MessageType union
  dynamic _extractId(D data) => data.when(
    data: (msg) => msg.id,
    chunk: (msg) => msg.id,
    service: (msg) => msg.id,
  );

  @override
  Future<void> destroy() async {
    await clear();
  }
}
