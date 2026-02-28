
import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

/// Repository generico per lo storage persistente con work_db

class ErmesStorageRepository<DataJson extends StorageType>
    extends IErmesStorageRepository<DataJson> {
  ErmesStorageRepository(IWorkDb db, [String collection = defaultCollection])
    : _collection = collection {
    _db = db;
    _numberOfElements = 0;
  }

  static const String defaultCollection = 'ermes_messages';

  late IWorkDb _db;
  int _numberOfElements = 0;
  final String _collection;

  @override
  Future<void> store(DataJson data) async {
    final id = _extractId(data);

    final serializedData = _toMap(data);

    // Crea o aggiorna con work_db
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
  Future<DataJson?> retrieve(IdType id) async {
    final result = await _db.retrieve(
      ItemId(id: id.toString(), collection: _collection),
    );

    if (result != null) {
      final deserializedData = Map<String, dynamic>.from(result.item as Map);
      return StorageType.fromJson(deserializedData) as DataJson;
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

  /// Extract ID from StorageType
  IdType _extractId(DataJson data) => data.id;

  /// Convert StorageType to Map<String, dynamic>
  Map<String, dynamic> _toMap(DataJson data) => data.json;
}
