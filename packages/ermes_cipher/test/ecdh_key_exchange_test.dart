import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:test/test.dart';

void main() {
  group('ECDHKeyExchangeService', () {
    test('should generate a new key pair', () async {
      final service = await ECDHKeyExchangeService.generateNew();

      expect(service.serialize(), isNotEmpty);
    });

    test('should serialize and deserialize', () async {
      final service = await ECDHKeyExchangeService.generateNew();
      final serialized = service.serialize();

      expect(serialized, isNotEmpty);

      final deserialized = ECDHKeyExchangeService.deserialize(serialized);
      expect(deserialized.serialize(), equals(serialized));
    });

    test('should generate shared secret', () async {
      final alice = await ECDHKeyExchangeService.generateNew();
      final bob = await ECDHKeyExchangeService.generateNew();

      final aliceKey = alice as IKeyExchange;
      final bobKey = bob as IKeyExchange;

      final aliceSecret = aliceKey.generateSharedSecret(bobKey.publicKey);
      final bobSecret = bobKey.generateSharedSecret(aliceKey.publicKey);

      expect(aliceSecret, isNotEmpty);
      expect(aliceSecret, equals(bobSecret));
    });

    test('should generate ISymmetric from remote key', () async {
      final alice = await ECDHKeyExchangeService.generateNew();
      final bob = await ECDHKeyExchangeService.generateNew();

      final aliceSerialized = alice.serialize();
      final bobSerialized = bob.serialize();

      final aliceSymmetric = alice.generateISymmetric(bobSerialized);
      final bobSymmetric = bob.generateISymmetric(aliceSerialized);

      expect(aliceSymmetric, isA<ISymmetricCipher>());
      expect(bobSymmetric, isA<ISymmetricCipher>());
    });

    test('should create fromKeyExhange with ECDH exchange', () async {
      final keyPair = await ECDHKeyExchange.generateKeyPair();
      final exchange = ECDHKeyExchange(InputECDHKeyExchange(
        parent: InputKeyExchangeBase(
          algorithm: KeyExchangeAlgorithm.ecdh,
          expirationDate: DateTime.now().add(const Duration(hours: 24)),
        ),
        publicKey: keyPair['publicKey']!,
        privateKey: keyPair['privateKey']!,
        curve: ECCKeyUtils.secp256r1,
      ));

      final service = ECDHKeyExchangeService.fromKeyExhange(
        exchange,
        SymmetricCipherAlgorithmEnum.aes,
      );
      expect(service, isA<IKeyExchange>());
      expect(service.serialize(), isNotEmpty);
    });

    test('should handle serialize roundtrip with ECDHKeyUtilities', () async {
      final service = await ECDHKeyUtilities.generateNewKey();

      final serialized = ECDHKeyUtilities.saveToString(service);
      expect(serialized, isNotEmpty);

      final loaded = ECDHKeyUtilities.loadFromString(serialized);
      expect(loaded.serialize(), equals(service.serialize()));
    });
  });
}
