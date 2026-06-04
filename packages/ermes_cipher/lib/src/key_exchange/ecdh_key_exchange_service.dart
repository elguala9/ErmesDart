// ignore_for_file: conflicting_field_and_method
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../exceptions.dart';
import '../factories/ermes_cipher_factories.dart';
import 'ecdh_serialization_helpers.dart';

const int keyDurationHours = 24;

final CryptoAlgorithm defaultSymmetricValue = SymmetricCipherAlgorithmEnum.aes;

/// ECDH key exchange service implementing CryptDart's `IKeyExchange`.
///
/// Wraps a P-256 [ECDHKeyExchange] and exposes the
/// `IECDHKeyExchangeService` surface for the rest of the stack.
/// Binary (de)serialization helpers live in
/// [ecdh_serialization_helpers.dart].
@isSingleton
class ECDHKeyExchangeService implements IKeyExchange, IECDHKeyExchangeService {
  ECDHKeyExchangeService();

  ECDHKeyExchangeService.fromKeyExhange(
    this.exchange,
    this.symmetricAlgorithm,
  ) {
    if (exchange.algorithm != KeyExchangeAlgorithm.ecdh) {
      throw CipherException('ECDHKeyExchangeService needs ECDH IKeyExchange');
    }
  }

  /// Restore an instance from the binary wire format produced by [serialize].
  factory ECDHKeyExchangeService.deserialize(
    String serialized, [
    CryptoAlgorithm? symmetricAlg,
  ]) {
    final buffer = base64UrlToBytes(serialized);
    if (buffer.length < 8) {
      throw const FormatException('Invalid serialized data: too short');
    }

    var offset = 0;
    final expirationMs = bytesToUint64(buffer.sublist(offset, offset + 8));
    final expirationDate = expirationMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(expirationMs)
        : DateTime.now().add(const Duration(hours: keyDurationHours));
    offset += 8;

    final pubRead = _readLengthPrefixedString(buffer, offset);
    offset = pubRead.nextOffset;
    final privRead = _readLengthPrefixedString(buffer, offset);
    final publicKey = pubRead.value;
    final privateKey = privRead.value;

    return ECDHKeyExchangeService.fromKeyExhange(
      _buildExchange(publicKey, privateKey, expirationDate),
      symmetricAlg ?? defaultSymmetricValue,
    );
  }

  @isInjected
  @protected
  late IKeyExchange exchange;
  @isMandatoryParameter
  late CryptoAlgorithm symmetricAlgorithm;

  @override
  KeyExchangeAlgorithm get algorithm => exchange.algorithm;

  @override
  String get publicKey => exchange.publicKey;

  @override
  String get privateKey => exchange.privateKey;

  @override
  DateTime? get expirationDate => exchange.expirationDate;

  @override
  int? get expirationTimes => exchange.expirationTimes;

  @override
  int? get expirationTimesRemaining => exchange.expirationTimesRemaining;

  @override
  bool isExpired() => exchange.isExpired();

  @override
  String getPublicKey() => exchange.getPublicKey();

  /// Generate a fresh P-256 key pair on this instance.
  Future<void> generateKeyPair({
    Duration expiration = const Duration(hours: keyDurationHours),
  }) async {
    final keyPair = await ECDHKeyExchange.generateKeyPair();
    exchange = _buildExchange(
      keyPair['publicKey']!,
      keyPair['privateKey']!,
      DateTime.now().add(expiration),
    );
  }

  @override
  String generateSharedSecret(String otherPublicKey) =>
      exchange.generateSharedSecret(otherPublicKey);

  @override
  String serialize() {
    final expirationMs = expirationDate?.millisecondsSinceEpoch ?? 0;
    final pubKeyPemBytes = utf8.encode(publicKey);
    final privKeyPemBytes = utf8.encode(privateKey);

    final bufferSize =
        8 + 2 + pubKeyPemBytes.length + 2 + privKeyPemBytes.length;
    final buffer = Uint8List(bufferSize);
    var offset = 0;

    buffer.setRange(offset, offset + 8, uint64ToBytes(expirationMs));
    offset += 8;

    offset = _writeLengthPrefixedBytes(buffer, offset, pubKeyPemBytes);
    _writeLengthPrefixedBytes(buffer, offset, privKeyPemBytes);

    return bytesToBase64Url(buffer);
  }

  static Future<IECDHKeyExchangeService> generateNew([
    CryptoAlgorithm? symmetricAlg,
  ]) async {
    final keyPair = await ECDHKeyExchange.generateKeyPair();
    final expiration = DateTime.now().add(
      const Duration(hours: keyDurationHours),
    );
    return ECDHKeyExchangeService.fromKeyExhange(
      _buildExchange(keyPair['publicKey']!, keyPair['privateKey']!, expiration),
      symmetricAlg ?? defaultSymmetricValue,
    );
  }

  static IECDHKeyExchangeService generateFromSerialize(String serialization) =>
      ECDHKeyExchangeService.deserialize(serialization);

  @override
  ISymmetricCipher generateISymmetric(
    String serialization, [
    CryptoAlgorithm? symmetricAlg,
  ]) {
    final remoteKey = ECDHKeyExchangeService.deserialize(serialization);
    final sharedSecret = generateSharedSecret(remoteKey.publicKey);
    final cleanedSecret = cleanHexString(sharedSecret);
    var secretBytes = hexStringToBytes(cleanedSecret);

    if (secretBytes.length < 32) {
      secretBytes =
          Uint8List(32)..setRange(32 - secretBytes.length, 32, secretBytes);
    }

    return generateSymmetric(
      secretBytes,
      symmetricAlg ?? defaultSymmetricValue,
    );
  }

  static IKeyExchange _buildExchange(
    String publicKey,
    String privateKey,
    DateTime expirationDate,
  ) =>
      ECDHKeyExchange(
        InputECDHKeyExchange(
          parent: InputKeyExchangeBase(
            algorithm: KeyExchangeAlgorithm.ecdh,
            expirationDate: expirationDate,
          ),
          publicKey: publicKey,
          privateKey: privateKey,
          curve: ECCKeyUtils.secp256r1,
        ),
      );

  static ({String value, int nextOffset}) _readLengthPrefixedString(
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

  static int _writeLengthPrefixedBytes(
    Uint8List buffer,
    int offset,
    List<int> data,
  ) {
    buffer[offset] = (data.length >> 8) & 0xFF;
    buffer[offset + 1] = data.length & 0xFF;
    buffer.setRange(offset + 2, offset + 2 + data.length, data);
    return offset + 2 + data.length;
  }
}
