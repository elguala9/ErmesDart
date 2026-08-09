
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

import '../../ermes_id_handler.dart';

/// Service for storing ID handler state persistently using IErmesStorage
@dependencyInjectable
class IdHandlerStorageService implements IIdHandlerStorageService {

  /// Creates an IdHandlerStorageService persisting through [repo].
  IdHandlerStorageService(this.repo);

  // GENERATED CODE - DO NOT MODIFY BY HAND
  factory IdHandlerStorageService.dependencyInjectionFactory(
      // ignore: avoid_unused_constructor_parameters,
      {String key = 'default', String subkey = 'default'}) {
    // GENERATED CODE - DO NOT MODIFY BY HAND
    final repo = RegistryManager.instance
        .getInstance<IIdHandlerStorageRepository>(key: key);

    // GENERATED CODE - DO NOT MODIFY BY HAND
    return IdHandlerStorageService(
      repo,
    );
  }
  // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Creates a service backed by an in-memory work_db, for callers that need
  /// a throw-away storage service without wiring a repository themselves.
  IdHandlerStorageService.inMemory()
      : repo = IdHandlerStorageRepository(
          WorkDbFactory().create(const MemoryWorkDbFactoryInput()),
        );

  ///
  /// [repo] - Repository for persisting the ID counter
  IdHandlerStorageService.fromRepo(IIdHandlerStorageRepository repo)
      : this(repo);

  /// Repository used to persist the ID counter.
  @protected
  final IIdHandlerStorageRepository repo;

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
