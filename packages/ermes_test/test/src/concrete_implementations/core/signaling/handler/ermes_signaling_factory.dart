import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_signaling_helper.dart';

void testErmesSignalingFactories() {
  group('ErmesSignalingFactory', () {
    test('createRepository returns ErmesSignalingRepository', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );
        expect(repo, isA<ErmesSignalingRepository>());
      } finally {
        await setup.dispose();
      }
    });

    test('createService returns ErmesSignalingService', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );
        final service = ErmesSignalingFactory.createService(repo);
        expect(service, isA<ErmesSignalingService>());
      } finally {
        await setup.dispose();
      }
    });

    test('createBoth returns repository and service', () async {
      final setup = await createTestSignalingSetup();
      try {
        final (repo, service) = ErmesSignalingFactory.createBoth(
          setup.signalingServer,
          setup.signalingHandler,
        );
        expect(repo, isA<ErmesSignalingRepository>());
        expect(service, isA<ErmesSignalingService>());
      } finally {
        await setup.dispose();
      }
    });

    test('createBoth creates linked repo and service', () async {
      final setup = await createTestSignalingSetup();
      try {
        final (repo, service) = ErmesSignalingFactory.createBoth(
          setup.signalingServer,
          setup.signalingHandler,
        );
        expect(repo, isNotNull);
        expect(service, isNotNull);
      } finally {
        await setup.dispose();
      }
    });
  });

  group('ErmesBookFactories', () {
    test('createRepository returns ErmesBookRepository', () {
      final repo = ErmesBookFactories.createRepository();
      expect(repo, isNotNull);
      expect(repo.numberOfElements(), equals(0));
    });

    test('each call returns a fresh, independent instance', () {
      final first = ErmesBookFactories.createRepository()
        ..setAccount(AccountInfo<BookData>(
          account: 'peer-1',
          info: BookData(peerId: 'peer-1', name: 'Peer One', timestamp: 0),
        ));
      final second = ErmesBookFactories.createRepository();
      expect(first.numberOfElements(), equals(1));
      expect(second.numberOfElements(), equals(0));
    });
  });

  group('ErmesBookRepositoryFactory', () {
    test('createDefault returns an empty repository', () {
      final repo = ErmesBookRepositoryFactory.createDefault();
      expect(repo.numberOfElements(), equals(0));
    });

    test('each call returns a fresh, independent instance', () {
      final first = ErmesBookRepositoryFactory.createDefault()
        ..setAccount(AccountInfo<BookData>(
          account: 'peer-1',
          info: BookData(peerId: 'peer-1', name: 'Peer One', timestamp: 0),
        ));
      final second = ErmesBookRepositoryFactory.createDefault();
      expect(first.numberOfElements(), equals(1));
      expect(second.numberOfElements(), equals(0));
    });
  });

  group('ErmesSignalingServerFactory', () {
    test('createFromKeys is defined', () {
      expect(ErmesSignalingServerFactory.createFromKeys, isA<Function>());
    });

    test('createFromConfig is defined', () {
      expect(ErmesSignalingServerFactory.createFromConfig, isA<Function>());
    });

    test('createFromKeys rejects a mismatched key pair before touching '
        'the network', () async {
      await expectLater(
        ErmesSignalingServerFactory.createFromKeys(
          pubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          privkey: '00000000000000000000000000000000'
              '00000000000000000000000000000001',
          accountId: 'test-account',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createFromConfig rejects a nonexistent config path', () async {
      await expectLater(
        ErmesSignalingServerFactory.createFromConfig(
          accountId: 'test-account',
          configPath: 'this/config/does/not/exist.json',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
