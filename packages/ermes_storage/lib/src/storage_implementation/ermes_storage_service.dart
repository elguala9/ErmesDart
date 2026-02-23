import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Service che gestisce lo storage dei messaggi
///
/// Nota: il DB salva documenti di tipo DataJson & { _id: String }
@includeInBarrelFile
class ErmesStorageService<DataJson extends StorageType>
    extends IErmesStorageService<DataJson> {
  ErmesStorageService(IErmesStorageRepository<DataJson> repo) {
    _repo = repo;
  }
  late IErmesStorageRepository<DataJson> _repo;

  @override
  Future<void> store(DataJson data) => _repo.store(data);

  @override
  Future<DataJson?> retrieve(IdType id) => _repo.retrieve(id);

  @override
  Future<bool> delete(IdType id) => _repo.delete(id);

  @override
  Future<void> clear() => _repo.clear();

  @override
  int numberOfElements() => _repo.numberOfElements();

  @override
  Future<List<IdType>> listOfIds() async {
    final ids = await _repo.listOfIds();
    return ids.cast<IdType>();
  }

  @override
  Future<void> destroy() => _repo.destroy();
}
