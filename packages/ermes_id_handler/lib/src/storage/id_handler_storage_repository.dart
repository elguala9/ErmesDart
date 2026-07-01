
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

/// Repository for storing ID handler state persistently using work_db
@isSingleton
class IdHandlerStorageRepository implements IIdHandlerStorageRepository {
  /// Default constructor used by the dependency injection framework.
  IdHandlerStorageRepository();
  /// Creates a repository backed by the given [db] and optional [_collection].
  IdHandlerStorageRepository.fromDb(
      this.db, [this._collection = _defaultCollection]);

  /// Default collection name used to store the ID counter.
  static const String _defaultCollection = 'id_handler';
  /// Key under which the current ID value is stored.
  static const String _idKey = 'current_id';
  /// Synchronous work_db instance used for persistence.
  @isMandatoryParameter
  @protected
  late IWorkDbSync db;
  /// Collection name where the ID counter is persisted.
  late String _collection = _defaultCollection;

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
