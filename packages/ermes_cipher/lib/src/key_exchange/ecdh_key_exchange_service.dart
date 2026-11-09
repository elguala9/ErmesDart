// ignore_for_file: conflicting_field_and_method
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../exceptions.dart';
import '../factories/ermes_cipher_factories.dart';
import '../factories/shared_secret_cipher.dart';
import 'ecdh_exchange_builder.dart';
import 'ecdh_key_exchange_delegation.dart';
import 'ecdh_serialization_helpers.dart';

/// Default lifetime, in hours, applied to generated ECDH key pairs.
const int keyDurationHours = 24;

/// ECDH key exchange service implementing CryptDart's `IKeyExchange`.
///
/// Wraps a P-256 [ECDHKeyExchange] and exposes the
/// `IECDHKeyExchangeService` surface for the rest of the stack.
/// Binary (de)serialization helpers live in
/// [ecdh_serialization_helpers.dart].
@dependencyInjectable
class ECDHKeyExchangeService
    with ECDHKeyExchangeDelegation
    implements IKeyExchange, IECDHKeyExchangeService {
  /// Creates a service wrapping an existing [exchange] and its
  /// [symmetricAlgorithm]. Requires the exchange to use ECDH.
  ECDHKeyExchangeService(this.exchange, this.symmetricAlgorithm) {
    if (exchange.algorithm != KeyExchangeAlgorithm.ecdh) {
      throw CipherException('ECDHKeyExchangeService needs ECDH IKeyExchange');
    }
  }

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ECDHKeyExchangeService.dependencyInjectionFactory({
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) { // GENERATED CODE - DO NOT MODIFY BY HAND
    // GENERATED CODE - DO NOT MODIFY BY HAND
    final exchange = RegistryManager.instance
        .getInstance<IKeyExchange>(key: key);
    // GENERATED CODE - DO NOT MODIFY BY HAND
    final symmetricAlgorithm = RegistryManager.instance
        .getInstance<CryptoAlgorithm>(key: key);

    return ECDHKeyExchangeService( // GENERATED CODE - DO NOT MODIFY BY HAND
      exchange, // GENERATED CODE - DO NOT MODIFY BY HAND
      symmetricAlgorithm, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Creates a service wrapping an existing [exchange] and its
  /// [symmetricAlgorithm]. Requires the exchange to use ECDH.
  ECDHKeyExchangeService.fromKeyExhange(
    IKeyExchange exchange,
    CryptoAlgorithm symmetricAlgorithm,
  ) : this(exchange, symmetricAlgorithm);

  /// Restore an instance from the binary wire format produced by [serialize].
  factory ECDHKeyExchangeService.deserialize(
    String serialized, [
    CryptoAlgorithm? symmetricAlg,
  ]) {
    final data = deserializeKeyData(serialized, keyDurationHours);
    return ECDHKeyExchangeService.fromKeyExhange(
      buildEcdhExchange(data.publicKey, data.privateKey, data.expirationDate),
      symmetricAlg ?? defaultSymmetricValue,
    );
  }

  /// The underlying ECDH key exchange this service delegates to.
  ///
  /// Replaced in place by [generateKeyPair], so this is deliberately mutable.
  @protected
  @override
  IKeyExchange exchange;
  /// Symmetric algorithm used for ciphers derived from shared secrets.
  final CryptoAlgorithm symmetricAlgorithm;

  /// Generate a fresh P-256 key pair on this instance.
  Future<void> generateKeyPair({
    Duration expiration = const Duration(hours: keyDurationHours),
  }) async {
    final keyPair = await ECDHKeyExchange.generateKeyPair();
    exchange = buildEcdhExchange(
      keyPair['publicKey']!,
      keyPair['privateKey']!,
      DateTime.now().add(expiration),
    );
  }


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
  ]) =>
      generateNewService(symmetricAlg);

  /// Same as [generateNew], but typed as the concrete implementation so
  /// callers needing the full surface (e.g. [IKeyExchange]) do not have to
  /// cast. [IECDHKeyExchangeService] alone does not imply [IKeyExchange].
  static Future<ECDHKeyExchangeService> generateNewService([
    CryptoAlgorithm? symmetricAlg,
  ]) async {
    final keyPair = await ECDHKeyExchange.generateKeyPair();
    final expiration = DateTime.now().add(
      const Duration(hours: keyDurationHours),
    );
    return ECDHKeyExchangeService(
      buildEcdhExchange(
        keyPair['publicKey']!,
        keyPair['privateKey']!,
        expiration,
      ),
      symmetricAlg ?? defaultSymmetricValue,
    );
  }

  /// Rebuilds a service from a previously [serialize]d value.
  static IECDHKeyExchangeService generateFromSerialize(String serialization) =>
      ECDHKeyExchangeService.deserialize(serialization);

  /// Derives the shared-secret symmetric cipher against the remote peer whose
  /// key is encoded in [serialization], optionally overriding [symmetricAlg].
  /// The key is bound to the Connection [context] (IPv4 by default).
  @override
  ISymmetricCipher generateISymmetric(
    String serialization, [
    CryptoAlgorithm? symmetricAlg,
    ErmesConnectionContext context = ErmesConnectionContext.ipv4,
  ]) {
    final remoteKey = ECDHKeyExchangeService.deserialize(serialization);
    return deriveSharedSecretCipher(
      this,
      remoteKey.publicKey,
      context,
      symmetricAlg,
    );
  }
}
