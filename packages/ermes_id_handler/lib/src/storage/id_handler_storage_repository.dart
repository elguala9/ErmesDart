
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

/// Repository for storing ID handler state persistently using work_db
@dependencyInjectable
class IdHandlerStorageRepository implements IIdHandlerStorageRepository {
  /// Creates a repository backed by the given [db], persisting the counter
  /// into the default collection.
  IdHandlerStorageRepository(this.db) : _collection = _defaultCollection;

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory IdHandlerStorageRepository.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final db = RegistryManager.instance.getInstance<IWorkDbSync>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return IdHandlerStorageRepository( // GENERATED CODE - DO NOT MODIFY BY HAND
      db, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Creates a repository backed by the given [db] and optional [_collection].
  IdHandlerStorageRepository.fromDb(
      this.db, [this._collection = _defaultCollection]);

  /// Default collection name used to store the ID counter.
  static const String _defaultCollection = 'id_handler';
  /// Key under which the current ID value is stored.
  static const String _idKey = 'current_id';
  /// Synchronous work_db instance used for persistence.
  @protected
  final IWorkDbSync db;
  /// Collection name where the ID counter is persisted.
  final String _collection;

  /// Persists the given [id] as the current counter value.
  @override
  void update(IdType id) {
    db.createOrUpdateSync(
      ItemWithId(
        id: _idKey,
        collection: _collection,
        item: {'id': id},
      ),
    );
  }

  /// No-op; work_db persists synchronously on every write.
  @override
  void save() {
    // work_db persists synchronously on every write; no-op here
  }

  /// No-op; work_db has no connection to close.
  @override
  void close() {
    // No connection to close for work_db
  }

  /// Deletes the persisted collection, discarding all stored state.
  @override
  void destroy() {
    db.deleteCollectionSync(_collection);
  }
}
