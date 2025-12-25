import '../interfaces/iermes_storage.dart';

/// Service che gestisce lo storage dei messaggi
/// 
/// Nota: il DB salva documenti di tipo DataJson & { _id: String }
class ErmesStorageService<DataJson> extends IErmesStorageService<DataJson> {
  late IErmesStorageRepository<DataJson> _repo;

  ErmesStorageService(IErmesStorageRepository<DataJson> repo) {
    _repo = repo;
  }

  @override
  Future<void> store(DataJson data) {
    return _repo.store(data);
  }

  @override
  Future<DataJson?> retrieve(dynamic id) {
    return _repo.retrieve(id);
  }

  @override
  Future<bool> delete(dynamic id) {
    return _repo.delete(id);
  }

  @override
  Future<void> clear() {
    return _repo.clear();
  }

  @override
  int numberOfElements() {
    return _repo.numberOfElements();
  }

  @override
  Future<List<dynamic>> listOfIds() {
    return _repo.listOfIds();
  }

  @override
  Future<void> destroy() {
    return _repo.destroy();
  }
}
