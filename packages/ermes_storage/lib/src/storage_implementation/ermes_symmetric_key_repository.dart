import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

/// Repository for managing symmetric keys
class ErmesSymmetricKeyRepository
    implements IErmesSymmetricKeyRepository {
  ErmesSymmetricKeyRepository(
    this._db, [
    this._collection = defaultCollection,
  ]) {
    _numberOfElements = 0;
  }

  static const String defaultCollection = 'ermes_symmetric_keys';

  final IWorkDb _db;
  final String _collection;
  int _numberOfElements = 0;

  @override
  Future<void> store(StorageSymmetricKeyType data) async {
    final id = data.id;
    final serializedData = data.json;

    await _db.createOrUpdate(
      ItemWithId(
        id: id.toString(),
        collection: _collection,
        item: serializedData,
      ),
    );

    _numberOfElements++;
  }

  @override
  Future<StorageSymmetricKeyType?> retrieve(IdType id) async {
    final result = await _db.retrieve(
      ItemId(id: id.toString(), collection: _collection),
    );

    if (result != null) {
      final deserializedData = Map<String, dynamic>.from(result.item as Map);
      return StorageSymmetricKeyType.fromJson(deserializedData);
    }
    return null;
  }

  @override
  Future<bool> delete(IdType id) async {
    final itemId = ItemId(id: id.toString(), collection: _collection);
    final existingItem = await _db.retrieve(itemId);

    if (existingItem != null) {
      await _db.delete(itemId);
      _numberOfElements = (_numberOfElements - 1)
          .clamp(0, double.infinity)
          .toInt();
      return true;
    }
    return false;
  }

  @override
  Future<void> clear() async {
    await _db.deleteCollection(_collection);
    _numberOfElements = 0;
  }

  @override
  int numberOfElements() => _numberOfElements;

  @override
  Future<List<IdType>> listOfIds() async {
    final itemIds = await _db.getItemsInCollection(_collection);
    return itemIds.map((id) => id as IdType).toList();
  }

  @override
  Future<void> destroy() async {
    await _db.clearDatabase();
    _numberOfElements = 0;
  }
}
