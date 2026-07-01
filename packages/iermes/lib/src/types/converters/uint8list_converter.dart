import 'dart:convert';
import 'dart:typed_data';



import 'json_converter.dart';

/// JsonConverter for Uint8List serialization (base64 encoding)
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  /// Creates a const byte-list converter.
  const Uint8ListConverter();

  /// Decodes a base64 string into a [Uint8List].
  @override
  Uint8List fromJson(String json) => Uint8List.fromList(base64Decode(json));

  /// Encodes a [Uint8List] as a base64 string.
  @override
  String toJson(Uint8List object) => base64Encode(object);
}
