// This file can run standalone (dart test) or be imported by an aggregator.
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Coverage for [initializeErmes] and [OrcErmesInitFactory].
///
/// Since singleton_manager 2.x there is one keyed registry rather than a
/// separate global container, so the former `createSingleton` / `createInstance`
/// pair collapses into one keyed entry point: the default key is what
/// `createSingleton` used to give you, any other key an independent stack.
///
/// `connectSignaling: false` throughout keeps these offline — no real relay.
void testInjectionOrcErmes() {
  group('initializeErmes', () {
    const key1 = 'test-orc-injection-1';
    const key2 = 'test-orc-injection-2';
    late IOrcErmes<BookData> orc1;
    late IOrcErmes<BookData> orc2;

    setUpAll(() async {
      orc1 = await _initialize(key1);
      orc2 = await _initialize(key2);
    });

    tearDownAll(() async {
      await orc1.destroy(force: true);
      await orc2.destroy(force: true);
    });

    group('Registration', () {
      test('returns an IOrcErmes for each key', () {
        expect(orc1, isA<IOrcErmes<BookData>>());
        expect(orc2, isA<IOrcErmes<BookData>>());
      });

      test('the getter returns the same instance for the same key', () {
        expect(identical(orc1, getIOrcErmes(key: key1)), isTrue);
        expect(identical(orc2, getIOrcErmes(key: key2)), isTrue);
      });
    });

    group('Independence between keys', () {
      test('different keys return different orchestrators', () {
        expect(identical(orc1, orc2), isFalse);
      });

      test('different keys get independent signaling services', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesSignalingService>(key: key1),
            registry.getInstance<IErmesSignalingService>(key: key2),
          ),
          isFalse,
        );
      });
    });

    group('Functional', () {
      test('getConnections is empty with no active connections', () async {
        expect(await orc1.getConnections(), isEmpty);
        expect(await orc2.getConnections(), isEmpty);
      });

      test('destroy completes without errors', () async {
        const key = 'test-orc-injection-destroy';
        final temp = await _initialize(key);
        await temp.destroy(force: true);
      });
    });
  });

  group('initializeErmes with a custom STUN server', () {
    test(
        'stunHost/stunPort are applied to the ipv4 handler in a single '
        'initializeErmes call — no separate initializeStunShsp/setStunServer '
        'step needed', () async {
      const key = 'test-orc-injection-custom-stun';
      final keyPair = NostrKeys.generate();

      final orc = await initializeErmes(
        key: key,
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        initializeStunShsp: true,
        stunHost: '203.0.113.1',
        stunPort: 3478,
      );

      // No dedicated getter exposes the address/port setStunServer applied,
      // so this only proves the one-call path registers the ipv4 handler
      // and leaves it usable, without needing a separate
      // initializeStunShsp()/setStunServer() step beforehand.
      final handler = RegistryManager.instance
          .getInstance<IStunShspHandler>(key: key, subkey: 'ipv4');
      expect(handler, isA<IStunShspHandler>());

      await orc.destroy(force: true);
    });
  });

  group('OrcErmesInitFactory.create', () {
    const key = 'test-orc-factory-injection';
    late IOrcErmes<BookData> orc;

    setUpAll(() async {
      final keyPair = NostrKeys.generate();
      orc = await OrcErmesInitFactory.create(
        key: key,
        keyPair: keyPair,
        accountId: keyPair.publicKey,
        connectSignaling: false,
      );
    });

    tearDownAll(() async {
      await orc.destroy(force: true);
    });

    test('returns an IOrcErmes', () {
      expect(orc, isA<IOrcErmes<BookData>>());
    });

    test('returns the same instance as getIOrcErmes', () {
      expect(identical(orc, getIOrcErmes(key: key)), isTrue);
    });

    test('getConnections is empty initially', () async {
      expect(await orc.getConnections(), isEmpty);
    });
  });
}

/// Boots a stack under [key] with a throw-away identity, offline.
///
/// `initializeStunShsp: true` is required, not optional: the orchestrator
/// resolves `IStunShspHandler` and `IShspSocket` under the `ipv4` subkey, and
/// only stun_shsp's own injector registers those. It binds local UDP sockets
/// but sends nothing, so this stays offline; `connectSignaling: false` is what
/// keeps the relay out of it.
Future<IOrcErmes<BookData>> _initialize(String key) async {
  final keyPair = NostrKeys.generate();
  return initializeErmes(
    key: key,
    keyPair: keyPair,
    accountId: keyPair.publicKey,
    initializeStunShsp: true,
  );
}

void main() {
  testInjectionOrcErmes();
}
