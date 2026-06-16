import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

// ===========================================================================
//  OrcErmesInitFactory.createSingleton  (SINGLETON)
// ===========================================================================

void testOrcErmesInitFactorySingleton() {
  group('OrcErmesInitFactory.createSingleton', () {
    late IOrcErmes<BookData> orc;

    setUpAll(() async {
      SingletonManager.instance.clearRegistry();
      final keyPair = NostrKeys.generate();
      // connectSignaling: false keeps the test offline (no real relay).
      orc = await OrcErmesInitFactory.createSingleton(
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        connectSignaling: false,
      );
    });

    tearDownAll(() async {
      await orc.destroy();
    });

    test('returns IOrcErmes', () {
      expect(orc, isA<IOrcErmes<BookData>>());
    });

    test('registers IOrcErmes in SingletonDIAccess', () {
      expect(SingletonDIAccess.exists<IOrcErmes<BookData>>(), isTrue);
    });

    test('returns the same instance as getIOrcErmes', () {
      expect(identical(orc, getIOrcErmes()), isTrue);
    });

    test('getConnections is empty initially', () async {
      expect(await orc.getConnections(), isEmpty);
    });
  });
}

// ===========================================================================
//  OrcErmesInitFactory.createInstance  (REGISTRY)
// ===========================================================================

void testOrcErmesInitFactoryInstance() {
  group('OrcErmesInitFactory.createInstance [registry]', () {
    late IOrcErmes<BookData> orc1;
    late IOrcErmes<BookData> orc2;
    const key1 = 'init-factory-1';
    const key2 = 'init-factory-2';

    setUpAll(() async {
      RegistryAccess.clearRegistry();
      final kp1 = NostrKeys.generate();
      final kp2 = NostrKeys.generate();
      orc1 = await OrcErmesInitFactory.createInstance(
        key: key1,
        keyPair: kp1,
        accountId: kp1.publicKey,
        connectSignaling: false,
      );
      orc2 = await OrcErmesInitFactory.createInstance(
        key: key2,
        keyPair: kp2,
        accountId: kp2.publicKey,
        connectSignaling: false,
      );
    });

    tearDownAll(() async {
      await orc1.destroy();
      await orc2.destroy();
    });

    test('both keys return IOrcErmes', () {
      expect(orc1, isA<IOrcErmes<BookData>>());
      expect(orc2, isA<IOrcErmes<BookData>>());
    });

    test('getters return the same instances', () {
      expect(identical(orc1, getIOrcErmesFromRegistry(key: key1)), isTrue);
      expect(identical(orc2, getIOrcErmesFromRegistry(key: key2)), isTrue);
    });

    test('different keys return different instances', () {
      expect(identical(orc1, orc2), isFalse);
    });

    test('getConnections is empty for both', () async {
      expect(await orc1.getConnections(), isEmpty);
      expect(await orc2.getConnections(), isEmpty);
    });
  });
}

// ===========================================================================
//  main  (standalone runner)
// ===========================================================================

void main() {
  testOrcErmesInitFactorySingleton();
  testOrcErmesInitFactoryInstance();
}
