

import '../../iermes.dart';

/// Private interface for ID handler operations
abstract class _IIdHandlerPrivate {
  /// Get a new unique ID
  ///
  /// Returns a unique ID that increments progressively with each call
  IdType getNewId();

  /// Reset the ID counter
  void reset();
}

/// Repository interface for ID generation
///
/// This interface is used to create unique IDs for messages in the
/// repository layer.
abstract class IIdHandlerRepository implements _IIdHandlerPrivate {
  /// Set the counter from which ID generation should begin
  ///
  /// [counter] The starting point of the counter
  void setCounter(IdType counter);

  /// Get the current counter value without incrementing
  ///
  /// Returns the current ID value
  IdType getCurrent();
}

/// Service interface for ID generation
///
/// This interface is used to create unique IDs for messages in the service
/// layer.
abstract class IIdHandlerService implements _IIdHandlerPrivate {
  /// Set the counter from which ID generation should begin
  ///
  /// [counter] The starting point of the counter
  void setCounter(IdType counter);

  /// Get the current counter value without incrementing
  ///
  /// Returns the current ID value
  IdType getCurrent();
}
