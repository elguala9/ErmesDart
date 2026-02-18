import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:test/test.dart';

void main() {
  testECDHKeyExchange();
}

void testECDHKeyExchange() {
  group('ECDHKeyExchangeService', () {
    group('Key Generation', () {
      test('generateNew creates valid key pair', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        expect(keyExchange.publicKey, isNotEmpty);
        expect(keyExchange.privateKey, isNotEmpty);
        expect(keyExchange.expirationDate, isNotNull);
        expect(keyExchange.isExpired(), isFalse);
      });

      test('generateKeyPair generates different keys on each call', () async {
        final exchange1 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final exchange2 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        expect(exchange1.publicKey, isNot(equals(exchange2.publicKey)));
        expect(exchange1.privateKey, isNot(equals(exchange2.privateKey)));
      });

      test('expirationDate is set to 24 hours from now', () async {
        final beforeGeneration = DateTime.now();
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        expect(keyExchange.expirationDate, isNotNull);
        final expiryDiff =
            keyExchange.expirationDate!.difference(beforeGeneration).inHours;
        expect(expiryDiff, greaterThanOrEqualTo(23));
        expect(expiryDiff, lessThanOrEqualTo(25));
      });
    });

    group('Serialization', () {
      test('serialize returns valid base64url string', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final serialized = keyExchange.serialize();

        expect(serialized, isNotEmpty);
        // Base64url should only contain alphanumeric, -, and _ (no padding)
        expect(serialized, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      });

      test('serialize output is compact', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final serialized = keyExchange.serialize();

        // Base64url of 105 bytes should be around 140 chars
        final expectedMinLength = 130;
        expect(serialized.length, greaterThan(expectedMinLength));
      });

      test('deserialize restores original key pair', () async {
        final original = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final serialized = original.serialize();

        final restored = ECDHKeyExchangeService.deserialize(serialized);

        expect(restored.publicKey, equals(original.publicKey));
        expect(restored.privateKey, equals(original.privateKey));
      });

      test('deserialize with custom symmetric algorithm', () async {
        final original = await ECDHKeyExchangeService.generateNew(
          SymmetricCipherAlgorithmEnum.des,
        ) as ECDHKeyExchangeService;
        final serialized = original.serialize();

        final restored = ECDHKeyExchangeService.deserialize(
          serialized,
          SymmetricCipherAlgorithmEnum.des,
        );

        expect(restored.symmetricAlgorithm,
            equals(SymmetricCipherAlgorithmEnum.des));
      });

      test('roundtrip serialization preserves all data', () async {
        final original = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final serialized = original.serialize();
        final restored = ECDHKeyExchangeService.deserialize(serialized);

        expect(restored.publicKey, equals(original.publicKey));
        expect(restored.privateKey, equals(original.privateKey));
        expect(restored.algorithm, equals(original.algorithm));
      });

      test('deserialize fails with invalid base64', () {
        expect(
          () => ECDHKeyExchangeService.deserialize('!!!invalid!!!'),
          throwsA(isA<Exception>()),
        );
      });

      test('deserialize fails with truncated data', () {
        expect(
          () => ECDHKeyExchangeService.deserialize('AA=='),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Shared Secret Generation', () {
      test('generateSharedSecret with two keys produces same result both ways',
          () async {
        final peer1 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final peer2 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        final secret1 = peer1.generateSharedSecret(peer2.publicKey);
        final secret2 = peer2.generateSharedSecret(peer1.publicKey);

        expect(secret1, equals(secret2));
      });

      test(
        'generateSharedSecret produces different secrets for different peers',
        () async {
        final peer1 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final peer2 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final peer3 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        final secret12 = peer1.generateSharedSecret(peer2.publicKey);
        final secret13 = peer1.generateSharedSecret(peer3.publicKey);

        expect(secret12, isNot(equals(secret13)));
      });

      test('generateSharedSecret produces non-empty result', () async {
        final peer1 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final peer2 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        final secret = peer1.generateSharedSecret(peer2.publicKey);

        expect(secret, isNotEmpty);
      });
    });

    group('Symmetric Cipher Generation', () {
      test('generateISymmetric creates valid symmetric cipher', () async {
        final peer1 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final peer2 = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        final peer2Serialized = peer2.serialize();
        final cipher = peer1.generateISymmetric(peer2Serialized);

        expect(cipher, isNotNull);
        expect(cipher, isA<ISymmetricCipher>());
      });

    });

    group('Property Delegation', () {
      test('algorithm delegates to underlying exchange', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        expect(keyExchange.algorithm, equals(KeyExchangeAlgorithm.ecdh));
      });

      test('publicKey delegates to underlying exchange', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final publicKey1 = keyExchange.publicKey;
        final publicKey2 = keyExchange.publicKey;

        expect(publicKey1, equals(publicKey2));
      });

      test('getPublicKey returns same as publicKey property', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        expect(keyExchange.getPublicKey(), equals(keyExchange.publicKey));
      });

      test('expirationTimes can be null', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        expect(keyExchange.expirationTimes, isNull);
      });
    });

    group('Factory Methods', () {
      test('generateFromSerialize deserializes correctly', () async {
        final original = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final serialized = original.serialize();

        final restored =
            ECDHKeyExchangeService.generateFromSerialize(serialized)
                as ECDHKeyExchangeService;

        expect(restored.publicKey, equals(original.publicKey));
        expect(restored.privateKey, equals(original.privateKey));
      });

      test('generateNew uses default symmetric algorithm', () async {
        final keyExchange = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        expect(keyExchange.symmetricAlgorithm,
            equals(SymmetricCipherAlgorithmEnum.aes));
      });
    });
  });
}
