import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  testErmesPeerKeyRotator();
}

void testErmesPeerKeyRotator() {
  group('ErmesPeerKeyRotator', () {
    late IIdHandlerService idHandler;
    late TestErmesRepository repository;
    late ErmesService service;
    var testCounter = 0;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      testCounter++;
      idHandler = IdHandlerServiceFactory.createDefault();
      repository = await TestErmesRepository.create(
        open: true,
        peerId: 'rotator-peer-$testCounter',
      );
      service = ErmesServiceFactory.createService(
        100, 1024, repository, idHandler,
        null, null, null, null, null,
      );
    });

    tearDown(() {
      service.close();
      repository.cleanUp();
      ErmesPeerCipherHandler().remove('rotator-peer-$testCounter');
    });

    group('onMessageSent()', () {
      test('does not rotate before the message interval is reached', () {
        ErmesPeerCipherHandler()
            .set('rotator-peer-$testCounter', ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'rotator-peer-$testCounter',
          intervalMessages: 5,
          intervalSeconds: 3600,
        );

        for (var i = 0; i < 4; i++) {
          rotator.onMessageSent();
        }

        expect(repository.sentData, isEmpty);
        rotator.dispose();
      });

      test('rotates once the message interval is reached', () {
        ErmesPeerCipherHandler()
            .set('rotator-peer-$testCounter', ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'rotator-peer-$testCounter',
          intervalMessages: 3,
          intervalSeconds: 3600,
        );

        for (var i = 0; i < 3; i++) {
          rotator.onMessageSent();
        }

        expect(repository.sentData, isNotEmpty);
        rotator.dispose();
      });

      test('resets the message counter after rotating', () {
        ErmesPeerCipherHandler()
            .set('rotator-peer-$testCounter', ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'rotator-peer-$testCounter',
          intervalMessages: 2,
          intervalSeconds: 3600,
        )
          ..onMessageSent()
          ..onMessageSent();
        final countAfterFirstRotation = repository.sentData.length;

        rotator.onMessageSent();
        expect(repository.sentData.length, equals(countAfterFirstRotation));

        rotator.onMessageSent();
        expect(
          repository.sentData.length,
          greaterThan(countAfterFirstRotation),
        );
        rotator.dispose();
      });

      test('does nothing when no peer cipher is registered', () {
        final rotator = ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'never-registered-peer',
          intervalMessages: 1,
          intervalSeconds: 3600,
        )..onMessageSent();

        expect(repository.sentData, isEmpty);
        rotator.dispose();
      });
    });

    group('start() / periodic rotation', () {
      test('rotates periodically once the timer interval elapses', () async {
        ErmesPeerCipherHandler()
            .set('rotator-peer-$testCounter', ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'rotator-peer-$testCounter',
          intervalMessages: 1000000,
          intervalSeconds: 1,
        )..start();

        await Future<void>.delayed(const Duration(milliseconds: 1300));

        expect(repository.sentData, isNotEmpty);
        rotator.dispose();
      });
    });

    group('dispose()', () {
      test('stops the periodic timer', () async {
        ErmesPeerCipherHandler()
            .set('rotator-peer-$testCounter', ErmesPeerCipher());
        ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'rotator-peer-$testCounter',
          intervalMessages: 1000000,
          intervalSeconds: 1,
        )
          ..start()
          ..dispose();
        await Future<void>.delayed(const Duration(milliseconds: 1300));

        expect(repository.sentData, isEmpty);
      });

      test('is idempotent', () {
        final rotator = ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'rotator-peer-$testCounter',
          intervalMessages: 5,
          intervalSeconds: 3600,
        );

        expect(rotator.dispose, returnsNormally);
        expect(rotator.dispose, returnsNormally);
      });

      test('prevents further rotation via onMessageSent after dispose', () {
        ErmesPeerCipherHandler()
            .set('rotator-peer-$testCounter', ErmesPeerCipher());
        ErmesPeerKeyRotator(
          service: service,
          remotePeerId: 'rotator-peer-$testCounter',
          intervalMessages: 1,
          intervalSeconds: 3600,
        )
          ..dispose()
          ..onMessageSent();

        expect(repository.sentData, isEmpty);
      });
    });
  });
}
