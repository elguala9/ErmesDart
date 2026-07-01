// ignore_for_file: conflicting_field_and_method
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../exceptions.dart';
import '../factories/ermes_cipher_factories.dart';
import 'ecdh_serialization_helpers.dart';

/// Default lifetime, in hours, applied to generated ECDH key pairs.
const int keyDurationHours = 24;

/// ECDH key exchange service implementing CryptDart's `IKeyExchange`.
///
/// Wraps a P-256 [ECDHKeyExchange] and exposes the
/// `IECDHKeyExchangeService` surface for the rest of the stack.
/// Binary (de)serialization helpers live in
/// [ecdh_serialization_helpers.dart].
@isSingleton
class ECDHKeyExchangeService implements IKeyExchange, IECDHKeyExchangeService {
  /// Creates an uninitialized service; the exchange is injected later.
  ECDHKeyExchangeService();

  /// Creates a service wrapping an existing [exchange] and its
  /// [symmetricAlgorithm]. Requires the exchange to use ECDH.
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

  /// The underlying ECDH key exchange this service delegates to.
  @isInjected
  @protected
  late IKeyExchange exchange;
  /// Symmetric algorithm used for ciphers derived from shared secrets.
  @isMandatoryParameter
  late CryptoAlgorithm symmetricAlgorithm;

  /// The key exchange algorithm in use (always ECDH here).
  @override
  KeyExchangeAlgorithm get algorithm => exchange.algorithm;

  /// This peer's public key.
  @override
  String get publicKey => exchange.publicKey;

  /// This peer's private key.
  @override
  String get privateKey => exchange.privateKey;

  /// When the key pair expires, or null if it never does.
  @override
  DateTime? get expirationDate => exchange.expirationDate;

  /// Total number of uses the key pair is allowed, if limited.
  @override
  int? get expirationTimes => exchange.expirationTimes;

  /// Remaining number of uses before the key pair expires, if limited.
  @override
  int? get expirationTimesRemaining => exchange.expirationTimesRemaining;

  /// Whether the key pair has expired.
  @override
  bool isExpired() => exchange.isExpired();

  /// Returns this peer's public key.
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

  /// Computes the ECDH shared secret with the peer's [otherPublicKey].
  @override
  String generateSharedSecret(String otherPublicKey) =>
      exchange.generateSharedSecret(otherPublicKey);

  /// Serializes this key pair to the binary wire format (base64url).
  @override
  String serialize() {
    final expirationMs = expirationDate?.millisecondsSinceEpoch ?? 0;
    return serializeKeyData(expirationMs, publicKey, privateKey);
  }

  /// Generates a brand new service with a fresh P-256 key pair, optionally
  /// bound to [symmetricAlg].
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

  /// Rebuilds a service from a previously [serialize]d value.
  static IECDHKeyExchangeService generateFromSerialize(String serialization) =>
      ECDHKeyExchangeService.deserialize(serialization);

  /// Derives the shared-secret symmetric cipher against the remote peer whose
  /// key is encoded in [serialization], optionally overriding [symmetricAlg].
  @override
  ISymmetricCipher generateISymmetric(
    String serialization, [
    CryptoAlgorithm? symmetricAlg,
  ]) {
    final remoteKey = ECDHKeyExchangeService.deserialize(serialization);
    return deriveSharedSecretCipher(this, remoteKey.publicKey, symmetricAlg);
  }

  /// Builds a P-256 [ECDHKeyExchange] from raw key material and expiration.
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
