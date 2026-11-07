import 'dart:convert';
import 'dart:typed_data';

import 'package:iermes/iermes.dart';

/// Serializes an [IErmesSerializable] to UTF-8 encoded JSON bytes.
Uint8List objectToUint8Array(IErmesSerializable obj) {
  final json = obj.toJson();
  final jsonString = jsonEncode(json);
  return Uint8List.fromList(utf8.encode(jsonString));
}

/// Serializes an outer envelope, overriding its `v` with [version] when
/// given (the version negotiated for the connection, RFC 7.1).
Uint8List envelopeToUint8Array(MessageRoot root, ProtocolVersion? version) {
  final json = root.toJson();
  if (version != null) {
    json['v'] = version.toString();
  }
  return Uint8List.fromList(utf8.encode(jsonEncode(json)));
}
