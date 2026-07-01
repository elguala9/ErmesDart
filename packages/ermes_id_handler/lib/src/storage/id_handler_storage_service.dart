
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

import '../../ermes_id_handler.dart';

/// Service for storing ID handler state persistently using IErmesStorage
@isSingleton
class IdHandlerStorageService implements IIdHandlerStorageService {

  /// Creates an IdHandlerStorageService
  IdHandlerStorageService();
  ///
  /// [repo] - Repository for persisting the ID counter
  IdHandlerStorageService.fromRepo(this.repo);
  /// Repository used to persist the ID counter; defaults to in-memory work_db.
  @isInjected
  @protected
  late IIdHandlerStorageRepository repo = IdHandlerStorageRepository.fromDb(
    WorkDbFactory().create(const MemoryWorkDbFactoryInput()),
  );

  /// Persists the given [id] via the underlying repository.
  @override
  void update(IdType id) => repo.update(id);

  /// Flushes pending state to persistent storage.
  @override
  void save() => repo.save();

  /// Closes the underlying storage repository.
  @override
  void close() => repo.close();

  /// Destroys all persisted state in the underlying repository.
  @override
  void destroy() => repo.destroy();
}
