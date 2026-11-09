import 'package:cryptdart/cryptdart.dart';

/// Read-only [IKeyExchange] surface of `ECDHKeyExchangeService`, delegating
/// every member to the wrapped [exchange].
mixin ECDHKeyExchangeDelegation implements IKeyExchange {
  /// The underlying key exchange the members delegate to.
  IKeyExchange get exchange;

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

  /// Computes the ECDH shared secret with the peer's [otherPublicKey].
  @override
  String generateSharedSecret(String otherPublicKey) =>
      exchange.generateSharedSecret(otherPublicKey);
}
