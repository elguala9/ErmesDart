
import 'package:iermes/iermes.dart';

/// Repository for managing ID generation with a configurable range.
///
/// Ids are never reused within a connection (RFC ermes-protocol 7.2): once
/// [_max] has been issued, [getNewId] throws instead of wrapping to zero.
class IdHandlerRepository implements IIdHandlerRepository {
  /// Creates an IdHandlerRepository
  ///
  /// [max] - Maximum allowed ID value (inclusive); exhaustion throws
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
  /// Maximum allowed ID value (inclusive); the last id ever issued.
  final int _max;

  /// Returns the current ID and advances the counter. Throws
  /// [ErmesValidationException] once every id up to [_max] has been issued:
  /// wrapping would alias old ids (RFC 7.2); open a new connection instead.
  @override
  int getNewId() {
    final id = _current;
    if (id > _max) {
      throw ErmesValidationException(
        'Id space exhausted (max $_max): ids must not be reused',
      );
    }
    _current = id + 1;
    return id;
  }

  /// Resets the counter back to zero. Only valid before the first id of a
  /// connection is issued (or for a fresh connection): ids must not be reused.
  @override
  void reset() {
    _current = 0;
  }

  /// Sets the counter to [counter], validating it is within the allowed range.
  /// Only valid before the first id of a connection is issued (or for a fresh
  /// connection): moving it back would reuse ids (RFC 7.2).
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
