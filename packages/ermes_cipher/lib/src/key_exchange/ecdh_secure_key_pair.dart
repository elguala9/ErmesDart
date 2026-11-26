import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart' show CryptoUtils;
import 'package:pointycastle/export.dart';

/// PEM-encoded P-256 key pair.
class EcdhPemKeyPair {
  /// Creates the pair.
  const EcdhPemKeyPair({required this.publicKey, required this.privateKey});

  /// PEM public key.
  final String publicKey;

  /// PEM private key.
  final String privateKey;
}

/// Fortuna PRNG seeded with 32 bytes from the OS CSPRNG ([Random.secure]).
///
/// Replaces cryptdart's `SecureRandomUtils.createSeeded`, whose seed is 32
/// copies of `microsecondsSinceEpoch % 256`: only 256 distinct seeds, so two
/// key pairs generated close together are frequently identical.
SecureRandom ermesSecureRandom() {
  final os = Random.secure();
  final seed = Uint8List.fromList(List.generate(32, (_) => os.nextInt(256)));
  return FortunaRandom()..seed(KeyParameter(seed));
}

/// Generates a fresh secp256r1 key pair from [ermesSecureRandom], PEM
/// encoded like cryptdart's `ECDHKeyExchange.generateKeyPair`.
EcdhPemKeyPair generateSecureEcdhKeyPair() {
  final params = ECKeyGeneratorParameters(ECDomainParameters('secp256r1'));
  final generator = ECKeyGenerator()
    ..init(ParametersWithRandom(params, ermesSecureRandom()));
  final pair = generator.generateKeyPair();
  return EcdhPemKeyPair(
    publicKey: CryptoUtils.encodeEcPublicKeyToPem(pair.publicKey),
    privateKey: CryptoUtils.encodeEcPrivateKeyToPem(pair.privateKey),
  );
}
