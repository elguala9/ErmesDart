// This file can run standalone (dart test) or be imported by an aggregator.
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

/// Coverage for [ErmesCipherInjector].
///
/// Since singleton_manager 2.x there is one keyed registry rather than a
/// separate global container, so the former "singleton" and "registry" suites
/// collapse into this single keyed one.
Future<void> testInjectionCipher() async {
  group('ErmesCipherInjector', () {
    const key1 = 'test-cipher-injection-1';
    const key2 = 'test-cipher-injection-2';

    setUpAll(() async {
      const injector = ErmesCipherInjector();
      await injector.registerAllSingletonsErmesCipherAsync(key: key1);
      await injector.registerAllSingletonsErmesCipherAsync(key: key2);
    });

    group('Registration', () {
      test('registers IErmesPeerCipher', () {
        expect(
          RegistryManager.instance.getInstance<IErmesPeerCipher>(key: key1),
          isA<IErmesPeerCipher>(),
        );
      });

      test('registers IErmesPeerKeyExchange', () {
        expect(
          RegistryManager.instance
              .getInstance<IErmesPeerKeyExchange>(key: key1),
          isA<IErmesPeerKeyExchange>(),
        );
      });

      test('registers IKeyExchange', () {
        expect(
          RegistryManager.instance.getInstance<IKeyExchange>(key: key1),
          isA<IKeyExchange>(),
        );
      });

      test('all three registered objects are distinct instances', () {
        final registry = RegistryManager.instance;
        final cipher = registry.getInstance<IErmesPeerCipher>(key: key1);
        final kx = registry.getInstance<IErmesPeerKeyExchange>(key: key1);
        final keyExchange = registry.getInstance<IKeyExchange>(key: key1);
        expect(identical(cipher, kx), isFalse);
        expect(identical(kx, keyExchange), isFalse);
        expect(identical(cipher, keyExchange), isFalse);
      });
    });

    group('Identity', () {
      test('IKeyExchange is identical across repeated lookups', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IKeyExchange>(key: key1),
            registry.getInstance<IKeyExchange>(key: key1),
          ),
          isTrue,
        );
      });

      test('IErmesPeerKeyExchange is identical across repeated lookups', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesPeerKeyExchange>(key: key1),
            registry.getInstance<IErmesPeerKeyExchange>(key: key1),
          ),
          isTrue,
        );
      });
    });

    group('Independence between keys', () {
      test('different keys get different peer ciphers', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesPeerCipher>(key: key1),
            registry.getInstance<IErmesPeerCipher>(key: key2),
          ),
          isFalse,
        );
      });

      test('different keys get different key pairs', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IKeyExchange>(key: key1),
            registry.getInstance<IKeyExchange>(key: key2),
          ),
          isFalse,
        );
      });
    });

    group('Functional', () {
      test('a peer cipher throws until an encryption cipher is registered', () {
        final registry = RegistryManager.instance;
        for (final key in const [key1, key2]) {
          expect(
            () => registry
                .getInstance<IErmesPeerCipher>(key: key)
                .encrypt(Uint8List.fromList([1, 2, 3])),
            throwsA(isA<Exception>()),
          );
        }
      });

      test('two fresh key pairs can derive a symmetric key', () async {
        final alice = await ECDHKeyExchangeService.generateNewService();
        final bob = await ECDHKeyExchangeService.generateNewService();

        expect(alice.generateISymmetric(bob.serialize()), isNotNull);
        expect(bob.generateISymmetric(alice.serialize()), isNotNull);
      });
    });
  });
}

Future<void> main() => testInjectionCipher();
