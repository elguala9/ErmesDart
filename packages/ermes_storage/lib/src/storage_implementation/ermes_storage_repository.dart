import '../interfaces/iermes_storage.dart';

/// Repository generico per lo storage persistente
///
/// Nota: In Dart puro non includiamo dipendenze da librerie esterne.
/// Questo è un template che dovrà essere adattato con la tua
/// libreria di database reale (hive, isar, sqflite, ecc.)
class ErmesStorageRepository<DataJson>
    extends IErmesStorageRepository<DataJson> {
  ErmesStorageRepository(dynamic db, [String collection = defaultCollection])
      : _collection = collection {
    _db = db;
    _loadElementCount();
  }
  static const String defaultCollection = 'ermes_messages';

  late dynamic _db; // Sostituire con il tipo reale del tuo DB
  int _numberOfElements = 0;
  final String _collection;

  Future<void> _loadElementCount() async {
    try {
      // Adattare alla tua libreria di database reale
      final ids = await listOfIds();
      _numberOfElements = ids.length;
    } catch (error) {
      print('Failed to load element count: $error');
      _numberOfElements = 0;
    }
  }

  @override
  Future<void> store(DataJson data) async {
    if (data is! Map || !data.containsKey('id')) {
      throw Exception('Data must have an id property');
    }

    try {
      final itemId = {
        'id': data['id'].toString(),
        'collection': _collection,
      };

      // Serializzazione dei dati
      final serializedData = Map<String, dynamic>.from(data as Map);

      // Gestione di Uint8Array (se applicabile)
      if (serializedData.containsKey('data') &&
          serializedData['data'] is! List) {
        // Se fosse un Uint8Array, converti a List
        serializedData['data'] =
            List<int>.from(serializedData['data'] as Iterable<dynamic>);
      }

      final item = {'item': serializedData};

      // Adattare alla tua libreria di database
      // Questo è un template di base
      // Esempio:
      // final existingItem = await _db.retrieve(itemId);
      // if (existingItem != null) {
      //   await _db.update({...itemId, ...item});
      // } else {
      //   await _db.create({...itemId, ...item});
      //   _numberOfElements++;
      // }
    } catch (error) {
      throw Exception('Failed to store data: $error');
    }
  }

  @override
  Future<DataJson?> retrieve(dynamic id) async {
    try {
      final itemId = {
        'id': id.toString(),
        'collection': _collection,
      };

      // Adattare alla tua libreria di database
      // Esempio:
      // final result = await _db.retrieve(itemId);
      // if (result != null && result['item'] != null) {
      //   final deserializedData = Map<String, dynamic>.from(result['item']);
      //   if (deserializedData['data'] is List) {
      //     deserializedData['data'] = Uint8List.fromList(deserializedData['data']);
      //   }
      //   return deserializedData as DataJson;
      // }
      return null;
    } catch (error) {
      throw Exception('Failed to retrieve data: $error');
    }
  }

  @override
  Future<bool> delete(dynamic id) async {
    final itemId = {
      'id': id.toString(),
      'collection': _collection,
    };

    // Adattare alla tua libreria di database
    // Esempio:
    // final existingItem = await _db.retrieve(itemId);
    // if (existingItem != null) {
    //   await _db.delete(itemId);
    //   _numberOfElements = (_numberOfElements - 1).clamp(0, double.infinity).toInt();
    //   final verifyDeleted = await _db.retrieve(itemId);
    //   if (verifyDeleted != null) {
    //     throw Exception('Failed to delete item $id: item still exists after deletion');
    //   }
    //   return true;
    // }
    return false;
  }

  @override
  Future<void> clear() async {
    // Adattare alla tua libreria di database
    // Esempio:
    // await _db.deleteCollection(_collection);
    _numberOfElements = 0;
  }

  @override
  int numberOfElements() => _numberOfElements;

  @override
  Future<List<dynamic>> listOfIds() async {
    try {
      // Adattare alla tua libreria di database
      // Esempio:
      // final itemIds = await _db.getItemsInCollection(_collection);
      // return itemIds
      //     .map((id) => int.tryParse(id) ?? id)
      //     .where((id) => id is int)
      //     .toList();
      return [];
    } catch (error) {
      throw Exception('Failed to list IDs: $error');
    }
  }

  @override
  Future<void> destroy() async {
    try {
      // Adattare alla tua libreria di database
      // Esempio:
      // await _db.clearDatabase();
      _numberOfElements = 0;
      // In Dart il garbage collection gestisce la pulizia automaticamente
    } catch (error) {
      throw Exception('Failed to destroy database: $error');
    }
  }
}
