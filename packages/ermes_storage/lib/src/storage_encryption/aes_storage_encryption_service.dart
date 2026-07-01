import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';

/// AES-256 encryption service for data at rest.
///
/// Encrypts serializable maps using AES-256 before storage.
/// The cipher already handles IV generation internally.
/// Encrypted payloads are stored as:
/// ```json
/// {"__encrypted": true, "data": "<base64-ciphertext>"}
/// ```
class AesStorageEncryptionService implements IStorageEncryptionService {
  /// Creates the service from a 256-bit AES key.
  AesStorageEncryptionService(Uint8List key256)
    : _cipher = _createAesCipher(key256);

  final ICipher _cipher;

  static const String _encryptedMarker = '__encrypted';
  static const String _dataField = 'data';

  /// Encrypts [data] and returns a marked map holding the base64 ciphertext.
  @override
  Map<String, dynamic> encrypt(Map<String, dynamic> data) {
    final jsonStr = jsonEncode(data);
    final plainBytes = utf8.encode(jsonStr);
    final ciphertext = _cipher.encrypt(Uint8List.fromList(plainBytes));

    return {
      _encryptedMarker: true,
      _dataField: base64Encode(ciphertext),
    };
  }

  /// Decrypts a previously encrypted map, or returns [data] unchanged if it
  /// carries no encryption marker.
  @override
  Map<String, dynamic> decrypt(Map<String, dynamic> data) {
    if (data[_encryptedMarker] != true) {
      return data;
    }

    final ciphertext = base64Decode(data[_dataField] as String);
    final plainBytes = _cipher.decrypt(Uint8List.fromList(ciphertext));
    final jsonStr = utf8.decode(plainBytes);

    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Builds an AES cipher from the given 256-bit key.
  static ICipher _createAesCipher(Uint8List key256) {
    final keyHex =
        key256.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    const inputCipher = InputCipher(parent: InputExpirationBase());
    final inputSymmetric =
        InputSymmetricCipher(parent: inputCipher, key: keyHex);
    final inputAes = InputAESCipher(parent: inputSymmetric);
    return AESCipher.createFull(inputAes);
  }
}
