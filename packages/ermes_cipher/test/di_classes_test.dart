import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void main() {
  group('ECDHKeyExchangeServiceDI', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test('default constructor creates instance', () {
      final di = ECDHKeyExchangeServiceDI();
      expect(di, isA<ECDHKeyExchangeServiceDI>());
      expect(di, isA<ECDHKeyExchangeService>());
      expect(di, isA<IECDHKeyExchangeService>());
    });

    test('initializeDI resolves dependencies from singleton registry',
        () async {
      final keyExchange =
          await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
      SingletonDIAccess.addInstance<IKeyExchange>(keyExchange);
      SingletonDIAccess.addInstance<CryptoAlgorithm>(
        SymmetricCipherAlgorithmEnum.aes,
      );

      final di = ECDHKeyExchangeServiceDI.initializeDI();

      expect(di.exchange, equals(keyExchange));
      expect(di.symmetricAlgorithm, equals(SymmetricCipherAlgorithmEnum.aes));
    });

    test('initializeWithParametersDI uses provided algorithm', () async {
      final keyExchange =
          await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
      SingletonDIAccess.addInstance<IKeyExchange>(keyExchange);

      final di = ECDHKeyExchangeServiceDI.initializeWithParametersDI(
        SymmetricCipherAlgorithmEnum.des,
      );

      expect(di.symmetricAlgorithm, equals(SymmetricCipherAlgorithmEnum.des));
    });

    test('initializeWithParametersDI resolves exchange from registry',
        () async {
      final keyExchange =
          await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
      SingletonDIAccess.addInstance<IKeyExchange>(keyExchange);

      final di = ECDHKeyExchangeServiceDI.initializeWithParametersDI(
        SymmetricCipherAlgorithmEnum.aes,
      );

      expect(di.exchange, equals(keyExchange));
    });

    test('can generate shared secret after DI init', () async {
      final keyExchange =
          await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
      SingletonDIAccess.addInstance<IKeyExchange>(keyExchange);
      SingletonDIAccess.addInstance<CryptoAlgorithm>(
        SymmetricCipherAlgorithmEnum.aes,
      );

      final di = ECDHKeyExchangeServiceDI.initializeDI();

      final remoteKey =
          await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
      final secret = di.generateSharedSecret(remoteKey.publicKey);
      expect(secret, isNotEmpty);
    });
  });

  group('ErmesPeerCipherDI', () {
    test('default constructor creates instance', () {
      final di = ErmesPeerCipherDI();
      expect(di, isA<ErmesPeerCipherDI>());
      expect(di, isA<ErmesPeerCipher>());
      expect(di, isA<IErmesPeerCipher>());
    });

    test('initializeDI returns ready instance', () {
      final di = ErmesPeerCipherDI.initializeDI();
      expect(di, isA<ErmesPeerCipherDI>());
    });

    test('can encrypt and decrypt after init', () {
      final di = ErmesPeerCipherDI();
      final cipher = generateSymmetric('0' * 64, SymmetricAlgorithm.aes);
      di.addEncryptCipher(cipher);
      di.addDecryptCipher(cipher);

      final data = Uint8List.fromList([1, 2, 3]);
      final encrypted = di.encrypt(data);
      final decrypted = di.decrypt(encrypted);

      expect(decrypted, equals(data));
    });

    test('initializeDI returns working cipher', () {
      final di = ErmesPeerCipherDI.initializeDI();
      final cipher = generateSymmetric('1' * 64, SymmetricAlgorithm.aes);
      di.addEncryptCipher(cipher);
      di.addDecryptCipher(cipher);

      final data = Uint8List.fromList([4, 5, 6]);
      final encrypted = di.encrypt(data);
      final decrypted = di.decrypt(encrypted);

      expect(decrypted, equals(data));
    });
  });

  group('ErmesPeerKeyExchangeDI', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test('default constructor creates instance', () {
      final di = ErmesPeerKeyExchangeDI();
      expect(di, isA<ErmesPeerKeyExchangeDI>());
      expect(di, isA<ErmesPeerKeyExchange>());
      expect(di, isA<IErmesPeerKeyExchange>());
    });

    test('initializeDI resolves peerCipher from registry', () {
      final peerCipher = ErmesPeerCipher();
      SingletonDIAccess.addInstance<IErmesPeerCipher>(peerCipher);

      final di = ErmesPeerKeyExchangeDI.initializeDI();

      expect(di.peerCipher, equals(peerCipher));
    });

    test('can prepare and deserialize after DI init', () {
      final peerCipher = ErmesPeerCipher();
      SingletonDIAccess.addInstance<IErmesPeerCipher>(peerCipher);

      final testCipher = generateSymmetric('a' * 64, SymmetricAlgorithm.aes);
      peerCipher.addEncryptCipher(testCipher);
      peerCipher.addDecryptCipher(testCipher);

      final di = ErmesPeerKeyExchangeDI.initializeDI();

      final symmetric = generateSymmetric('b' * 64, SymmetricAlgorithm.aes);
      final encrypted = di.prepareEncryptedSymmetricKey(symmetric);
      final deserialized = di.deserialize(encrypted);

      expect(deserialized.key, equals(symmetric.key));
      expect(deserialized.algorithm, equals(symmetric.algorithm));
    });

    test('initializeDI with real peer cipher flow', () {
      final peerCipher = ErmesPeerCipher();
      SingletonDIAccess.addInstance<IErmesPeerCipher>(peerCipher);

      final cipherAES = generateSymmetric('c' * 64, SymmetricAlgorithm.aes);
      peerCipher.addEncryptCipher(cipherAES);
      peerCipher.addDecryptCipher(cipherAES);

      final di = ErmesPeerKeyExchangeDI.initializeDI();

      final aesKey = generateSymmetric('d' * 64, SymmetricAlgorithm.aes);
      final encrypted = di.prepareEncryptedSymmetricKey(aesKey);
      expect(encrypted.encryptedData, isNotEmpty);

      final deserialized = di.deserialize(encrypted);
      expect(deserialized.algorithm, equals(SymmetricAlgorithm.aes));
      expect(deserialized.key, equals(aesKey.key));

      final testMessage = [1, 2, 3, 4, 5];
      final enc = deserialized.encrypt(testMessage);
      final dec = deserialized.decrypt(enc);
      expect(dec, equals(testMessage));
    });
  });
}
