

import '../../iermes.dart';

/// Private interface for ID handler operations
abstract class _IIdHandlerPrivate {
  /// Get a new unique ID
  ///
  /// Returns a unique ID that increments progressively with each call.
  /// Ids MUST NOT be reused within a connection (RFC ermes-protocol 7.2):
  /// once the id space is exhausted this throws [ErmesValidationException]
  /// instead of wrapping.
  IdType getNewId();

  /// Reset the ID counter. Only valid before the first id of a connection
  /// is issued, or for a fresh connection, since it would reuse ids.
  void reset();
}

/// Repository interface for ID generation
///
/// This interface is used to create unique IDs for messages in the
/// repository layer.
abstract class IIdHandlerRepository implements _IIdHandlerPrivate {
  /// Set the counter from which ID generation should begin
  ///
  /// [counter] The starting point of the counter. Only valid before the
  /// first id of a connection is issued, or for a fresh connection.
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
  /// [counter] The starting point of the counter. Only valid before the
  /// first id of a connection is issued, or for a fresh connection.
  void setCounter(IdType counter);

  /// Get the current counter value without incrementing
  ///
  /// Returns the current ID value
  IdType getCurrent();
}
