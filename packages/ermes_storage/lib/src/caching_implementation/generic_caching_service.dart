import 'package:iermes/iermes.dart';

class GenericCachingService<TId, TData>
    implements IGenericCachingService<TId, TData> {
  GenericCachingService(this._repo);

  final IGenericCachingRepository<TId, TData> _repo;

  @override
  Future<void> store(TId id, TData data) => _repo.store(id, data);

  @override
  Future<TData?> retrieve(TId id) => _repo.retrieve(id);

  @override
  Future<bool> delete(TId id) => _repo.delete(id);

  @override
  Future<void> clear() => _repo.clear();

  @override
  int numberOfElements() => _repo.numberOfElements();

  @override
  Future<List<TId>> listOfIds() => _repo.listOfIds();

  @override
  Future<void> destroy() => _repo.destroy();
}
