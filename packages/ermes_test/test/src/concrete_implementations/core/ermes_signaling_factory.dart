import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

import '../../test_signaling_helper.dart';

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
  });

  group('ErmesSignalingServerFactory', () {
    test('createFromKeys is defined', () {
      expect(ErmesSignalingServerFactory.createFromKeys, isA<Function>());
    });

    test('createFromConfig is defined', () {
      expect(ErmesSignalingServerFactory.createFromConfig, isA<Function>());
    });
  });
}
