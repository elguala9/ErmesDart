import 'dart:convert';
import 'dart:typed_data';

import 'serialization_registry.dart';

/// Deserializes UTF-8 encoded JSON bytes into the registered Ermes type [T].
///
/// Dispatches through [SerializationRegistry] so the same call site works
/// for any registered message type. Throws [ArgumentError] when [T] is not
/// registered.
T uint8ArrayToObject<T>(Uint8List data) {
  final jsonString = utf8.decode(data);
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final factory = SerializationRegistry.getFactory<T>();
  return factory(json) as T;
}

/// Identity helper kept for API compatibility with older call sites that
/// expected an explicit `Uint8List -> Uint8List` conversion step.
Uint8List uint8ArrayToArrayBuffer(Uint8List data) => data;
