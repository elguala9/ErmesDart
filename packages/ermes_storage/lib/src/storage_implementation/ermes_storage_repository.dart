import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:work_db/work_db.dart';

import '../interfaces/iermes_storage.dart';

/// Repository generico per lo storage persistente con work_db
@includeInBarrelFile
class ErmesStorageRepository<DataJson>
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
    if (data is! Map || !data.containsKey('id')) {
      throw Exception('Data must have an id property');
    }

    try {
      final id = data['id'].toString();
      final serializedData = Map<String, dynamic>.from(data as Map);

      // Gestione di dati binari (se applicabile)
      if (serializedData.containsKey('data') &&
          serializedData['data'] is! List) {
        final data = serializedData['data'];
        if (data is Iterable && data is! String) {
          serializedData['data'] = List<int>.from(data);
        }
      }

      // Crea o aggiorna con work_db
      await _db.createOrUpdate(
        ItemWithId(id: id, collection: _collection, item: serializedData),
      );

      _numberOfElements++;
    } on Exception catch (e) {
      throw Exception('Failed to store data: $e');
    }
  }

  @override
  Future<DataJson?> retrieve(dynamic id) async {
    try {
      final result = await _db.retrieve(
        ItemId(id: id.toString(), collection: _collection),
      );

      if (result != null) {
        final deserializedData = Map<String, dynamic>.from(result.item as Map);
        if (deserializedData['data'] is List) {
          deserializedData['data'] = List<int>.from(
            deserializedData['data'] as Iterable<dynamic>,
          );
        }
        return deserializedData as DataJson;
      }
      return null;
    } on Exception catch (e) {
      throw Exception('Failed to retrieve data: $e');
    }
  }

  @override
  Future<bool> delete(dynamic id) async {
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
  Future<List<dynamic>> listOfIds() async {
    try {
      final itemIds = await _db.getItemsInCollection(_collection);
      return itemIds.map((dynamic id) => id.toString()).toList();
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
}
