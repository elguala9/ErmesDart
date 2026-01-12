import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// Service implementation for ID generation
@includeInBarrelFile
class IdHandlerService implements IIdHandlerService {
  IdHandlerService({this.startCounter = 0, this.maxCounter})
    : _counter = startCounter;

  final int startCounter;
  final int? maxCounter;
  int _counter;

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

  /// Get the current counter value (service-specific utility)
  IdType getCurrentId() => _counter;

  /// Get the maximum allowed counter value
  int getMaxCounter() => maxCounter ?? defaultMaxCounter;

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

  /// Create a new service instance with same configuration
  IdHandlerService clone() =>
      IdHandlerService(startCounter: startCounter, maxCounter: maxCounter);
}
