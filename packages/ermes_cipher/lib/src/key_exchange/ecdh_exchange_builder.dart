import 'package:cryptdart/cryptdart.dart';

/// Builds a P-256 [ECDHKeyExchange] from raw key material and expiration.
IKeyExchange buildEcdhExchange(
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
