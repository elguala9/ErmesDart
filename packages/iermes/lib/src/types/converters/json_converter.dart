import 'package:barrel_files_annotation/barrel_files_annotation.dart';

/// JSON converter interface
@includeInBarrelFile
abstract class JsonConverter<T, S> {
  T fromJson(S json);
  S toJson(T object);
}
