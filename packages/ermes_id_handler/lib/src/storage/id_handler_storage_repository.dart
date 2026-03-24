
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

/// Repository for storing ID handler state persistently using work_db
@isSingleton
class IdHandlerStorageRepository implements IIdHandlerStorageRepository {
  IdHandlerStorageRepository();
  IdHandlerStorageRepository.fromDb(
      this.db, [this._collection = _defaultCollection]);

  static const String _defaultCollection = 'id_handler';
  static const String _idKey = 'current_id';
  @isMandatoryParameter
  @protected
  late IWorkDbSync db;
  late String _collection = _defaultCollection;

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

  @override
  void save() {
    // work_db persists synchronously on every write; no-op here
  }

  @override
  void close() {
    // No connection to close for work_db
  }

  @override
  void destroy() {
    db.deleteCollectionSync(_collection);
  }
}
