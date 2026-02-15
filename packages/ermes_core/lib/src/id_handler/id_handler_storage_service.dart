import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Service for storing ID handler state persistently using IErmesStorage
@includeInBarrelFile
class IdHandlerStorageService implements IIdHandlerStorageService {
  /// Creates an IdHandlerStorageService
  ///
  /// [repo] - Repository for persisting the ID counter
  IdHandlerStorageService(IIdHandlerStorageRepository repo) : _repo = repo;

  final IIdHandlerStorageRepository _repo;

  @override
  Future<void> update(IdType id) => _repo.update(id);

  @override
  void save() => _repo.save();

  @override
  void close() => _repo.close();

  @override
  void destroy() => _repo.destroy();
}
