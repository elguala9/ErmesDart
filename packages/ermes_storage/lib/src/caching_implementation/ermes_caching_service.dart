import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Service che gestisce il caching dei messaggi
@includeInBarrelFile
class ErmesCachingService<DataJson extends StorageType>
    extends IErmesCachingService<DataJson> {
  ErmesCachingService(IErmesCachingRepository<DataJson> repo) {
    _repo = repo;
  }
  late IErmesCachingRepository<DataJson> _repo;

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
  Future<void> destroy() async {
    await _repo.destroy();
    // Nulliamo il riferimento per indicare la distruzione
    // (In Dart non è strettamente necessario, il GC farà il resto)
  }
}
