import 'dart:async';
import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// Repository implementation for ID handler persistent storage
@includeInBarrelFile
class IdHandlerStorageRepository implements IIdHandlerStorageRepository {
  IdHandlerStorageRepository({
    required this.storageKey,
    this.persistenceInterval = const Duration(seconds: 30),
  });

  final String storageKey;
  final Duration persistenceInterval;

  IdType? _currentId;
  Timer? _persistenceTimer;
  bool _closed = false;

  // TODO: Add actual persistent storage backend
  // This could be SharedPreferences, SQLite, file storage, etc.
  static final Map<String, IdType> _mockStorage = {};

  @override
  Future<void> update(IdType id) async {
    if (_closed) {
      throw StateError('Cannot update on closed storage');
    }

    _currentId = id;

    // TODO: Implement debounced persistence to avoid excessive writes
    _startPersistenceTimer();
  }

  @override
  void save() {
    if (_closed || _currentId == null) {
      return;
    }

    try {
      // TODO: Replace with actual persistent storage
      // Examples:
      // - SharedPreferences: prefs.setInt(storageKey, _currentId!);
      // - File: await File('ids/$storageKey.txt').writeAsString(_currentId.toString());
      // - SQLite: await db.update('id_counters', {'value': _currentId}, where: 'key = ?', whereArgs: [storageKey]);

      _mockStorage[storageKey] = _currentId!;
    } catch (e) {
      throw Exception('Failed to save ID to storage: $e');
    }
  }

  @override
  void close() {
    if (_closed) {
      return;
    }

    _persistenceTimer?.cancel();
    _persistenceTimer = null;

    // Save final state before closing
    if (_currentId != null) {
      save();
    }

    _closed = true;
  }

  @override
  void destroy() {
    close();

    // TODO: Optionally remove data from persistent storage
    // _mockStorage.remove(storageKey);

    _currentId = null;
  }

  /// Load the stored ID from persistent storage
  Future<IdType?> load() async {
    if (_closed) {
      throw StateError('Cannot load from closed storage');
    }

    try {
      // TODO: Replace with actual persistent storage
      // Examples:
      // - SharedPreferences: return prefs.getInt(storageKey);
      // - File: final file = File('ids/$storageKey.txt'); return file.existsSync() ? int.parse(await file.readAsString()) : null;
      // - SQLite: final result = await db.query('id_counters', where: 'key = ?', whereArgs: [storageKey]); return result.isNotEmpty ? result.first['value'] as int : null;

      return _mockStorage[storageKey];
    } catch (e) {
      throw Exception('Failed to load ID from storage: $e');
    }
  }

  /// Initialize storage and load existing value
  Future<void> initialize() async {
    if (_closed) {
      throw StateError('Cannot initialize closed storage');
    }

    _currentId = await load();
  }

  /// Get the current stored ID without loading
  IdType? get currentId => _currentId;

  /// Check if storage is closed
  bool get isClosed => _closed;

  void _startPersistenceTimer() {
    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(persistenceInterval, () {
      if (!_closed) {
        save();
      }
    });
  }
}
