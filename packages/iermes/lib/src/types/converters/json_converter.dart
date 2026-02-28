

/// JSON converter interface
abstract class JsonConverter<T, S> {
  T fromJson(S json);
  S toJson(T object);
}
