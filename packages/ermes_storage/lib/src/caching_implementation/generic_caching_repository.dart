import 'package:iermes/iermes.dart';

class GenericCachingRepository<TId, TData>
    implements IGenericCachingRepository<TId, TData> {
  GenericCachingRepository([this.maxBuffer = 1000]);

  final int maxBuffer;
  final Map<TId, TData> _buffer = {};

  @override
  Future<void> store(TId id, TData data) async {
    _buffer.remove(id);
    _buffer[id] = data;
    if (_buffer.length > maxBuffer) {
      _buffer.remove(_buffer.keys.first);
    }
  }

  @override
  Future<TData?> retrieve(TId id) async => _buffer[id];

  @override
  Future<bool> delete(TId id) async => _buffer.remove(id) != null;

  @override
  Future<void> clear() async => _buffer.clear();

  @override
  int numberOfElements() => _buffer.length;

  @override
  Future<List<TId>> listOfIds() async => _buffer.keys.toList();

  @override
  Future<void> destroy() async => _buffer.clear();
}
