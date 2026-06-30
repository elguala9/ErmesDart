import 'dart:typed_data';

/// Deterministic payload helpers shared by the load / reliability scenarios.
///
/// The sender builds a payload from a seed, the receiver recomputes the same
/// checksum from the bytes it reassembled, and the two are compared — proving
/// the transport delivered every byte intact (no silent truncation or chunk
/// reorder).
class NatPayload {
  const NatPayload._();

  /// Builds [size] deterministic bytes from [seed]. A linear-congruential walk
  /// keeps it cheap while still varying every byte (a constant fill would hide
  /// chunk-boundary bugs).
  static Uint8List build(int size, int seed) {
    final out = Uint8List(size);
    var x = (seed * 2654435761) & 0xffffffff;
    for (var i = 0; i < size; i++) {
      x = (x * 1103515245 + 12345) & 0xffffffff;
      out[i] = (x >> 16) & 0xff;
    }
    return out;
  }

  /// 32-bit FNV-1a checksum of [bytes]; stable across machines and runs.
  static int checksum(Uint8List bytes) {
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash = (hash ^ b) & 0xffffffff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
