import 'dart:convert';
import 'dart:typed_data';

/// Wire-format helpers for [ECDHKeyExchangeService].
///
/// The serialized binary layout is:
///   [expirationMs: 8B][pubKeyLen: 2B][publicKey][privKeyLen: 2B][privateKey]
/// Encoded as unpadded base64url for compact transport. Kept as
/// top-level utilities so the main service class stays focused on
/// key-exchange logic.

/// Convert 64-bit unsigned integer to 8 bytes (big-endian).
Uint8List uint64ToBytes(int value) {
  final bytes = Uint8List(8);
  for (var i = 0; i < 8; i++) {
    bytes[i] = (value >> (56 - i * 8)) & 0xFF;
  }
  return bytes;
}

/// Read a big-endian uint64 from the first 8 bytes of [bytes].
int bytesToUint64(Uint8List bytes) {
  if (bytes.length < 8) {
    throw const FormatException('Need at least 8 bytes for uint64');
  }
  var value = 0;
  for (var i = 0; i < 8; i++) {
    value = (value << 8) | bytes[i];
  }
  return value;
}

/// Normalize a hex string: strip whitespace and 0x prefix, lower-case,
/// pad to even length so it can be decoded byte-by-byte.
String cleanHexString(String hex) {
  var cleaned = hex
      .trim()
      .replaceFirst(RegExp('^0x', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '')
      .toLowerCase();
  if (cleaned.length % 2 != 0) {
    cleaned = '0$cleaned';
  }
  return cleaned;
}

/// Convert a previously [cleanHexString]-normalized string to bytes.
Uint8List hexStringToBytes(String hex) {
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return bytes;
}

/// Encode bytes as unpadded base64url for compact transport.
String bytesToBase64Url(Uint8List bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// Inverse of [bytesToBase64Url]: restores padding before decoding.
Uint8List base64UrlToBytes(String base64urlString) {
  final padding = (4 - (base64urlString.length % 4)) % 4;
  final padded = base64urlString + ('=' * padding);
  return Uint8List.fromList(base64Url.decode(padded));
}
