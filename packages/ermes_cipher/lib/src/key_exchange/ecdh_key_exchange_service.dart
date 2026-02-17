// ignore_for_file: conflicting_field_and_method
import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';

import '../factories/ermes_cipher_factories.dart';

const int keyDurationHours = 24;

final CryptoAlgorithm defaultSymmetricValue = SymmetricCipherAlgorithmEnum.aes;

/// ECDH key exchange service implementing CryptDart's IKeyExchange
///
/// Direct implementation of IKeyExchange from CryptDart library.
/// Ready to be injected as a dependency in the application.
@includeInBarrelFile
class ECDHKeyExchangeService implements IKeyExchange, IECDHKeyExchangeService {
  ECDHKeyExchangeService(IKeyExchange exchange, this.symmetricAlgorithm) {
    if (exchange.algorithm != KeyExchangeAlgorithm.ecdh) {
      throw Exception('ECDHKeyExchangeService needs ECDH IKeyExchange');
    }
    _exchange = exchange;
  }

  late IKeyExchange _exchange;
  final CryptoAlgorithm symmetricAlgorithm;

  @override
  KeyExchangeAlgorithm get algorithm => _exchange.algorithm;

  @override
  String get publicKey => _exchange.publicKey;

  @override
  String get privateKey => _exchange.privateKey;

  @override
  DateTime? get expirationDate => _exchange.expirationDate;

  @override
  int? get expirationTimes => _exchange.expirationTimes;

  @override
  int? get expirationTimesRemaining => _exchange.expirationTimesRemaining;

  @override
  bool isExpired() => _exchange.isExpired();

  @override
  String getPublicKey() => _exchange.getPublicKey();

  /// Generate a new ECDH key pair using P-256 curve
  ///
  /// Must be called before any other operations.
  Future<void> generateKeyPair({
    Duration expiration = const Duration(hours: keyDurationHours),
  }) async {
    final keyPair = await ECDHKeyExchange.generateKeyPair();

    _exchange = ECDHKeyExchange(InputECDHKeyExchange(
      parent: InputKeyExchangeBase(
        algorithm: KeyExchangeAlgorithm.ecdh,
        expirationDate: DateTime.now().add(expiration),
        expirationTimes: null,
      ),
      publicKey: keyPair['publicKey']!,
      privateKey: keyPair['privateKey']!,
      curve: ECCKeyUtils.secp256r1,
    ));
  }

  /// Compute shared secret with remote public key
  ///
  /// Delegates to CryptDart's IKeyExchange.generateSharedSecret()
  @override
  String generateSharedSecret(String otherPublicKey) =>
      _exchange.generateSharedSecret(otherPublicKey);

  /// Serialize to compact binary format encoded as base64url
  ///
  /// Format: [expirationMs:8 bytes][pubKeyLen:2 bytes][publicKey][privKeyLen:2 bytes][privateKey]
  /// Stores the original PEM format from CryptDart to ensure compatibility on deserialization
  @override
  String serialize() {
    // Convert timestamp to 8 bytes (milliseconds since epoch)
    final expirationMs = expirationDate?.millisecondsSinceEpoch ?? 0;
    final expirationBytes = _uint64ToBytes(expirationMs);

    // Convert PEM strings to bytes
    final pubKeyPemBytes = utf8.encode(publicKey);
    final privKeyPemBytes = utf8.encode(privateKey);

    // Calculate total buffer size
    final bufferSize = 8 + 2 + pubKeyPemBytes.length + 2 + privKeyPemBytes.length;
    final buffer = Uint8List(bufferSize);
    var offset = 0;

    // Write expiration timestamp (8 bytes)
    buffer.setRange(offset, offset + 8, expirationBytes);
    offset += 8;

    // Write public key length (2 bytes, big-endian)
    buffer[offset] = (pubKeyPemBytes.length >> 8) & 0xFF;
    buffer[offset + 1] = pubKeyPemBytes.length & 0xFF;
    offset += 2;

    // Write public key PEM
    buffer.setRange(offset, offset + pubKeyPemBytes.length, pubKeyPemBytes);
    offset += pubKeyPemBytes.length;

    // Write private key length (2 bytes, big-endian)
    buffer[offset] = (privKeyPemBytes.length >> 8) & 0xFF;
    buffer[offset + 1] = privKeyPemBytes.length & 0xFF;
    offset += 2;

    // Write private key PEM
    buffer.setRange(offset, offset + privKeyPemBytes.length, privKeyPemBytes);

    // Encode as base64url
    return _bytesToBase64Url(buffer);
  }

