import 'dart:collection';

import 'package:iermes/iermes.dart';

/// Deduplication set of processed integrity hashes, bounded by age
/// (RFC ermes-protocol sections 7.1 and 10.2).
///
/// Each hash is remembered for [retention] after it was first added and is
/// then forgotten, so a long-lived connection keeps at most one retention
/// window of hashes instead of one per message ever received. Pruning is by
/// age, never by count, so a duplicate inside the window is still rejected.
class ProcessedHashWindow extends SetBase<String> {
  /// Creates an empty window; [nowMs] defaults to the wall clock.
  ProcessedHashWindow({Duration? retention, int Function()? nowMs})
      : retention =
            retention ?? ErmesProtocolParameters.current.retentionWindow,
        _nowMs = nowMs ?? _wallClockMs;

  /// How long a hash is remembered.
  final Duration retention;
  final int Function() _nowMs;

  /// Hash -> time it was added; insertion order equals time order.
  final LinkedHashMap<String, int> _addedAtMs = LinkedHashMap<String, int>();

  static int _wallClockMs() => DateTime.now().millisecondsSinceEpoch;

  /// Drops every hash older than [retention].
  void prune() {
    final cutoff = _nowMs() - retention.inMilliseconds;
    while (_addedAtMs.isNotEmpty && _addedAtMs.values.first <= cutoff) {
      _addedAtMs.remove(_addedAtMs.keys.first);
    }
  }

  @override
  bool add(String value) {
    prune();
    if (_addedAtMs.containsKey(value)) {
      return false;
    }
    _addedAtMs[value] = _nowMs();
    return true;
  }

  @override
  bool contains(Object? element) {
    prune();
    return _addedAtMs.containsKey(element);
  }

  @override
  String? lookup(Object? element) => contains(element) && element is String
      ? element
      : null;

  @override
  bool remove(Object? value) => _addedAtMs.remove(value) != null;

  @override
  Iterator<String> get iterator {
    prune();
    return _addedAtMs.keys.iterator;
  }

  @override
  int get length {
    prune();
    return _addedAtMs.length;
  }

  @override
  Set<String> toSet() => _addedAtMs.keys.toSet();
}
