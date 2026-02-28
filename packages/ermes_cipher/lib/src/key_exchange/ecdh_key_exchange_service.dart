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

class ECDHKeyExchangeService implements IKeyExchange, IECDHKeyExchangeService {
  ECDHKeyExchangeService(IKeyExchange exchange, this.symmetricAlgorithm) {
    if (exchange.algorithm != KeyExchangeAlgorithm.ecdh) {
      throw Exception('ECDHKeyExchangeService needs ECDH IKeyExchange');
    }
    _exchange = exchange;
  }

  /// Deserialize from compact binary format (base64url encoded)
  ///
  /// Restores the key exchange service from a serialized binary string.
  /// Reads back the original PEM format that was stored during
  /// serialization.
  factory ECDHKeyExchangeService.deserialize(
      String serialized, [CryptoAlgorithm? symmetricAlg]) {
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
      throw const FormatException(
        'Invalid serialized data: cannot read public key length',
      );
    }
    final pubKeyLen =
        ((buffer[offset] & 0xFF) << 8) | (buffer[offset + 1] & 0xFF);
    offset += 2;

    // Read public key PEM string
    if (offset + pubKeyLen > buffer.length) {
      throw const FormatException(
        'Invalid serialized data: cannot read public key',
      );
    }
    final publicKeyBytes = buffer.sublist(offset, offset + pubKeyLen);
    final publicKey = utf8.decode(publicKeyBytes);
    offset += pubKeyLen;

    // Read private key length (2 bytes, big-endian)
    if (offset + 2 > buffer.length) {
      throw const FormatException(
        'Invalid serialized data: cannot read private key length',
      );
    }
    final privKeyLen =
        ((buffer[offset] & 0xFF) << 8) | (buffer[offset + 1] & 0xFF);
    offset += 2;

    // Read private key PEM string
    if (offset + privKeyLen > buffer.length) {
      throw const FormatException(
        'Invalid serialized data: cannot read private key',
      );
    }
    final privateKeyBytes = buffer.sublist(offset, offset + privKeyLen);
    final privateKey = utf8.decode(privateKeyBytes);

    // Recreate the key exchange with original PEM keys
    final exchange = ECDHKeyExchange(InputECDHKeyExchange(
      parent: InputKeyExchangeBase(
        algorithm: KeyExchangeAlgorithm.ecdh,
        expirationDate: expirationDate,
      ),
      publicKey: publicKey,
      privateKey: privateKey,
      curve: ECCKeyUtils.secp256r1,
    ));

    return ECDHKeyExchangeService(
      exchange,
      symmetricAlg ?? defaultSymmetricValue,
    );
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
  /// Format: [expirationMs:8 bytes][pubKeyLen:2 bytes][publicKey]
  /// [privKeyLen:2 bytes][privateKey]
  /// Stores the original PEM format from CryptDart to ensure compatibility
  /// on deserialization
  @override
  String serialize() {
    // Convert timestamp to 8 bytes (milliseconds since epoch)
    final expirationMs = expirationDate?.millisecondsSinceEpoch ?? 0;
    final expirationBytes = _uint64ToBytes(expirationMs);

    // Convert PEM strings to bytes
    final pubKeyPemBytes = utf8.encode(publicKey);
    final privKeyPemBytes = utf8.encode(privateKey);

    // Calculate total buffer size
    final bufferSize =
        8 + 2 + pubKeyPemBytes.length + 2 + privKeyPemBytes.length;
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

  /// Generate a new ECDH key exchange service instance
  ///
  /// Creates a fresh instance with a new random P-256 key pair.
  static Future<IECDHKeyExchangeService> generateNew(
      [CryptoAlgorithm? symmetricAlg]) async {
    final keyPair = await ECDHKeyExchange.generateKeyPair();
    final expiration = DateTime.now().add(
      const Duration(hours: keyDurationHours),
    );
    final exchange = ECDHKeyExchange(InputECDHKeyExchange(
      parent: InputKeyExchangeBase(
        algorithm: KeyExchangeAlgorithm.ecdh,
        expirationDate: expiration,
      ),
      publicKey: keyPair['publicKey']!,
      privateKey: keyPair['privateKey']!,
      curve: ECCKeyUtils.secp256r1,
    ));
    return ECDHKeyExchangeService(
      exchange,
      symmetricAlg ?? defaultSymmetricValue,
    );
  }

  /// Generate an ECDH key exchange service from a serialized string
  ///
  /// Deserializes a previously serialized key exchange service.
  /// This is the implementation of the interface's static factory method.
  static IECDHKeyExchangeService generateFromSerialize(
    String serialization,
  ) =>
      ECDHKeyExchangeService.deserialize(serialization);

  /// Generate a ISymmetric from the remote peer's serialized key
  ///
  /// Deserializes the remote peer's key and creates a cipher
  /// that uses the ECDH shared secret for encryption/decryption.
  @override
  ISymmetricCipher generateISymmetric(
      String serialization, [CryptoAlgorithm? symmetricAlg]) {
    // Deserialize the remote peer's key
    final remoteKey = ECDHKeyExchangeService.deserialize(serialization);

    // Generate the shared secret
    final sharedSecret = generateSharedSecret(remoteKey.publicKey);

    // Ensure the shared secret has even length for hex encoding
    final cleanedSecret = _cleanHexString(sharedSecret);

    // Convert hex string to actual bytes for the cipher
    final secretBytes = _hexStringToBytes(cleanedSecret);

    // Create a cipher using the shared secret for encryption/decryption
    return generateSymmetric(
      secretBytes,
      symmetricAlg ?? defaultSymmetricValue,
    );
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

  /// Convert hex string to bytes
  static Uint8List _hexStringToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
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
