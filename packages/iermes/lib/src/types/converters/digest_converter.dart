import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'json_converter.dart';

/// JsonConverter for Digest serialization (hex encoding)
@includeInBarrelFile
class DigestConverter implements JsonConverter<Digest?, String?> {
  const DigestConverter();

  @override
  Digest? fromJson(String? json) =>
      json != null ? Digest(hex.decode(json)) : null;

  @override
  String? toJson(Digest? object) =>
      object != null ? hex.encode(object.bytes) : null;
}
