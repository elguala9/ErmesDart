// ignore_for_file: invalid_use_of_protected_member

import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void main() {
  // Each test registers under its own key so the graphs stay independent and
  // no test can see another's instances.
  var testCounter = 0;
  late String key;

  setUp(() {
    testCounter++;
    key = 'cipher_di_test_$testCounter';
  });

  group('ECDHKeyExchangeService.dependencyInjectionFactory', () {
    test('resolves exchange and algorithm from the registry', () async {
      final keyExchange = await ECDHKeyExchangeService.generateNewService();
      RegistryManager.instance
        ..setInstance<IKeyExchange>(keyExchange, key: key)
        ..setInstance<CryptoAlgorithm>(
          SymmetricCipherAlgorithmEnum.aes,
          key: key,
        );

      final di = ECDHKeyExchangeService.dependencyInjectionFactory(key: key);

      expect(di, isA<IECDHKeyExchangeService>());
      expect(di.exchange, equals(keyExchange));
      expect(di.symmetricAlgorithm, equals(SymmetricCipherAlgorithmEnum.aes));
    });

    test('honours the registered algorithm', () async {
      final keyExchange = await ECDHKeyExchangeService.generateNewService();
      RegistryManager.instance
        ..setInstance<IKeyExchange>(keyExchange, key: key)
        ..setInstance<CryptoAlgorithm>(
          SymmetricCipherAlgorithmEnum.des,
          key: key,
        );

      final di = ECDHKeyExchangeService.dependencyInjectionFactory(key: key);

      expect(di.symmetricAlgorithm, equals(SymmetricCipherAlgorithmEnum.des));
    });

    test('throws when the key exchange is not registered', () {
      RegistryManager.instance.setInstance<CryptoAlgorithm>(
        SymmetricCipherAlgorithmEnum.aes,
        key: key,
      );

      expect(
        () => ECDHKeyExchangeService.dependencyInjectionFactory(key: key),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('can generate a shared secret after DI init', () async {
      final keyExchange = await ECDHKeyExchangeService.generateNewService();
      RegistryManager.instance
        ..setInstance<IKeyExchange>(keyExchange, key: key)
        ..setInstance<CryptoAlgorithm>(
          SymmetricCipherAlgorithmEnum.aes,
          key: key,
        );

      final di = ECDHKeyExchangeService.dependencyInjectionFactory(key: key);

      final remoteKey = await ECDHKeyExchangeService.generateNewService();
      final secret = di.generateSharedSecret(remoteKey.publicKey);
      expect(secret, isNotEmpty);
    });
  });

  group('ErmesPeerCipher.dependencyInjectionFactory', () {
    test('creates a working cipher with no registered dependencies', () {
      final di = ErmesPeerCipher.dependencyInjectionFactory(key: key);
      expect(di, isA<IErmesPeerCipher>());

      final cipher = generateSymmetric('1' * 64, SymmetricAlgorithm.aes);
      di
        ..addEncryptCipher(cipher)
        ..addDecryptCipher(cipher);

      final data = Uint8List.fromList([4, 5, 6]);
      final encrypted = di.encrypt(data);
      final decrypted = di.decrypt(encrypted);

      expect(decrypted, equals(data));
    });
  });

  group('ErmesPeerKeyExchange.dependencyInjectionFactory', () {
    test('resolves peerCipher from the registry', () {
      final peerCipher = ErmesPeerCipher();
      RegistryManager.instance
          .setInstance<IErmesPeerCipher>(peerCipher, key: key);

      final di = ErmesPeerKeyExchange.dependencyInjectionFactory(key: key);

      expect(di, isA<IErmesPeerKeyExchange>());
      expect(di.peerCipher, equals(peerCipher));
    });

    test('can prepare and deserialize after DI init', () {
      final peerCipher = ErmesPeerCipher();
      RegistryManager.instance
          .setInstance<IErmesPeerCipher>(peerCipher, key: key);

      final testCipher = generateSymmetric('a' * 64, SymmetricAlgorithm.aes);
      peerCipher
        ..addEncryptCipher(testCipher)
        ..addDecryptCipher(testCipher);

      final di = ErmesPeerKeyExchange.dependencyInjectionFactory(key: key);

      final symmetric = generateSymmetric('b' * 64, SymmetricAlgorithm.aes);
      final encrypted = di.prepareEncryptedSymmetricKey(symmetric);
      final deserialized = di.deserialize(encrypted);

      expect(deserialized.key, equals(symmetric.key));
      expect(deserialized.algorithm, equals(symmetric.algorithm));
    });

    test('round-trips a real symmetric key through the peer cipher', () {
      final peerCipher = ErmesPeerCipher();
      RegistryManager.instance
          .setInstance<IErmesPeerCipher>(peerCipher, key: key);

      final cipherAES = generateSymmetric('c' * 64, SymmetricAlgorithm.aes);
      peerCipher
        ..addEncryptCipher(cipherAES)
        ..addDecryptCipher(cipherAES);

      final di = ErmesPeerKeyExchange.dependencyInjectionFactory(key: key);

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

  group('ErmesCipherInjector', () {
    test('connects the whole graph and generates a key pair', () async {
      await const ErmesCipherInjector()
          .registerAllSingletonsErmesCipherAsync(key: key);

      final registry = RegistryManager.instance;
      expect(registry.getInstance<IKeyExchange>(key: key), isA<IKeyExchange>());
      expect(
        registry.getInstance<CryptoAlgorithm>(key: key),
        equals(defaultSymmetricValue),
      );
      expect(
        registry.getInstance<IErmesPeerCipher>(key: key),
        isA<IErmesPeerCipher>(),
      );

      final exchange = registry.getInstance<IErmesPeerKeyExchange>(key: key);
      expect(exchange, isA<IErmesPeerKeyExchange>());
      // Connected instances are cached, so the same key resolves the same one.
      expect(
        registry.getInstance<IErmesPeerKeyExchange>(key: key),
        same(exchange),
      );
    });

    test('reuses a supplied key pair instead of generating one', () async {
      final keyExchange = await ECDHKeyExchangeService.generateNewService();

      await ErmesCipherInjector(keyExchange: keyExchange)
          .registerAllSingletonsErmesCipherAsync(key: key);

      expect(
        RegistryManager.instance.getInstance<IKeyExchange>(key: key),
        same(keyExchange),
      );
    });

    test('keeps graphs registered under different keys independent', () async {
      const injector = ErmesCipherInjector();
      await injector.registerAllSingletonsErmesCipherAsync(key: '$key-a');
      await injector.registerAllSingletonsErmesCipherAsync(key: '$key-b');

      final registry = RegistryManager.instance;
      final a = registry.getInstance<IErmesPeerCipher>(key: '$key-a');
      final b = registry.getInstance<IErmesPeerCipher>(key: '$key-b');
      expect(a, isNot(same(b)));
    });
  });
}
