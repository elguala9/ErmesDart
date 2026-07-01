
import 'package:iermes/iermes.dart';

/// Repository for managing ID generation with configurable range and wrapping
class IdHandlerRepository implements IIdHandlerRepository {
  /// Creates an IdHandlerRepository
  ///
  /// [max] - Maximum allowed ID value (inclusive). When exceeded, wraps to 0
  /// [start] - Initial counter value (default 0)
  IdHandlerRepository({
    int max = 9007199254740990, // Last safe integer before MAX_SAFE_INTEGER
    int start = 0,
  }) : _max = max,
       _current = start {
    if (max < 1) {
      throw ArgumentError('`max` must be an integer >= 1');
    }
    if (start < 0 || start > max) {
      throw ArgumentError('`start` must be an integer between 0 and max');
    }
  }
  /// The current counter value that will be returned by the next call.
  int _current;
  /// Maximum allowed ID value (inclusive) before the counter wraps to zero.
  final int _max;

  /// Returns the current ID and advances the counter, wrapping past [_max].
  @override
  int getNewId() {
    final id = _current;
    _current = _current + 1;
    // If we've exceeded max, wrap to zero
    if (_current > _max) {
      _current = 0;
    }
    return id;
  }

  /// Resets the counter back to zero.
  @override
  void reset() {
    _current = 0;
  }

  /// Sets the counter to [counter], validating it is within the allowed range.
  @override
  void setCounter(int counter) {
    if (counter < 0 || counter > _max) {
      throw ArgumentError('ID must be an integer between 0 and $_max');
    }
    _current = counter;
  }

  /// Returns the current counter value without advancing it.
  @override
  int getCurrent() => _current;
}
