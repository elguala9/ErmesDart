import 'dart:convert';
import 'dart:typed_data';

import 'package:iermes/iermes.dart';

/// Serializes an [IErmesSerializable] to UTF-8 encoded JSON bytes.
Uint8List objectToUint8Array(IErmesSerializable obj) {
  final json = obj.toJson();
  final jsonString = jsonEncode(json);
  return Uint8List.fromList(utf8.encode(jsonString));
}
