
import 'dart:async';

import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

/// Repository generico per lo storage persistente con work_db

class ErmesStorageRepository<DataJson extends StorageType>
    extends IErmesStorageRepository<DataJson> {
  /// Creates a repository over [db] for the given [collection], optionally with
  /// a deserialization factory and an encryption service for data at rest.
  ErmesStorageRepository(
    IWorkDb db, [
    String collection = defaultCollection,
    DataJson Function(Map<String, dynamic>)? fromJsonFactory,
    IStorageEncryptionService? encryptionService,
  ])  : _collection = collection,
        _fromJsonFactory = fromJsonFactory,
        _encryptionService = encryptionService {
    _db = db;
    _numberOfElements = 0;
  }

  /// Default collection name used when none is provided.
  static const String defaultCollection = 'ermes_messages';

  late IWorkDb _db;
  int _numberOfElements = 0;
  final String _collection;
  final DataJson Function(Map<String, dynamic>)? _fromJsonFactory;
  final IStorageEncryptionService? _encryptionService;

  /// Serializes concurrent store operations to preserve ordering.
  Future<void> _storeQueue = Future.value();

  /// Stores [data], serializing the write behind any in-flight store.
  @override
  Future<void> store(DataJson data) async {
    final completer = Completer<void>();
    _storeQueue = _storeQueue.then((_) async {
      try {
        await _storeInternal(data);
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    }).catchError((_) {});
    await completer.future;
  }

  /// Performs the actual persistence, applying encryption and tracking count.
  Future<void> _storeInternal(DataJson data) async {
    final id = _extractId(data);

    var serializedData = _toMap(data);
    if (_encryptionService != null) {
      serializedData = _encryptionService.encrypt(serializedData);
    }

    final itemId = ItemId(id: id.toString(), collection: _collection);
    final existingItem = await _db.retrieve(itemId);
    final isNewItem = existingItem == null;

    await _db.createOrUpdate(
      ItemWithId(
        id: id.toString(),
        collection: _collection,
        item: serializedData,
      ),
    );

    if (isNewItem) {
      _numberOfElements++;
    }
  }

  /// Retrieves and deserializes the item for [id], decrypting if configured.
  @override
  Future<DataJson?> retrieve(IdType id) async {
    final result = await _db.retrieve(
      ItemId(id: id.toString(), collection: _collection),
    );

    if (result != null) {
      var deserializedData = Map<String, dynamic>.from(result.item as Map);
      if (_encryptionService != null) {
        deserializedData = _encryptionService.decrypt(deserializedData);
      }
      if (_fromJsonFactory != null) {
        return _fromJsonFactory(deserializedData);
      }
      return StorageType.fromJson(deserializedData) as DataJson;
    }
    return null;
  }

  /// Deletes the item for [id], updating the element count if it existed.
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

  /// Removes all items in the collection and resets the element count.
  @override
  Future<void> clear() async {
    await _db.deleteCollection(_collection);
    _numberOfElements = 0;
  }

  /// Returns the number of stored elements.
  @override
  int numberOfElements() => _numberOfElements;

  /// Returns the IDs of all stored items, parsed as integers.
  @override
  Future<List<IdType>> listOfIds() async {
    final itemIds = await _db.getItemsInCollection(_collection);
    return itemIds
        .map((id) => int.tryParse(id) ?? 0)
        .toList();
  }

  /// Clears the entire database and resets the element count.
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
