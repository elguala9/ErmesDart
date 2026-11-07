import 'package:iermes/iermes.dart';

import 'missing_range_recorder.dart';

/// Repository implementation of message control that handles ID tracking and
/// gap detection

class ErmesMessageControlRepository implements IErmesMessageControlRepository {
  /// Set of IDs detected as missing (gaps) in the received sequence.
  final Set<IdType> _missingIds = {};
  /// The highest ID seen so far, used for gap detection (RFC section 9.1).
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

    _cleanIdArrived(id);
  }

  /// Handles the first received [id], marking any IDs before it as missing.
  void _handleInitialId(IdType id) {
    _lastId = id;
    if (recordMissingRange(_missingIds, 1, id - 1)) {
      _notifyMissingIds();
    }
  }

  /// Records the IDs skipped between the last ID and [id] as missing.
  void _handleSequenceGap(IdType id) {
    recordMissingRange(_missingIds, _lastId! + 1, id - 1);
    _lastId = id;
    _notifyMissingIds();
  }

  /// Records (highest seen, [id]] as missing (RFC section 9.2); the range
  /// is not marked received, and highest seen moves to [id] so a later real
  /// arrival is treated as a filled gap rather than a new one.
  @override
  void counterpartCurrentId(IdType id) {
    final from = (_lastId ?? 0) + 1;
    if (id < from) {
      return;
    }
    recordMissingRange(_missingIds, from, id);
    _lastId = id;
    _notifyMissingIds();
  }

  /// Notifies the registered callback with the sorted list of missing IDs.
  void _notifyMissingIds() {
    _callbackIdsToRequest?.call(_missingIds.toList()..sort());
  }

  /// Removes a previously missing [id] now that it has arrived.
  ///
  /// An id that is not missing is a duplicate and is silently ignored.
  void _cleanIdArrived(IdType id) {
    _missingIds.remove(id);
  }

  /// Stops tracking [id] as missing: the peer reported it as gone.
  @override
  void idGone(IdType id) => _missingIds.remove(id);

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
  ///
  /// The highest contiguous ID jumps to the highest seen ID: the caller gives
  /// up on the cleared ids.
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

  /// Returns the highest contiguous ID received (RFC section 9.1).
  @override
  IdType? getLastReceivedId() => highestContiguousId;

  /// The highest ID seen so far (used for gap detection).
  IdType? get lastId => _lastId;

  /// The highest ID such that every ID from 1 up to it has arrived.
  ///
  /// Null before the first ID; 0 when ID 1 is still missing.
  IdType? get highestContiguousId {
    if (_lastId == null || _missingIds.isEmpty) {
      return _lastId;
    }
    return _missingIds.reduce((a, b) => a < b ? a : b) - 1;
  }
  /// Returns whether the given [id] is currently tracked as missing.
  bool isMissing(IdType id) => _missingIds.contains(id);
  /// Returns the sorted list of currently missing IDs.
  List<IdType> getMissingIds() =>
      _missingIds.toList()..sort();
}
