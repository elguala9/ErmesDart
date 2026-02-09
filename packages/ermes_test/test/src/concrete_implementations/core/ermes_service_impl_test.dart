import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test concreti per ErmesService usando le factories
///
/// Testa l'implementazione concreta di IErmesService
@includeInBarrelFile
void testErmesServiceImplementation() {
  group('ErmesService Concrete Implementation', () {
    late ErmesService service;
    late IIdHandlerService idHandler;

    setUp(() {
      // Usa IdHandlerServiceFactory per creare istanza
      idHandler = IdHandlerServiceFactory.createDefault();
    });

    tearDown(() {
      // Cleanup
      service.close();
    });

    group('Service Creation', () {
      test('creates service with default factories', () {
        // Usa ErmesServiceFactory
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100,   // maxBuffer
          1024,  // maxByte
          repository,
          idHandler,
          null,  // callbackOnDataArrived
          null,  // ermesStorageAndCaching
          null,  // ermesMessageControlService
          null,  // missingMessagesCheckIntervalMs
          null,  // missingMessagesThreshold
        );

        expect(service, isNotNull);
      });

      test('service is initially disconnected', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        // Il repository mock non è connesso per default
        expect(service.isOpen(), isFalse);
      });
    });

    group('Message Callbacks', () {
      test('onMessageData registers callback', () {
        final mockRepository = _MockErmesRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, mockRepository, idHandler, null, null, null, null, null,
        );

        var callbackCalled = false;
        var receivedData = Uint8List(0);
        service.onMessageData((data) {
          callbackCalled = true;
          receivedData = data;
        });

        // Create properly serialized test message
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

        // Simula ricezione dati
        mockRepository.simulateDataReceived(serializedMessage);

        expect(callbackCalled, isTrue);
        expect(receivedData, equals(testData));
      });

      test('onDataSending registers callback', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(
          () => service.onDataSending((msg) {}),
          returnsNormally,
        );
      });

      test('onDataSent registers callback', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(
          () => service.onDataSent((id) {}),
          returnsNormally,
        );
      });
    });

    group('Message Sending', () {
      test('send does not throw', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        expect(() => service.send(data), returnsNormally);
      });

      test('send with empty data', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(() => service.send(Uint8List(0)), returnsNormally);
      });

      test('send with large data', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        final largeData = Uint8List(10000);
        expect(() => service.send(largeData), returnsNormally);
      });
    });

    group('Service Lifecycle', () {
      test('close does not throw', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(() => service.close(), returnsNormally);
      });

      test('close marks service as closed', () {
        final repository = _createMockRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        service.close();

        expect(service.isClosed(), isTrue);
      });
    });
  });
}

/// Mock minimalista di IErmesRepository per test
class _MockErmesRepository implements IErmesRepository {
  final List<Uint8List> sentData = [];
  void Function(Uint8List)? onDataCallback;
  bool _isConnected = false;

  @override
  void destroy({bool force = false}) {
    sentData.clear();
    onDataCallback = null;
  }

  @override
  bool isOpen() => _isConnected;

  @override
  void onMessageData(void Function(Uint8List) callback) {
    onDataCallback = callback;
  }

  @override
  void send(Uint8List data) {
    sentData.add(data);
  }

  @override
  bool isClosed() => false;

  @override
  Future<void> waitForClose([int? timeoutMs]) async {}

  @override
  Future<void> waitForConnect([int? timeoutMs]) async {}

  @override
  bool isClosing() => false;

  @override
  bool onClose(void Function() closeCallback) => false;

  @override
  bool onClosing(void Function() closingCallback) => false;

  @override
  bool onOpen(void Function() openCallback) => false;

  void simulateDataReceived(Uint8List data) {
    onDataCallback?.call(data);
  }
}

IErmesRepository _createMockRepository() => _MockErmesRepository();

void main() {
  testErmesServiceImplementation();
}
