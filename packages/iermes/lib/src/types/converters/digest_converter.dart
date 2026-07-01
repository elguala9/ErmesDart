
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'json_converter.dart';

/// JsonConverter for Digest serialization (hex encoding)
class DigestConverter implements JsonConverter<Digest?, String?> {
  /// Creates a const digest converter.
  const DigestConverter();

  /// Decodes a hex string into a [Digest], or null when input is null.
  @override
  Digest? fromJson(String? json) =>
      json != null ? Digest(hex.decode(json)) : null;

  /// Encodes a [Digest] as a hex string, or null when input is null.
  @override
  String? toJson(Digest? object) =>
      object != null ? hex.encode(object.bytes) : null;
}
