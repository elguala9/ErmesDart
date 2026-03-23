abstract class IGenericCachingRepository<TId, TData> {
  Future<void> store(TId id, TData data);
  Future<TData?> retrieve(TId id);
  Future<bool> delete(TId id);
  Future<void> clear();
  int numberOfElements();
  Future<List<TId>> listOfIds();
  Future<void> destroy();
}

abstract class IGenericCachingService<TId, TData>
    implements IGenericCachingRepository<TId, TData> {}
