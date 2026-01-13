import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';

import '../interfaces/iermes_caching.dart';

/// Repository in-memoria con capacità massima e politica FIFO/LIFO
@includeInBarrelFile
class ErmesCachingRepository<D> extends IErmesCachingRepository<D> {
  ErmesCachingRepository(this.maxBuffer);
  final Map<dynamic, D> _buffer = {};
  final int maxBuffer;

  @override
  Future<void> store(D data) async {
    // Estrai l'ID dal dato
    dynamic id;
    if (data is! Map) {
      throw Exception('Data must be a Map with an id property');
    }
    if (!data.containsKey('id')) {
      throw Exception('Data must have an id property');
    }
    id = data['id'];

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
  Future<List<IdType>> listOfIds() async =>
      _buffer.keys.cast<IdType>().toList();

  @override
  Future<void> destroy() async {
    await clear();
  }
}
