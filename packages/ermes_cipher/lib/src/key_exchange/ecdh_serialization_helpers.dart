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

/// Read a 2-byte length-prefixed UTF-8 string from [buffer] at [offset].
/// Returns the decoded value and the offset just past the payload.
({String value, int nextOffset}) readLengthPrefixedString(
  Uint8List buffer,
  int offset,
) {
  if (offset + 2 > buffer.length) {
    throw const FormatException(
      'Invalid serialized data: cannot read length prefix',
    );
  }
  final len = ((buffer[offset] & 0xFF) << 8) | (buffer[offset + 1] & 0xFF);
  final dataStart = offset + 2;
  if (dataStart + len > buffer.length) {
    throw const FormatException(
      'Invalid serialized data: payload exceeds buffer',
    );
  }
  return (
    value: utf8.decode(buffer.sublist(dataStart, dataStart + len)),
    nextOffset: dataStart + len,
  );
}

/// Write [data] to [buffer] at [offset] with a 2-byte big-endian length
/// prefix. Returns the offset just past the written payload.
int writeLengthPrefixedBytes(Uint8List buffer, int offset, List<int> data) {
  buffer[offset] = (data.length >> 8) & 0xFF;
  buffer[offset + 1] = data.length & 0xFF;
  buffer.setRange(offset + 2, offset + 2 + data.length, data);
  return offset + 2 + data.length;
}

/// Encode key material into the binary wire format (see file header).
String serializeKeyData(int expirationMs, String publicKey, String privateKey) {
  final pubKeyPemBytes = utf8.encode(publicKey);
  final privKeyPemBytes = utf8.encode(privateKey);

  final bufferSize = 8 + 2 + pubKeyPemBytes.length + 2 + privKeyPemBytes.length;
  final buffer = Uint8List(bufferSize);
  var offset = 0;

  buffer.setRange(offset, offset + 8, uint64ToBytes(expirationMs));
  offset += 8;

  offset = writeLengthPrefixedBytes(buffer, offset, pubKeyPemBytes);
  writeLengthPrefixedBytes(buffer, offset, privKeyPemBytes);

  return bytesToBase64Url(buffer);
}

/// Decode the binary wire format back into key material. [fallbackHours]
/// supplies an expiration when the serialized value carries none.
({DateTime expirationDate, String publicKey, String privateKey})
    deserializeKeyData(String serialized, int fallbackHours) {
  final buffer = base64UrlToBytes(serialized);
  if (buffer.length < 8) {
    throw const FormatException('Invalid serialized data: too short');
  }

  var offset = 0;
  final expirationMs = bytesToUint64(buffer.sublist(offset, offset + 8));
  final expirationDate = expirationMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(expirationMs)
      : DateTime.now().add(Duration(hours: fallbackHours));
  offset += 8;

  final pubRead = readLengthPrefixedString(buffer, offset);
  offset = pubRead.nextOffset;
  final privRead = readLengthPrefixedString(buffer, offset);

  return (
    expirationDate: expirationDate,
    publicKey: pubRead.value,
    privateKey: privRead.value,
  );
}
