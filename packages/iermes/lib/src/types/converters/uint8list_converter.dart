import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'json_converter.dart';

/// JsonConverter for Uint8List serialization (base64 encoding)
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => Uint8List.fromList(base64Decode(json));

  @override
  String toJson(Uint8List object) => base64Encode(object);
}
