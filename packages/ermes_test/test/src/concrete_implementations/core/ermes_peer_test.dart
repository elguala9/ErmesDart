import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  testErmesPeer();
}

/// Tests for ErmesPeer message sending
void testErmesPeer() {
  group('ErmesPeer - Message Sending', () {
    late TestErmesRepository repository;
    late ErmesService service;
    late IIdHandlerService idHandler;
    late ErmesPeer peer;

    setUpAll(initialPointErmesStorage);

    setUp(() async {
      idHandler = IdHandlerServiceFactory.createDefault();
      repository = await TestErmesRepository.create(open: true);
      service = ErmesServiceFactory.createService(
        100, 1024, repository, idHandler, null, null, null, null, null,
      );
      peer = ErmesPeer.create(
        service: service,
        remotePeerId: 'alice',
        enableEncryption: false,
      );
    });

    tearDown(() {
      repository.cleanUp();
    });

    group('send() method', () {
      test('sends message when service is open', () async {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        await peer.send(testData);

        expect(repository.sentData, isNotEmpty);
      });

      test('does not send when service is closed', () async {
        repository.openState = false;
        final testData = Uint8List.fromList([10, 20, 30]);

        await peer.send(testData);

        expect(repository.sentData, isEmpty);
      });

      test('throws error when peer is disposed', () {
        final testData = Uint8List.fromList([1, 2, 3]);

        peer.dispose();

        expect(
          () => peer.send(testData),
          throwsA(isA<StateError>()),
        );
      });

      test('tracks message count for key rotation', () async {
        final testData = Uint8List.fromList([1, 2, 3]);

        for (var i = 0; i < 5; i++) {
          await peer.send(testData);
        }

        expect(repository.sentData.length, equals(5));
      });
    });

    group('isConnected() method', () {
      test('returns true when service is open', () {
        repository.openState = true;
        expect(peer.isConnected(), isTrue);
      });

      test('returns false when service is closed', () {
        repository.openState = false;
        expect(peer.isConnected(), isFalse);
      });

      test('returns false after dispose()', () async {
        repository.openState = true;
        expect(peer.isConnected(), isTrue);

        await peer.dispose();

        expect(peer.isConnected(), isFalse);
      });

      test('reflects service state changes', () {
        repository.openState = true;
        expect(peer.isConnected(), isTrue);

        repository.openState = false;
        expect(peer.isConnected(), isFalse);

        repository.openState = true;
        expect(peer.isConnected(), isTrue);
      });
    });

    group('Edge cases', () {
      test('handles rapid send/close transitions', () async {
        final testData = Uint8List.fromList([1, 2, 3]);

        repository.openState = true;
        await peer.send(testData);
        expect(repository.sentData.length, equals(1));

        repository.openState = false;
        await peer.send(testData);
        expect(repository.sentData.length, equals(1));

        repository.openState = true;
        await peer.send(testData);
        expect(repository.sentData.length, equals(2));
      });
    });
  });
}
