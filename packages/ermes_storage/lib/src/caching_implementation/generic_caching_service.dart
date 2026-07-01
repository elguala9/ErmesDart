import 'package:iermes/iermes.dart';

/// Generic caching service delegating all operations to a
/// [IGenericCachingRepository] keyed by arbitrary ID and data types.
class GenericCachingService<TId, TData>
    implements IGenericCachingService<TId, TData> {
  /// Creates a service backed by the given repository.
  GenericCachingService(this._repo);

  final IGenericCachingRepository<TId, TData> _repo;

  /// Stores [data] under [id] in the underlying repository.
  @override
  Future<void> store(TId id, TData data) => _repo.store(id, data);

  /// Retrieves the element stored under [id].
  @override
  Future<TData?> retrieve(TId id) => _repo.retrieve(id);

  /// Deletes the element stored under [id].
  @override
  Future<bool> delete(TId id) => _repo.delete(id);

  /// Clears all cached elements.
  @override
  Future<void> clear() => _repo.clear();

  /// Returns the number of cached elements.
  @override
  int numberOfElements() => _repo.numberOfElements();

  /// Returns the IDs of all cached elements.
  @override
  Future<List<TId>> listOfIds() => _repo.listOfIds();

  /// Releases the service and destroys the underlying repository.
  @override
  Future<void> destroy() => _repo.destroy();
}
