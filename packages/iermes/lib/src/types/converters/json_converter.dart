

/// JSON converter interface
abstract class JsonConverter<T, S> {
  /// Converts the serialized form [json] back into an object of type [T].
  T fromJson(S json);
  /// Converts [object] into its serialized form of type [S].
  S toJson(T object);
}
