import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Registry for polymorphic serialization/deserialization of Ermes types
///
/// Provides a single source of truth for mapping types to their fromJson
/// factory methods, enabling extensible deserialization without switch
/// statements.
@includeInBarrelFile
class SerializationRegistry {
  // Private constructor to prevent instantiation
  SerializationRegistry._();

  /// Map of Type -> fromJson factory function
  static final _fromJsonRegistry =
      <Type, Object Function(Map<String, dynamic>)>{
    MessageRoot: MessageRoot.fromJson,
    InternalMessage: InternalMessage.fromJson,
    MessageData: MessageData.fromJson,
    ChunkMessage: ChunkMessage.fromJson,
    ChunkInfo: ChunkInfo.fromJson,
    ServiceMessage: ServiceMessage.fromJson,
    MessageType: MessageType.fromJson,
  };

  /// Register a custom fromJson factory for a type
  ///
  /// This allows users of the registry to extend it with their own types
  static void register<T>(
    Object Function(Map<String, dynamic>) fromJsonFactory,
  ) {
    _fromJsonRegistry[T] = fromJsonFactory;
  }

  /// Get the fromJson factory for a type
  ///
  /// Throws [ArgumentError] if the type is not registered
  static Object Function(Map<String, dynamic>) getFactory<T>() {
    final factory = _fromJsonRegistry[T];
    if (factory == null) {
      throw ArgumentError(
        'No deserialization factory registered for type: $T. '
        'Register it using SerializationRegistry.register<$T>()',
      );
    }
    return factory;
  }

  /// Get all registered types
  static List<Type> getRegisteredTypes() =>
      _fromJsonRegistry.keys.toList();

  /// Check if a type has a registered factory
  static bool isRegistered<T>() => _fromJsonRegistry.containsKey(T);
}
