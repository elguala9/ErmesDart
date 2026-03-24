
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
  @isInjected
  @protected
  late IIdHandlerStorageRepository repo = IdHandlerStorageRepository.fromDb(
    WorkDbFactory().create(const MemoryWorkDbFactoryInput()),
  );

  @override
  void update(IdType id) => repo.update(id);

  @override
  void save() => repo.save();

  @override
  void close() => repo.close();

  @override
  void destroy() => repo.destroy();
}