  /// Deserialize from compact binary format (base64url encoded)
  ///
  /// Restores the key exchange service from a serialized binary string.
  /// Reads back the original PEM format that was stored during serialization.
  static ECDHKeyExchangeService deserialize(String serialized, [CryptoAlgorithm? symmetricAlg]) {
    // Decode base64url to bytes
    final buffer = _base64UrlToBytes(serialized);

    if (buffer.length < 8) {
      throw const FormatException('Invalid serialized data: too short');
    }

    var offset = 0;

    // Read expiration timestamp (8 bytes)
    final expirationBytes = buffer.sublist(offset, offset + 8);
    final expirationMs = _bytesToUint64(expirationBytes);
    final expirationDate = expirationMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(expirationMs)
        : DateTime.now().add(const Duration(hours: keyDurationHours));
    offset += 8;

    // Read public key length (2 bytes, big-endian)
    if (offset + 2 > buffer.length) {
      throw const FormatException('Invalid serialized data: cannot read public key length');
    }
    final pubKeyLen = ((buffer[offset] & 0xFF) << 8) | (buffer[offset + 1] & 0xFF);
    offset += 2;

    // Read public key PEM string
    if (offset + pubKeyLen > buffer.length) {
      throw const FormatException('Invalid serialized data: cannot read public key');
    }
    final publicKeyBytes = buffer.sublist(offset, offset + pubKeyLen);
    final publicKey = utf8.decode(publicKeyBytes);
    offset += pubKeyLen;

    // Read private key length (2 bytes, big-endian)
    if (offset + 2 > buffer.length) {
      throw const FormatException('Invalid serialized data: cannot read private key length');
    }
    final privKeyLen = ((buffer[offset] & 0xFF) << 8) | (buffer[offset + 1] & 0xFF);
    offset += 2;

    // Read private key PEM string
    if (offset + privKeyLen > buffer.length) {
      throw const FormatException('Invalid serialized data: cannot read private key');
    }
    final privateKeyBytes = buffer.sublist(offset, offset + privKeyLen);
    final privateKey = utf8.decode(privateKeyBytes);

    // Recreate the key exchange with original PEM keys
    final exchange = ECDHKeyExchange(InputECDHKeyExchange(
      parent: InputKeyExchangeBase(
        algorithm: KeyExchangeAlgorithm.ecdh,
        expirationDate: expirationDate,
        expirationTimes: null,
      ),
      publicKey: publicKey,
      privateKey: privateKey,
      curve: ECCKeyUtils.secp256r1,
    ));

    return ECDHKeyExchangeService(exchange, symmetricAlg ?? defaultSymmetricValue);

  }

  /// Generate a new ECDH key exchange service instance
  ///
  /// Creates a fresh instance with a new random P-256 key pair.
  static Future<IECDHKeyExchangeService> generateNew([CryptoAlgorithm? symmetricAlg]) async {
    final keyPair = await ECDHKeyExchange.generateKeyPair();
    final expiration = DateTime.now().add(
      const Duration(hours: keyDurationHours),
    );
    final exchange = ECDHKeyExchange(InputECDHKeyExchange(
      parent: InputKeyExchangeBase(
        algorithm: KeyExchangeAlgorithm.ecdh,
        expirationDate: expiration,
        expirationTimes: null,
      ),
      publicKey: keyPair['publicKey']!,
      privateKey: keyPair['privateKey']!,
      curve: ECCKeyUtils.secp256r1,
    ));
    return ECDHKeyExchangeService(exchange, symmetricAlg ?? defaultSymmetricValue);
  }

  /// Generate an ECDH key exchange service from a serialized string
  ///
  /// Deserializes a previously serialized key exchange service.
  /// This is the implementation of the interface's static factory method.
  static IECDHKeyExchangeService generateFromSerialize(String serialization) 
    => deserialize(serialization);
  

  /// Generate a ISymmetric from the remote peer's serialized key
  ///
  /// Deserializes the remote peer's key and creates a cipher
  /// that uses the ECDH shared secret for encryption/decryption.
  @override
  ISymmetricCipher generateISymmetric(String serialization, [CryptoAlgorithm? symmetricAlg]) {
    // Deserialize the remote peer's key
    final remoteKey = deserialize(serialization);

    // Generate the shared secret
    final sharedSecret = generateSharedSecret(remoteKey.publicKey);

    // Ensure the shared secret has even length for hex encoding
    final cleanedSecret = _cleanHexString(sharedSecret);

    // Create a cipher using the shared secret for encryption/decryption
    return generateSymmetric(cleanedSecret, symmetricAlg ?? defaultSymmetricValue);
  }

  /// Convert 64-bit unsigned integer to bytes (big-endian)
  static Uint8List _uint64ToBytes(int value) {
    final bytes = Uint8List(8);
    bytes[0] = (value >> 56) & 0xFF;
    bytes[1] = (value >> 48) & 0xFF;
    bytes[2] = (value >> 40) & 0xFF;
    bytes[3] = (value >> 32) & 0xFF;
    bytes[4] = (value >> 24) & 0xFF;
    bytes[5] = (value >> 16) & 0xFF;
    bytes[6] = (value >> 8) & 0xFF;
    bytes[7] = value & 0xFF;
    return bytes;
  }

