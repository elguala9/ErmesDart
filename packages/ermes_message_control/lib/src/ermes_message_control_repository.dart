
import 'package:iermes/iermes.dart';

import 'exceptions.dart';


/// Storage type for message control data

class MessageControlData {
  MessageControlData({required this.timestamp, this.missingIds});
  final List<IdType>? missingIds;
  final int timestamp;

  Map<String, dynamic> toMap() => {
    'missing_ids': missingIds,
    'timestamp': timestamp,
  };
}

/// Repository implementation of message control that handles ID tracking and
/// gap detection

class ErmesMessageControlRepository implements IErmesMessageControlRepository {
  final Set<IdType> _missingIds = {};
  IdType? _lastId;
  CallbackIdsToRequest? _callbackIdsToRequest;

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

  void _handleInitialId(IdType id) {
    _lastId = id;
    if (id > 1) {
      for (var i = 1; i < id; i++) {
        _missingIds.add(i);
      }
      _notifyMissingIds();
    }
  }

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

  void _notifyMissingIds() {
    _callbackIdsToRequest?.call(_missingIds.toList()..sort());
  }

  void _cleanIdArrived(IdType id) {
    if (!_missingIds.contains(id)) {
      throw MessageControlException('ID: $id, is not missing');
    }
    _missingIds.remove(id);
  }

  @override
  Future<List<IdType>> idsToRequest() async => _missingIds.toList()..sort();

  @override
  int numberOfMissingIds() => _missingIds.length;

  @override
  void setCallbackIdsToRequest(CallbackIdsToRequest callback) {
    _callbackIdsToRequest = callback;
  }

  @override
  Future<void> clear() async {
    _missingIds.clear();
  }

  @override
  Future<void> destroy() async {
    _missingIds.clear();
    _lastId = null;
    _callbackIdsToRequest = null;
  }

  @override
  Future<void> saveState() async {
    // SaveState: Save missing IDs and lastId to persistent storage
  }

  Future<void> loadState() async {
    // LoadState: Load from collection
  }

  @override
  IdType? getLastReceivedId() => _lastId;

  IdType? get lastId => _lastId;
  bool isMissing(IdType id) => _missingIds.contains(id);
  List<IdType> getMissingIds() =>
      _missingIds.toList()..sort();
}
