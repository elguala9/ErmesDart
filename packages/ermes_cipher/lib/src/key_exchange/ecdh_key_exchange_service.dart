// ignore_for_file: conflicting_field_and_method
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../exceptions.dart';
import '../factories/ermes_cipher_factories.dart';
import 'ecdh_serialization_helpers.dart';

const int keyDurationHours = 24;

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
    final data = deserializeKeyData(serialized, keyDurationHours);
    return ECDHKeyExchangeService.fromKeyExhange(
      _buildExchange(data.publicKey, data.privateKey, data.expirationDate),
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
    return serializeKeyData(expirationMs, publicKey, privateKey);
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
    return deriveSharedSecretCipher(this, remoteKey.publicKey, symmetricAlg);
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
}