  /// Convert bytes to 64-bit unsigned integer (big-endian)
  static int _bytesToUint64(Uint8List bytes) {
    if (bytes.length < 8) {
      throw const FormatException('Need at least 8 bytes for uint64');
    }
    return (bytes[0] << 56) |
        (bytes[1] << 48) |
        (bytes[2] << 40) |
        (bytes[3] << 32) |
        (bytes[4] << 24) |
        (bytes[5] << 16) |
        (bytes[6] << 8) |
        bytes[7];
  }

  /// Clean hex string: remove whitespace, 0x prefix, and ensure even length
  static String _cleanHexString(String hex) {
    var cleaned = hex
        .trim()
        .replaceFirst(RegExp('^0x', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();

    // If length is odd, pad with leading zero
    if (cleaned.length % 2 != 0) {
      cleaned = '0$cleaned';
    }

    return cleaned;
  }

  /// Convert PEM format string to hex (if needed), handles both PEM and hex formats
  static String _pemToHexIfNeeded(String keyString) {
    keyString = keyString.trim();

    // Check if it's PEM format
    if (keyString.startsWith('-----BEGIN')) {
      // Extract the base64 content between markers
      final lines = keyString.split('\n');
      final base64Content = StringBuffer();

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (!trimmedLine.startsWith('-----') && trimmedLine.isNotEmpty) {
          base64Content.write(trimmedLine);
        }
      }

      // Decode base64 to bytes
      final keyBytes = base64Url.decode(base64Content.toString().replaceAll('-', '+').replaceAll('_', '/'));

      // For ECDH P-256 public key in X.509 format, we need to extract the raw key
      // The raw key is typically at position 26 for uncompressed point (65 bytes)
      // This is a simplified extraction - adjust offsets based on actual format
      if (keyBytes.length >= 91) {
        // Extract the public key point (typically starts around byte 26-27 for ECDH P-256)
        // Skip the ASN.1 structure and extract the 0x04 prefix + 65 bytes of uncompressed point
        final startIndex = keyBytes.length - 65;
        final keyPoint = keyBytes.sublist(startIndex);
        return _bytesToHex(keyPoint);
      }

      // Fallback: return the entire key as hex
      return _bytesToHex(keyBytes);
    }

    // Already in hex format
    return keyString;
  }

  /// Convert hex string to bytes
  static Uint8List _hexToBytes(String hex) {
    // First, convert from PEM if needed
    var cleanHex = _pemToHexIfNeeded(hex);

    // Clean the hex string: trim, remove 0x prefix, remove all whitespace, convert to lowercase
    cleanHex = cleanHex
        .trim()
        .replaceFirst(RegExp('^0x', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '')  // Remove all whitespace
        .toLowerCase();

    // Validate that hex string has even length (each byte = 2 hex chars)
    if (cleanHex.isEmpty) {
      throw const FormatException('Invalid hex string: empty after cleaning');
    }

    if (cleanHex.length % 2 != 0) {
      throw FormatException('Invalid hex string: odd length (${cleanHex.length}), expected even length. Original: "$hex"');
    }

    final bytes = Uint8List(cleanHex.length ~/ 2);
    for (var i = 0; i < cleanHex.length; i += 2) {
      try {
        bytes[i ~/ 2] = int.parse(cleanHex.substring(i, i + 2), radix: 16);
      } catch (e) {
        throw FormatException('Invalid hex characters at position $i: "${cleanHex.substring(i, i + 2)}", original: "$hex"');
      }
    }
    return bytes;
  }

  /// Convert bytes to hex string (without 0x prefix, lowercase)
  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();

  /// Convert bytes to simple PEM format (base64 wrapped with markers)
  /// This is much simpler than DER and works with CryptDart
  static String _bytesToSimplePem(Uint8List keyBytes, String keyType) {
    // Simply base64 encode the key bytes and wrap with PEM markers
    final base64Content = base64.encode(keyBytes);

    // Format with PEM markers and line wrapping
    final StringBuffer pem = StringBuffer();
    pem.writeln('-----BEGIN $keyType-----');

    // Wrap base64 content to 64 characters per line
    for (int i = 0; i < base64Content.length; i += 64) {
      pem.writeln(base64Content.substring(
        i,
        i + 64 > base64Content.length ? base64Content.length : i + 64,
      ));
    }

    pem.write('-----END $keyType-----');

    return pem.toString();
  }

  /// Convert bytes to PEM format (ECDH P-256 X.509) - DEPRECATED
  /// Use _bytesToSimplePem instead
  static String _bytesToPem(Uint8List keyBytes, {required bool isPrivate}) {
    // Kept for backward compatibility but not used
    // Use _bytesToSimplePem which works with CryptDart
    return _bytesToSimplePem(
      keyBytes,
      isPrivate ? 'EC PRIVATE KEY' : 'PUBLIC KEY',
    );
  }

  /// Construct ECDH P-256 public key DER structure
  static Uint8List _constructPublicKeyDER(Uint8List publicKeyPoint) {
    // OID for ecPublicKey: 1.2.840.10045.2.1
    const ecPublicKeyOid = [0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01];

    // OID for prime256v1 (P-256): 1.2.840.10045.3.1.7
    const prime256v1Oid = [0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x20];

    // Construct algorithm identifier sequence
    final algoIdBytes = Uint8List(2 + ecPublicKeyOid.length + 2 + prime256v1Oid.length);
    int offset = 0;
    algoIdBytes[offset++] = 0x30; // SEQUENCE
    algoIdBytes[offset++] = ecPublicKeyOid.length + 2 + prime256v1Oid.length;
    algoIdBytes.setRange(offset, offset + ecPublicKeyOid.length, ecPublicKeyOid);
    offset += ecPublicKeyOid.length;
    algoIdBytes.setRange(offset, offset + prime256v1Oid.length, prime256v1Oid);

    // BIT STRING for the public key
    final bitStringBytes = Uint8List(2 + 1 + publicKeyPoint.length);
    bitStringBytes[0] = 0x03; // BIT STRING
    bitStringBytes[1] = 1 + publicKeyPoint.length;
    bitStringBytes[2] = 0x00; // No unused bits
    bitStringBytes.setRange(3, 3 + publicKeyPoint.length, publicKeyPoint);

    // Final SEQUENCE wrapping
    final totalLength = 2 + algoIdBytes.length + 2 + bitStringBytes.length;
    final derBytes = Uint8List(2 + totalLength);
    derBytes[0] = 0x30; // SEQUENCE
    derBytes[1] = totalLength;
    derBytes.setRange(2, 2 + algoIdBytes.length, algoIdBytes);
    derBytes.setRange(2 + algoIdBytes.length, 2 + algoIdBytes.length + bitStringBytes.length, bitStringBytes);

    return derBytes;
  }

  /// Construct ECDH P-256 private key DER structure (SEC1 format)
  static Uint8List _constructPrivateKeyDER(Uint8List privateKeyBytes) {
    // For simplicity, return a basic structure
    // A proper implementation would include the full SEC1 structure
    // For now, wrap in a simple way that CryptDart can recognize

    // OID for prime256v1 (P-256): 1.2.840.10045.3.1.7
    const prime256v1Oid = [0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x20];

    // Version (1 byte) = 1
    final version = [0x02, 0x01, 0x01];

    // Private key as OCTET STRING
    final keyOctetString = Uint8List(2 + privateKeyBytes.length);
    keyOctetString[0] = 0x04; // OCTET STRING
    keyOctetString[1] = privateKeyBytes.length;
    keyOctetString.setRange(2, 2 + privateKeyBytes.length, privateKeyBytes);

    // Construct parameters [0] EXPLICIT
    final paramsExplicit = Uint8List(2 + prime256v1Oid.length);
    paramsExplicit[0] = 0xa0; // CONTEXT SPECIFIC [0]
    paramsExplicit[1] = prime256v1Oid.length;
    paramsExplicit.setRange(2, 2 + prime256v1Oid.length, prime256v1Oid);

    // Final SEQUENCE
    final totalLength = version.length + keyOctetString.length + paramsExplicit.length;
    final derBytes = Uint8List(2 + totalLength);
    derBytes[0] = 0x30; // SEQUENCE
    derBytes[1] = totalLength;

    int offset = 2;
    derBytes.setRange(offset, offset + version.length, version);
    offset += version.length;
    derBytes.setRange(offset, offset + keyOctetString.length, keyOctetString);
    offset += keyOctetString.length;
    derBytes.setRange(offset, offset + paramsExplicit.length, paramsExplicit);

    return derBytes;
  }

  /// Convert bytes to base64url string (compact, no padding)
  static String _bytesToBase64Url(Uint8List bytes) {
    final base64 = base64Url.encode(bytes);
    // Remove padding for more compact representation
    return base64.replaceAll('=', '');
  }

  /// Convert base64url string back to bytes
  static Uint8List _base64UrlToBytes(String base64urlString) {
    // Add back padding if needed
    var padded = base64urlString;
    final padding = (4 - (base64urlString.length % 4)) % 4;
    padded = base64urlString + ('=' * padding);
    final decoded = base64Url.decode(padded);
    return Uint8List.fromList(decoded);
  }
}
