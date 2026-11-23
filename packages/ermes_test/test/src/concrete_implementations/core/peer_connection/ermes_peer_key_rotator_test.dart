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
        null, null, null, null,
      );
    });

    tearDown(() {
      service.close();
      repository.cleanUp();
      ErmesPeerCipherHandler().remove(repository.cipherKey);
    });

    group('onMessageSent()', () {
      test('does not rotate before the message interval is reached', () {
        ErmesPeerCipherHandler()
            .set(repository.cipherKey, ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(
          service: service,
          intervalMessages: 5,
        );

        for (var i = 0; i < 4; i++) {
          rotator.onMessageSent();
        }

        expect(repository.sentData, isEmpty);
        rotator.dispose();
      });

      test('rotates once the message interval is reached', () {
        ErmesPeerCipherHandler()
            .set(repository.cipherKey, ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(
          service: service,
          intervalMessages: 3,
        );

        for (var i = 0; i < 3; i++) {
          rotator.onMessageSent();
        }

        expect(repository.sentData, isNotEmpty);
        rotator.dispose();
      });

      test('resets the message counter after rotating', () async {
        ErmesPeerCipherHandler()
            .set(repository.cipherKey, ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(
          service: service,
          intervalMessages: 2,
        )
          ..onMessageSent()
          ..onMessageSent();
        // Let the first rotation finish (newkey sent, key switched).
        await Future<void>.delayed(const Duration(milliseconds: 20));
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
          intervalMessages: 1,
        )..onMessageSent();

        expect(repository.sentData, isEmpty);
        rotator.dispose();
      });
    });

    group('protocol parameters (RFC 7.5)', () {
      test('default interval is the version 3.0 N', () {
        ErmesPeerCipherHandler()
            .set(repository.cipherKey, ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(service: service);
        final n = ErmesProtocolParameters.current.sessionKeyRotationMessages;
        for (var i = 0; i < n - 1; i++) {
          rotator.onMessageSent();
        }
        expect(repository.sentData, isEmpty);

        rotator.onMessageSent();
        expect(repository.sentData, isNotEmpty);
        rotator.dispose();
      });

      test('no time-based symmetric rotation', () async {
        ErmesPeerCipherHandler()
            .set(repository.cipherKey, ErmesPeerCipher());
        final rotator = ErmesPeerKeyRotator(service: service);

        await Future<void>.delayed(const Duration(milliseconds: 1300));

        expect(repository.sentData, isEmpty);
        rotator.dispose();
      });
    });

    group('dispose()', () {
      test('is idempotent', () {
        final rotator = ErmesPeerKeyRotator(
          service: service,
          intervalMessages: 5,
        );

        expect(rotator.dispose, returnsNormally);
        expect(rotator.dispose, returnsNormally);
      });

      test('prevents further rotation via onMessageSent after dispose', () {
        ErmesPeerCipherHandler()
            .set(repository.cipherKey, ErmesPeerCipher());
        ErmesPeerKeyRotator(
          service: service,
          intervalMessages: 1,
        )
          ..dispose()
          ..onMessageSent();

        expect(repository.sentData, isEmpty);
      });
    });
  });
}
