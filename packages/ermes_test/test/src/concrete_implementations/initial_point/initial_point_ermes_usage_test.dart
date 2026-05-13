import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

// ===========================================================================
//  initialPointErmes  (SINGLETON)
// ===========================================================================

void testInitialPointErmesUsage() {
  group('initialPointErmes [singleton]', () {
    late IOrcErmes<BookData> orc;

    setUpAll(() async {
      SingletonManager.instance.clearRegistry();
      final keyPair = NostrKeys.generate();
      orc = await initialPointErmes(
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
      );
    });

    tearDownAll(() async {
      await orc.destroy();
    });

    group('Registration', () {
      test('returns IOrcErmes', () {
        expect(orc, isA<IOrcErmes<BookData>>());
        expect(orc, isNotNull);
      });

      test('registers IOrcErmes in SingletonDIAccess', () {
        expect(SingletonDIAccess.exists<IOrcErmes<BookData>>(), isTrue);
      });

      test('getter returns same instance as initial point', () {
        final fromDi = getIOrcErmes();
        expect(identical(orc, fromDi), isTrue);
      });
    });

    group('Functional', () {
      test('getConnections returns empty list with no active connections', () async {
        final connections = await orc.getConnections();
        expect(connections, isA<List<IdPeer>>());
        expect(connections, isEmpty);
      });

      test('destroy can be called without errors', () async {
        final keyPair = NostrKeys.generate();
        final temp = await initialPointErmes(
          keyPair: keyPair,
          accountId: keyPair.publicKey,
          initializeStunShsp: true,
        );
        await temp.destroy();
      });
    });
  });
}

// ===========================================================================
//  initialPointErmesRegistry  (REGISTRY)
// ===========================================================================

void testInitialPointErmesRegistryUsage() {
  group('initialPointErmesRegistry [registry]', () {
    late IOrcErmes<BookData> orc1;
    late IOrcErmes<BookData> orc2;
    const key1 = 'ermes-usage-1';
    const key2 = 'ermes-usage-2';

    setUpAll(() async {
      RegistryAccess.clearRegistry();
      final kp1 = NostrKeys.generate();
      final kp2 = NostrKeys.generate();

      orc1 = await initialPointErmesRegistry(
        key: key1,
        keyPair: kp1,
        accountId: kp1.publicKey,
        initializeStunShsp: true,
      );
      orc2 = await initialPointErmesRegistry(
        key: key2,
        keyPair: kp2,
        accountId: kp2.publicKey,
        initializeStunShsp: true,
      );
    });

    tearDownAll(() async {
      await orc1.destroy();
      await orc2.destroy();
    });

    group('Registration', () {
      test('key1: returns IOrcErmes', () {
        expect(orc1, isA<IOrcErmes<BookData>>());
        expect(orc1, isNotNull);
      });

      test('key2: returns IOrcErmes', () {
        expect(orc2, isA<IOrcErmes<BookData>>());
        expect(orc2, isNotNull);
      });

      test('key1: getter returns same instance', () {
        final fromReg = getIOrcErmesFromRegistry(key: key1);
        expect(identical(orc1, fromReg), isTrue);
      });

      test('key2: getter returns same instance', () {
        final fromReg = getIOrcErmesFromRegistry(key: key2);
        expect(identical(orc2, fromReg), isTrue);
      });
    });

    group('Independence between keys', () {
      test('different keys return different OrcErmes instances', () {
        expect(identical(orc1, orc2), isFalse);
      });

      test('different keys have independent registry entries', () {
        final from1 = getIOrcErmesFromRegistry(key: key1);
        final from2 = getIOrcErmesFromRegistry(key: key2);
        expect(identical(from1, from2), isFalse);
      });
    });

    group('Functional', () {
      test('key1: getConnections returns empty with no active connections', () async {
        final connections = await orc1.getConnections();
        expect(connections, isA<List<IdPeer>>());
        expect(connections, isEmpty);
      });

      test('key2: getConnections returns empty with no active connections', () async {
        final connections = await orc2.getConnections();
        expect(connections, isA<List<IdPeer>>());
        expect(connections, isEmpty);
      });
    });
  });
}

// ===========================================================================
//  main  (standalone runner)
// ===========================================================================

void main() {
  testInitialPointErmesUsage();
  testInitialPointErmesRegistryUsage();
}
