// This file can run standalone (dart test) or be imported by an aggregator.
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Coverage for [ErmesSignalingInjector] on its own, without going through
/// `ermes_core_init`'s [initializeErmes] — isolates whether ermes_signaling's
/// own DI graph is complete (every entry the generator wrote plus the
/// hand-maintained bridges in
/// [ErmesSignalingInjector.afterRegisterAllSingletonsErmesSignaling] resolve
/// without a missing dependency).
///
/// `initializeStunShsp: true` is required: [ErmesSignalingHandler] resolves
/// `IStunShspHandler`/`IShspSocket` under the `ipv4` subkey, which only
/// stun_shsp's own injector registers. `connectSignaling: false` throughout
/// keeps this offline — no real relay.
void testInjectionSignaling() {
  group('ErmesSignalingInjector', () {
    const key1 = 'test-signaling-injection-1';
    const key2 = 'test-signaling-injection-2';

    setUpAll(() async {
      await Future.wait([_initialize(key1), _initialize(key2)]);
    });

    group('Registration', () {
      test('registers IErmesBookRepository', () {
        expect(
          RegistryManager.instance.getInstance<IErmesBookRepository<dynamic>>(
            key: key1,
          ),
          isA<IErmesBookRepository<dynamic>>(),
        );
      });

      test('registers IErmesBookService', () {
        expect(
          RegistryManager.instance.getInstance<IErmesBookService<dynamic>>(
            key: key1,
          ),
          isA<IErmesBookService<dynamic>>(),
        );
      });

      test('registers IErmesSignalingHandler', () {
        expect(
          RegistryManager.instance.getInstance<IErmesSignalingHandler<dynamic>>(
            key: key1,
          ),
          isA<IErmesSignalingHandler<dynamic>>(),
        );
      });

      test('registers IErmesSignalingRepository', () {
        expect(
          RegistryManager.instance
              .getInstance<IErmesSignalingRepository<dynamic>>(key: key1),
          isA<IErmesSignalingRepository<dynamic>>(),
        );
      });

      test('registers IErmesSignalingService', () {
        expect(
          RegistryManager.instance.getInstance<IErmesSignalingService>(
            key: key1,
          ),
          isA<IErmesSignalingService>(),
        );
      });

      test('registers IErmesSignalingServer', () {
        expect(
          RegistryManager.instance.getInstance<IErmesSignalingServer>(
            key: key1,
          ),
          isA<IErmesSignalingServer>(),
        );
      });

      test(
        'registers INostrSignaling (supplied by NostrSignalingInjection)',
        () {
          expect(
            RegistryManager.instance.getInstance<INostrSignaling>(key: key1),
            isA<INostrSignaling>(),
          );
        },
      );

      test('registers IdAccountType for this peer', () {
        expect(
          RegistryManager.instance.getInstance<IdAccountType>(key: key1),
          isA<IdAccountType>(),
        );
      });
    });

    group('Bridged parameterized entries', () {
      test('IErmesBookRepository<BookData> resolves to the same instance as '
          'the raw entry', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesBookRepository<BookData>>(key: key1),
            registry.getInstance<IErmesBookRepository<dynamic>>(key: key1),
          ),
          isTrue,
        );
      });

      test('IErmesBookService<BookData> resolves to the same instance as '
          'the raw entry', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesBookService<BookData>>(key: key1),
            registry.getInstance<IErmesBookService<dynamic>>(key: key1),
          ),
          isTrue,
        );
      });

      test('IErmesSignalingHandler<IShspPeer> resolves to the same instance '
          'as the raw entry', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesSignalingHandler<IShspPeer>>(key: key1),
            registry.getInstance<IErmesSignalingHandler<dynamic>>(key: key1),
          ),
          isTrue,
        );
      });

      test('IErmesSignalingHandler<ShspPeer> resolves to the same instance '
          'as the raw entry', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesSignalingHandler<ShspPeer>>(key: key1),
            registry.getInstance<IErmesSignalingHandler<dynamic>>(key: key1),
          ),
          isTrue,
        );
      });

      test('IErmesSignalingRepository<ISignalErmes> resolves to the same '
          'instance as the raw entry', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesSignalingRepository<ISignalErmes>>(
              key: key1,
            ),
            registry.getInstance<IErmesSignalingRepository<dynamic>>(key: key1),
          ),
          isTrue,
        );
      });
    });

    group('Independence between keys', () {
      test('different keys get different signaling services', () {
        final registry = RegistryManager.instance;
        expect(
          identical(
            registry.getInstance<IErmesSignalingService>(key: key1),
            registry.getInstance<IErmesSignalingService>(key: key2),
          ),
          isFalse,
        );
      });

      test('different keys get different account ids', () {
        final registry = RegistryManager.instance;
        expect(
          registry.getInstance<IdAccountType>(key: key1),
          isNot(equals(registry.getInstance<IdAccountType>(key: key2))),
        );
      });
    });

    group('Error Handling and DI Edge Cases', () {
      test('resolving IErmesSignalingHandler without initializeStunShsp '
          'throws — the ipv4 STUN/SHSP subkey is missing', () async {
        const badKey = 'test-signaling-injection-no-stun';
        const injector = ErmesSignalingInjector();
        await injector.registerAllSingletonsErmesSignalingAsync(key: badKey);

        expect(
          () => RegistryManager.instance
              .getInstance<IErmesSignalingHandler<dynamic>>(key: badKey),
          throwsA(anything),
        );
      });

      test('getInstance for a completely unregistered key throws', () {
        expect(
          () => RegistryManager.instance.getInstance<IErmesSignalingService>(
            key: 'never-registered-signaling-key',
          ),
          throwsA(isA<RegistryNotFoundError>()),
        );
      });
    });
  });
}

/// Boots a signaling stack under [key] with a throw-away Nostr identity,
/// offline. Mirrors `_initialize` in `injection_orc_ermes_test.dart` but
/// exercises [ErmesSignalingInjector] directly instead of the full
/// `initializeErmes` orchestration.
Future<void> _initialize(String key) async {
  final keyPair = NostrKeys.generate();
  final injector = ErmesSignalingInjector(
    keyPair: keyPair,
    accountId: keyPair.publicKey,
    initializeStunShsp: true,
  );
  await injector.registerAllSingletonsErmesSignalingAsync(key: key);
}

void main() {
  testInjectionSignaling();
}
