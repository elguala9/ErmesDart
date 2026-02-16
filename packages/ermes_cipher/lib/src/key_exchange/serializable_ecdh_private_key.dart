import 'dart:convert';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';

/// Implementation of ECDH key with serialization support
///
/// Stores P-256 elliptic curve private and public key data in serializable format.
/// The class manages key material as raw bytes and provides methods to
/// serialize/deserialize to string representation.
@includeInBarrelFile
class SerializableECDHPrivateKey {
  /// Private key bytes (P-256: 32 bytes)
  late final List<int> _privateKeyBytes;

  /// Public key bytes (P-256: 65 bytes, uncompressed format)
  late final List<int> _publicKeyBytes;

  /// Curve used for key generation
  static const String curveName = 'P-256';

  /// Private constructor for internal initialization
  SerializableECDHPrivateKey._internal(
    List<int> privateKeyBytes,
    List<int> publicKeyBytes,
  ) {
    _privateKeyBytes = List<int>.from(privateKeyBytes);
    _publicKeyBytes = List<int>.from(publicKeyBytes);
  }

  /// Create from existing key material
  ///
  /// Use this when you have pre-computed key bytes from another source.
  factory SerializableECDHPrivateKey.fromBytes({
    required List<int> privateKeyBytes,
    required List<int> publicKeyBytes,
  }) {
    if (privateKeyBytes.isEmpty || publicKeyBytes.isEmpty) {
      throw ArgumentError('Key bytes cannot be empty');
    }
    return SerializableECDHPrivateKey._internal(
      privateKeyBytes,
      publicKeyBytes,
    );
  }

  /// Get the private key bytes
  List<int> get privateKeyBytes => List<int>.from(_privateKeyBytes);

  /// Get the public key bytes
  List<int> get publicKeyBytes => List<int>.from(_publicKeyBytes);

  /// Get curve name
  String get curve => curveName;

  /// Generate a new random key pair using cryptdart
  ///
  /// Returns a new [SerializableECDHPrivateKey] with randomly generated P-256 keys.
  /// The keys are generated using cryptdart's ECDH implementation with secp256r1 curve.
  ///
  /// Throws [Exception] if key generation fails
  static Future<SerializableECDHPrivateKey> generateNew() async {
    final ecdhKeyPair = await _generateECDHKeyPair();
    return SerializableECDHPrivateKey._internal(
      ecdhKeyPair['private']!,
      ecdhKeyPair['public']!,
    );
  }

  /// Internal helper to generate ECDH key pair using cryptdart
  ///
  /// Returns a map with 'private' and 'public' keys as List<int>
  static Future<Map<String, List<int>>> _generateECDHKeyPair() async {
    final keyPair = await ECDHKeyExchange.generateKeyPair(
      curve: ECCKeyUtils.secp256r1,
    );

    final privateBytes = _hexToBytes(keyPair['privateKey']!);
    final publicBytes = _hexToBytes(keyPair['publicKey']!);

    return {'private': privateBytes, 'public': publicBytes};
  }

  /// Convert hex string to list of bytes
  ///
  /// Example: "48656c6c6f" -> [0x48, 0x65, 0x6c, 0x6c, 0x6f]
  static List<int> _hexToBytes(String hexString) {
    final bytes = <int>[];
    for (int i = 0; i < hexString.length; i += 2) {
      final hex = hexString.substring(i, i + 2);
      bytes.add(int.parse(hex, radix: 16));
    }
    return bytes;
  }

  /// Serialize to string format for storage/transmission
  ///
  /// Format: "base64(privateKey):base64(publicKey)"
  /// This creates a positional representation containing both key components.
  String serialize() {
    final privateB64 = base64Encode(_privateKeyBytes);
    final publicB64 = base64Encode(_publicKeyBytes);
    return '$privateB64:$publicB64';
  }

  /// Recreate an instance from serialized string
  ///
  /// Expects format: "base64(privateKey):base64(publicKey)"
  /// This allows restoring the key from any storage medium.
  static SerializableECDHPrivateKey deserialize(String data) {
    try {
      final parts = data.split(':');
      if (parts.length != 2) {
        throw FormatException(
          'Invalid serialization format. Expected "base64:base64" format',
        );
      }

      final privateKeyBytes = base64Decode(parts[0]);
      final publicKeyBytes = base64Decode(parts[1]);

      return SerializableECDHPrivateKey._internal(
        privateKeyBytes,
        publicKeyBytes,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Failed to deserialize ECDH key: $e');
    }
  }

  @override
  String toString() =>
      'SerializableECDHPrivateKey($curveName, private: '
      '${_privateKeyBytes.length}B, public: ${_publicKeyBytes.length}B)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SerializableECDHPrivateKey &&
          runtimeType == other.runtimeType &&
          _listEquals(_privateKeyBytes, other._privateKeyBytes) &&
          _listEquals(_publicKeyBytes, other._publicKeyBytes);

  @override
  int get hashCode =>
      _listHashCode(_privateKeyBytes) ^ _listHashCode(_publicKeyBytes);

  /// Helper to compare lists
  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper to hash lists
  static int _listHashCode(List<int> list) {
    int hash = 0;
    for (int i = 0; i < list.length; i++) {
      hash = ((hash << 5) - hash) + list[i];
      hash &= 0xFFFFFFFF; // Convert to 32-bit integer
    }
    return hash;
  }
}
