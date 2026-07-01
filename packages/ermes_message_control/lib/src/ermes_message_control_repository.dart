
import 'package:iermes/iermes.dart';

import 'exceptions.dart';


/// Storage type for message control data

class MessageControlData {
  /// Creates a snapshot with the given [timestamp] and optional [missingIds].
  MessageControlData({required this.timestamp, this.missingIds});
  /// The IDs currently detected as missing, if any.
  final List<IdType>? missingIds;
  /// The moment this snapshot was captured.
  final int timestamp;

  /// Serializes this snapshot into a map for persistence.
  Map<String, dynamic> toMap() => {
    'missing_ids': missingIds,
    'timestamp': timestamp,
  };
}

/// Repository implementation of message control that handles ID tracking and
/// gap detection

class ErmesMessageControlRepository implements IErmesMessageControlRepository {
  /// Set of IDs detected as missing (gaps) in the received sequence.
  final Set<IdType> _missingIds = {};
  /// The highest sequential ID received so far.
  IdType? _lastId;
  /// Callback invoked whenever the set of missing IDs changes.
  CallbackIdsToRequest? _callbackIdsToRequest;

  /// Registers an incoming [id], updating missing-ID tracking accordingly.
  @override
  void idArrived(IdType id) {
    if (_lastId == null) {
      _handleInitialId(id);
      return;
    }

    if (id == _lastId! + 1) {
      _lastId = id;
      return;
    }

    if (id > _lastId! + 1) {
      _handleSequenceGap(id);
      return;
    }

    if (id < _lastId!) {
      _cleanIdArrived(id);
    }
  }

  /// Handles the first received [id], marking any IDs before it as missing.
  void _handleInitialId(IdType id) {
    _lastId = id;
    if (id > 1) {
      for (var i = 1; i < id; i++) {
        _missingIds.add(i);
      }
      _notifyMissingIds();
    }
  }

  /// Records the IDs skipped between the last ID and [id] as missing.
  void _handleSequenceGap(IdType id) {
    if (_lastId == null) {
      _handleInitialId(id);
      return;
    }

    for (var i = _lastId! + 1; i < id; i++) {
      _missingIds.add(i);
    }
    _lastId = id;
    _notifyMissingIds();
  }

  /// Notifies the registered callback with the sorted list of missing IDs.
  void _notifyMissingIds() {
    _callbackIdsToRequest?.call(_missingIds.toList()..sort());
  }

  /// Removes a previously missing [id] now that it has arrived.
  void _cleanIdArrived(IdType id) {
    if (!_missingIds.contains(id)) {
      throw MessageControlException('ID: $id, is not missing');
    }
    _missingIds.remove(id);
  }

  /// Returns the sorted list of IDs that still need to be requested.
  @override
  Future<List<IdType>> idsToRequest() async => _missingIds.toList()..sort();

  /// Returns the count of currently missing IDs.
  @override
  int numberOfMissingIds() => _missingIds.length;

  /// Registers the [callback] to be notified when missing IDs change.
  @override
  void setCallbackIdsToRequest(CallbackIdsToRequest callback) {
    _callbackIdsToRequest = callback;
  }

  /// Clears the tracked set of missing IDs.
  @override
  Future<void> clear() async {
    _missingIds.clear();
  }

  /// Resets all tracking state, including last ID and registered callback.
  @override
  Future<void> destroy() async {
    _missingIds.clear();
    _lastId = null;
    _callbackIdsToRequest = null;
  }

  /// Persists the current missing IDs and last ID (currently a no-op).
  @override
  Future<void> saveState() async {
    // SaveState: Save missing IDs and lastId to persistent storage
  }

  /// Loads previously persisted state from the collection (currently a no-op).
  Future<void> loadState() async {
    // LoadState: Load from collection
  }

  /// Returns the highest sequential ID received so far.
  @override
  IdType? getLastReceivedId() => _lastId;

  /// The highest sequential ID received so far.
  IdType? get lastId => _lastId;
  /// Returns whether the given [id] is currently tracked as missing.
  bool isMissing(IdType id) => _missingIds.contains(id);
  /// Returns the sorted list of currently missing IDs.
  List<IdType> getMissingIds() =>
      _missingIds.toList()..sort();
}
