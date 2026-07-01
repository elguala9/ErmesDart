
import 'package:iermes/iermes.dart';

/// Service che gestisce lo storage dei messaggi
///
/// Nota: il DB salva documenti di tipo DataJson & { _id: String }

class ErmesStorageService<DataJson extends StorageType>
    extends IErmesStorageService<DataJson> {
  /// Creates a storage service delegating to the given repository.
  ErmesStorageService(IErmesStorageRepository<DataJson> repo) {
    _repo = repo;
  }
  late IErmesStorageRepository<DataJson> _repo;

  /// Stores [data] in the underlying repository.
  @override
  Future<void> store(DataJson data) => _repo.store(data);

  /// Retrieves the item for [id].
  @override
  Future<DataJson?> retrieve(IdType id) => _repo.retrieve(id);

  /// Deletes the item for [id].
  @override
  Future<bool> delete(IdType id) => _repo.delete(id);

  /// Clears all stored items.
  @override
  Future<void> clear() => _repo.clear();

  /// Returns the number of stored items.
  @override
  int numberOfElements() => _repo.numberOfElements();

  /// Returns the IDs of all stored items.
  @override
  Future<List<IdType>> listOfIds() async {
    final ids = await _repo.listOfIds();
    return ids.cast<IdType>();
  }

  /// Releases the service and destroys the underlying repository.
  @override
  Future<void> destroy() => _repo.destroy();
}
