import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesPeerKeyExchange', () {
    late ErmesPeerCipher peerCipher;
    late ErmesPeerKeyExchange keyExchange;
    late ISymmetricCipher symmetricCipher;

    setUp(() {
      peerCipher = ErmesPeerCipher();
      keyExchange = ErmesPeerKeyExchange.fromPeerCipher(peerCipher);

      final aesCipher = AESCipher.createFull(InputAESCipher(
        parent: InputSymmetricCipher(
          parent: InputCipher(
            parent: InputExpirationBase(
              expirationDate: DateTime.now().add(const Duration(hours: 1)),
            ),
          ),
          key: '0123456789abcdef0123456789abcdef',
        ),
      ));
      peerCipher
        ..addEncryptCipher(aesCipher)
        ..addDecryptCipher(aesCipher);

      symmetricCipher = AESCipher.createFull(InputAESCipher(
        parent: InputSymmetricCipher(
          parent: InputCipher(
            parent: InputExpirationBase(
              expirationDate: DateTime.now().add(const Duration(hours: 1)),
            ),
          ),
          key: 'fedcba9876543210fedcba9876543210',
        ),
      ));
    });

    test('should prepare and deserialize encrypted symmetric key', () {
      final encrypted =
          keyExchange.prepareEncryptedSymmetricKey(symmetricCipher);

      expect(encrypted, isA<DataEncrypted>());
      expect(encrypted.encryptedData, isNotEmpty);

      final deserialized = keyExchange.deserialize(encrypted);
      expect(deserialized.key, equals(symmetricCipher.key));
      expect(deserialized.algorithm, equals(symmetricCipher.algorithm));
    });

    test('should handle AES algorithm', () {
      final encrypted =
          keyExchange.prepareEncryptedSymmetricKey(symmetricCipher);
      final deserialized = keyExchange.deserialize(encrypted);

      expect(deserialized.algorithm, equals(SymmetricAlgorithm.aes));
    });

    test('should handle DES algorithm', () {
      final now = DateTime.now();
      final desCipher = DESCipher(InputDESCipher(
        parent: InputSymmetricCipher(
          parent: InputCipher(
            parent: InputExpirationBase(
              expirationDate: now.add(const Duration(hours: 1)),
            ),
          ),
          key: '0123456789abcdef',
        ),
      ));

      final encrypted = keyExchange.prepareEncryptedSymmetricKey(desCipher);
      final deserialized = keyExchange.deserialize(encrypted);

      expect(deserialized.algorithm, equals(SymmetricAlgorithm.des));
    });

    test('should throw on unsupported algorithm', () {
      expect(
        () => keyExchange.prepareEncryptedSymmetricKey(
          generateSymmetric('testkey', SymmetricAlgorithm.hmac),
        ),
        throwsException,
      );
    });
  });
}
