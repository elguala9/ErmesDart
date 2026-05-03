import 'dart:io';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

/// Test concreti per ErmesService usando le factories
///
/// Testa l'implementazione concreta di IErmesService

void testErmesServiceImplementation() {
  group('ErmesService Concrete Implementation', () {
    late ErmesService service;
    late IIdHandlerService idHandler;
    late RawDatagramSocket? _currentRawSocket;

    setUpAll(initialPointErmesStorage);

    setUp(() {
      idHandler = IdHandlerServiceFactory.createDefault();
      _currentRawSocket = null;
    });

    tearDown(() {
      service.close();
      _currentRawSocket?.close();
    });

    group('Service Creation', () {
      test('creates service with default factories', () async {
        final repo = await createTestRepository(open: false);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100,   // maxBuffer
          1024,  // maxByte
          repo.repository,
          idHandler,
          null,  // callbackOnDataArrived
          null,  // ermesStorageAndCaching
          null,  // ermesMessageControlService
          null,  // missingMessagesCheckIntervalMs
          null,  // missingMessagesThreshold
        );

        expect(service, isNotNull);
      });

      test('service is initially disconnected', () async {
        final repo = await createTestRepository(open: false);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        expect(service.isOpen(), isFalse);
      });
    });

    group('Message Callbacks', () {
      test('addOnMessageDataListener registers callback', () async {
        final testRepository = await TestErmesRepository.create(open: false);
        _currentRawSocket = testRepository.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, testRepository, idHandler, null, null, null, null, null,
        );

        var callbackCalled = false;
        var receivedData = Uint8List(0);
        service.addOnMessageDataListener((data) {
          callbackCalled = true;
          receivedData = data;
        });

        final testData = Uint8List.fromList([1, 2, 3]);
        final messageData = MessageData(id: 1, data: testData);
        final internalMessage = InternalMessage(
          message: MessageType.data(messageData),
          type: MessageValue.base,
        );
        final serializedInternal = objectToUint8Array(internalMessage);
        final hash = calculateHashSync(serializedInternal);
        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: hash,
        );
        final serializedMessage = objectToUint8Array(messageRoot);

        testRepository.simulateDataReceived(serializedMessage);

        expect(callbackCalled, isTrue);
        expect(receivedData, equals(testData));
      });

      test('addOnDataSendingListener registers callback', () async {
        final repo = await createTestRepository(open: false);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        expect(
          () => service.addOnDataSendingListener((msg) {}),
          returnsNormally,
        );
      });

      test('addOnDataSentListener registers callback', () async {
        final repo = await createTestRepository(open: false);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        expect(
          () => service.addOnDataSentListener((id) {}),
          returnsNormally,
        );
      });

      test('addOnNewKeyListener registers callback', () async {
        final testRepository = await TestErmesRepository.create(open: false);
        _currentRawSocket = testRepository.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, testRepository, idHandler, null, null, null, null, null,
        );

        var callbackCalled = false;
        service.addOnNewKeyListener((newKey) {
          callbackCalled = true;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'a' * 64,
        );
        final internalMessage = InternalMessage(
          message: MessageType.service(newKeyMessage),
          type: MessageValue.service,
        );
        final serializedInternal = objectToUint8Array(internalMessage);
        final hash = calculateHashSync(serializedInternal);
        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: hash,
        );
        final serializedMessage = objectToUint8Array(messageRoot);

        testRepository.simulateDataReceived(serializedMessage);

        expect(callbackCalled, isTrue);
      });
    });

    group('Message Sending', () {
      setUp(() {
        ErmesPeerCipherHandler().remove('test-peer-id');
      });

      test('send does not throw', () async {
        final repo = await createTestRepository(open: true);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        expect(() => service.send(data), returnsNormally);
      });

      test('send with empty data', () async {
        final repo = await createTestRepository(open: true);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        expect(() => service.send(Uint8List(0)), returnsNormally);
      });

      test('send with large data', () async {
        final repo = await createTestRepository(open: true);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        final largeData = Uint8List(10000);
        await service.send(largeData);
      });
    });

    group('Service Lifecycle', () {
      test('close does not throw', () async {
        final repo = await createTestRepository(open: false);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        expect(() => service.close(), returnsNormally);
      });

      test('close marks service as closed', () async {
        final repo = await createTestRepository(open: false);
        _currentRawSocket = repo.rawSocket;
        service = ErmesServiceFactory.createService(
          100, 1024, repo.repository, idHandler, null, null, null, null, null,
        );

        service.close();

        expect(service.isClosed(), isTrue);
      });
    });
  });
}

void main() {
  testErmesServiceImplementation();
}
