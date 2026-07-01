import 'dart:convert';
import 'dart:typed_data';


import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../../ermes_cipher.dart';

/// Implementation of peer key exchange with asymmetric encryption
///
/// Manages the preparation of encrypted symmetric key material for secure
/// peer-to-peer communication using IErmesPeerCipher for encryption.
///
/// Does NOT handle actual data transmission - only preparation and
/// serialization.
@isSingleton
class ErmesPeerKeyExchange implements IErmesPeerKeyExchange {
  /// Creates a handler with a default injected peer cipher.
  ErmesPeerKeyExchange();
  /// Creates a new key exchange handler
  ///
  /// Parameters:
  /// - [peerCipher]: Cipher instance for encrypting/decrypting with peer
  ErmesPeerKeyExchange.fromPeerCipher(this.peerCipher);
  /// Cipher used to encrypt and decrypt key material exchanged with the peer.
  @isInjected
  late IErmesPeerCipher peerCipher = ErmesPeerCipher();

  /// Convert CryptoAlgorithm to a single byte for serialization
  int _algorithmToBytes(CryptoAlgorithm algorithm) {
    //TDO: try to eliminate these things
    if (algorithm == SymmetricAlgorithm.aes) {
      return 0x01;
    }
    if (algorithm == SymmetricAlgorithm.des) {
      return 0x02;
    }
    if (algorithm == SymmetricAlgorithm.hmac) {
      return 0x03;
    }
    throw UnsupportedAlgorithmException('$algorithm');
  }

  /// Convert a byte back to CryptoAlgorithm
  CryptoAlgorithm _bytesToAlgorithm(int byte) {
    switch (byte) {
      case 0x01:
        return SymmetricAlgorithm.aes;
      case 0x02:
        return SymmetricAlgorithm.des;
      case 0x03:
        return SymmetricAlgorithm.hmac;
      default:
        throw CipherException(
          'Unknown algorithm byte: 0x${byte.toRadixString(16)}',
        );
    }
  }

  /// Serializes and encrypts the [symmetric] key material (algorithm byte
  /// plus key) using the peer cipher, ready for transmission.
  @override
  DataEncrypted prepareEncryptedSymmetricKey(ISymmetricCipher symmetric) {
    // Serialize algorithm type to byte
    final algorithmByte = _algorithmToBytes(symmetric.algorithm);

    // Convert the symmetric key material to bytes for encryption
    final keyBytes = utf8.encode(symmetric.key);

    // Combine algorithm byte with key bytes
    final combinedBytes = Uint8List(1 + keyBytes.length);
    combinedBytes[0] = algorithmByte;
    combinedBytes.setRange(1, combinedBytes.length, keyBytes);

    // Encrypt using the peer cipher
    final encrypted = peerCipher.encrypt(combinedBytes);

    return encrypted;
  }

  /// Deserialize from encrypted symmetric key data
  ///
  /// Restores the peer cipher from previously encrypted key material.
  /// This is a static factory method to reconstruct the cipher from
  /// transmission.
  @override
  ISymmetricCipher deserialize(DataEncrypted encryptedInfo) {
    final decryptedData = peerCipher.decrypt(encryptedInfo);

    // Extract algorithm byte from first position
    final algorithmByte = decryptedData[0];
    final algorithm = _bytesToAlgorithm(algorithmByte);

    // Extract key bytes (from second position onwards)
    final keyBytes = decryptedData.sublist(1);
    final keyString = utf8.decode(keyBytes);

    // Reconstruct ISymmetric using the deserialized algorithm and key
    final symmetric = generateSymmetric(keyString, algorithm);

    return symmetric;
  }
}
