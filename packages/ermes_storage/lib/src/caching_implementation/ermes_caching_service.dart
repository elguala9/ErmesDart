import '../interfaces/iermes_caching.dart';

/// Service che gestisce il caching dei messaggi
class ErmesCachingService<DataJson> extends IErmesCachingService<DataJson> {
  late IErmesCachingRepository<DataJson> _repo;

  ErmesCachingService(IErmesCachingRepository<DataJson> repo) {
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
  Future<void> destroy() async {
    await _repo.destroy();
    // Nulliamo il riferimento per indicare la distruzione
    // (In Dart non è strettamente necessario, il GC farà il resto)
  }
}
