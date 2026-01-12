import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// Repository implementation for ID generation
@includeInBarrelFile
class IdHandlerRepository implements IIdHandlerRepository {
  IdHandlerRepository({this.startCounter = 0, this.maxCounter})
    : _counter = startCounter;

  final int startCounter;
  final int? maxCounter;
  int _counter;

  /// JavaScript's MAX_SAFE_INTEGER as default max
  static const int defaultMaxCounter = 9007199254740991;

  @override
  IdType getNewId() {
    final max = maxCounter ?? defaultMaxCounter;

    if (_counter >= max) {
      throw StateError('ID counter exceeded maximum value: $max');
    }

    return _counter++;
  }

  @override
  void reset() {
    _counter = startCounter;
  }

  @override
  void setCounter(IdType counter) {
    final max = maxCounter ?? defaultMaxCounter;

    if (counter < 0) {
      throw ArgumentError('Counter cannot be negative: $counter');
    }

    if (counter > max) {
      throw ArgumentError('Counter exceeds maximum: $counter > $max');
    }

    _counter = counter;
  }

  @override
  IdType getCurrent() => _counter;

  /// Get the maximum allowed counter value
  int getMaxCounter() => maxCounter ?? defaultMaxCounter;

  /// Get the starting counter value
  int getStartCounter() => startCounter;

  /// Check if the counter is at maximum
  bool isAtMaximum() {
    final max = maxCounter ?? defaultMaxCounter;
    return _counter >= max;
  }

  /// Get the number of IDs that can still be generated
  int getRemainingIds() {
    final max = maxCounter ?? defaultMaxCounter;
    return (max - _counter).clamp(0, max);
  }
}
