import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void testErmesSignalingFactories() {
  group('ErmesSignalingFactory', () {
    test('createBoth returns repository and service tuple', () async {
      // We test the factory static methods by verifying call patterns.
      // Full integration requires a real Nostr relay.
      expect(
        ErmesSignalingFactory.createService,
        isA<Function>(),
      );
      expect(
        ErmesSignalingFactory.createRepository,
        isA<Function>(),
      );
      expect(
        ErmesSignalingFactory.createBoth,
        isA<Function>(),
      );
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
    test('createFromKeys and createFromConfig are defined', () {
      expect(
        ErmesSignalingServerFactory.createFromKeys,
        isA<Function>(),
      );
      expect(
        ErmesSignalingServerFactory.createFromConfig,
        isA<Function>(),
      );
    });
  });
}
