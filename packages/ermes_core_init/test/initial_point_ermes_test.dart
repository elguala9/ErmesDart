@TestOn('vm')
library;
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void main() {
  group('initialPointErmes [singleton]', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test('returns IOrcErmes with Nostr + stun_shsp', () async {
      final keyPair = NostrKeys.generate();

      final orc = await initialPointErmes(
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      expect(orc, isA<IOrcErmes<BookData>>());
      expect(orc, isNotNull);
    });

    test('registered instance is the same as returned one', () async {
      final keyPair = NostrKeys.generate();

      final orc = await initialPointErmes(
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      final fromDi = getIOrcErmes();
      expect(identical(orc, fromDi), isTrue,
          reason: 'returned instance must be the singleton');
    });
  });

  group('initialPointErmesRegistry [registry]', () {
    setUp(RegistryAccess.clearRegistry);

    test('returns IOrcErmes with Nostr + stun_shsp', () async {
      final keyPair = NostrKeys.generate();

      final orc = await initialPointErmesRegistry(
        key: 'test',
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      expect(orc, isA<IOrcErmes<BookData>>());
      expect(orc, isNotNull);
    });

    test('registered instance is the same as returned one', () async {
      const key = 'identity-check';
      final keyPair = NostrKeys.generate();

      final orc = await initialPointErmesRegistry(
        key: key,
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );

      final fromRegistry = getIOrcErmesFromRegistry(key: key);
      expect(identical(orc, fromRegistry), isTrue,
          reason: 'returned instance must match registry entry');
    });

    test('supports multiple independent registry keys', () async {
      final aliceKeys = NostrKeys.generate();
      final bobKeys = NostrKeys.generate();

      final alice = await initialPointErmesRegistry(
        key: 'alice',
        keyPair: aliceKeys,
        accountId: aliceKeys.publicKey,
        initializeStunShsp: true,
      );
      final bob = await initialPointErmesRegistry(
        key: 'bob',
        keyPair: bobKeys,
        accountId: bobKeys.publicKey,
        initializeStunShsp: true,
      );

      expect(alice, isA<IOrcErmes<BookData>>());
      expect(bob, isA<IOrcErmes<BookData>>());
      expect(identical(alice, bob), isFalse,
          reason: 'different keys must return different instances');
    });
  });
}
