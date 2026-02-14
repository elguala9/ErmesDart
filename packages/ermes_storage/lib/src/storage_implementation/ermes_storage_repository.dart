import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

/// Repository generico per lo storage persistente con work_db
@includeInBarrelFile
class ErmesStorageRepository<DataJson extends MessageType>
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
    try {
      final id = _extractId(data);
      if (id == null) {
        throw Exception('Data must have an id property');
      }

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
    } on Exception catch (e) {
      throw Exception('Failed to store data: $e');
    }
  }

  @override
  Future<DataJson?> retrieve(IdType id) async {
    try {
      final result = await _db.retrieve(
        ItemId(id: id.toString(), collection: _collection),
      );

      if (result != null) {
        final deserializedData = Map<String, dynamic>.from(result.item as Map);
        return MessageType.fromJson(deserializedData) as DataJson;
      }
      return null;
    } on Exception catch (e) {
      throw Exception('Failed to retrieve data: $e');
    }
  }

  @override
  Future<bool> delete(IdType id) async {
    try {
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
    } on Exception catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _db.deleteCollection(_collection);
      _numberOfElements = 0;
    } on Exception catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }

  @override
  int numberOfElements() => _numberOfElements;

  @override
  Future<List<IdType>> listOfIds() async {
    try {
      final itemIds = await _db.getItemsInCollection(_collection);
      return itemIds.map((dynamic id) => int.parse(id.toString())).toList();
    } on Exception catch (e) {
      throw Exception('Failed to list IDs: $e');
    }
  }

  @override
  Future<void> destroy() async {
    try {
      await _db.clearDatabase();
      _numberOfElements = 0;
    } on Exception catch (e) {
      throw Exception('Failed to destroy database: $e');
    }
  }

  /// Extract ID from MessageType union
  dynamic _extractId(DataJson data) => data.when(
    data: (msg) => msg.id,
    chunk: (msg) => msg.id,
    service: (msg) => msg.id,
  );

  /// Convert MessageType to Map<String, dynamic>
  Map<String, dynamic> _toMap(DataJson data) => (data as MessageType).toJson();
}
