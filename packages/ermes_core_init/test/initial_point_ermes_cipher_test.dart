@TestOn('vm')
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void main() {
  group('initialPointErmesCipher', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test('should initialize cipher DI stack', () async {
      await initialPointErmesCipher();

      final peerCipher = SingletonDIAccess.get<IErmesPeerCipher>();
      expect(peerCipher, isA<IErmesPeerCipher>());

      final keyExchange = SingletonDIAccess.get<IKeyExchange>();
      expect(keyExchange, isA<IKeyExchange>());
    });
  });

  group('initialPointErmesCipherRegistry', () {
    setUp(() {
      RegistryAccess.clearRegistry();
    });

    test('should initialize with custom registry key', () async {
      const registryKey = 'test_cipher_registry';

      await initialPointErmesCipherRegistry(key: registryKey);

      final peerCipher = getIErmesPeerCipherFromRegistry(key: registryKey);
      expect(peerCipher, isA<IErmesPeerCipher>());

      final keyExchange = getIKeyExchangeFromRegistry(key: registryKey);
      expect(keyExchange, isA<IKeyExchange>());
    });

    test('should support multiple registry instances', () async {
      await initialPointErmesCipherRegistry(key: 'alice');
      await initialPointErmesCipherRegistry(key: 'bob');

      final aliceCipher = getIErmesPeerCipherFromRegistry(key: 'alice');
      final bobCipher = getIErmesPeerCipherFromRegistry(key: 'bob');

      expect(aliceCipher, isNotNull);
      expect(bobCipher, isNotNull);
    });
  });
}
