
import 'package:iermes/iermes.dart';

/// Service che gestisce il caching dei messaggi

class ErmesCachingService<DataJson extends StorageType>
    extends IErmesCachingService<DataJson> {
  /// Creates a caching service delegating to the given repository.
  ErmesCachingService(IErmesCachingRepository<DataJson> repo) {
    _repo = repo;
  }
  late IErmesCachingRepository<DataJson> _repo;

  /// Stores [data] in the underlying cache repository.
  @override
  Future<void> store(DataJson data) => _repo.store(data);

  /// Retrieves the cached element for [id].
  @override
  Future<DataJson?> retrieve(IdType id) => _repo.retrieve(id);

  /// Deletes the cached element for [id].
  @override
  Future<bool> delete(IdType id) => _repo.delete(id);

  /// Clears all cached elements.
  @override
  Future<void> clear() => _repo.clear();

  /// Returns the number of cached elements.
  @override
  int numberOfElements() => _repo.numberOfElements();

  /// Returns the IDs of all cached elements.
  @override
  Future<List<IdType>> listOfIds() async {
    final ids = await _repo.listOfIds();
    return ids.cast<IdType>();
  }

  /// Releases the service and destroys the underlying repository.
  @override
  Future<void> destroy() async {
    await _repo.destroy();
    // Nulliamo il riferimento per indicare la distruzione
    // (In Dart non è strettamente necessario, il GC farà il resto)
  }
}
