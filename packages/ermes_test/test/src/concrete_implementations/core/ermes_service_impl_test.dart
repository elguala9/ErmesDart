import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:crypto/crypto.dart';
import 'package:ermes_core/ermes_core.dart';
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
        final repository = _createTestRepository();
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
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        // Il repository mock non è connesso per default
        expect(service.isOpen(), isFalse);
      });
    });

    group('Message Callbacks', () {
      test('addOnMessageDataListener registers callback', () {
        final testRepository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, testRepository, idHandler, null, null, null, null, null,
        );

        var callbackCalled = false;
        var receivedData = Uint8List(0);
        service.addOnMessageDataListener((data) {
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
        final hash = sha256.convert(serializedInternal);
        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: hash,
        );
        final serializedMessage = objectToUint8Array(messageRoot);

        // Simula ricezione dati
        testRepository.simulateDataReceived(serializedMessage);

        expect(callbackCalled, isTrue);
        expect(receivedData, equals(testData));
      });

      test('addOnDataSendingListener registers callback', () {
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(
          () => service.addOnDataSendingListener((msg) {}),
          returnsNormally,
        );
      });

      test('addOnDataSentListener registers callback', () {
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(
          () => service.addOnDataSentListener((id) {}),
          returnsNormally,
        );
      });

      test('addOnNewKeyListener registers callback', () {
        final testRepository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, testRepository, idHandler, null, null, null, null, null,
        );

        var callbackCalled = false;
        service.addOnNewKeyListener((newKey) {
          callbackCalled = true;
        });

        // Create and send a ServiceMessageNewKey
        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key-material',
        );
        final internalMessage = InternalMessage(
          message: MessageType.service(newKeyMessage),
          type: MessageValue.service,
        );
        final serializedInternal = objectToUint8Array(internalMessage);
        final hash = sha256.convert(serializedInternal);
        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: hash,
        );
        final serializedMessage = objectToUint8Array(messageRoot);

        // Simulate receiving the new key message
        testRepository.simulateDataReceived(serializedMessage);

        expect(callbackCalled, isTrue);
      });
    });

    group('Message Sending', () {
      test('send does not throw', () {
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        expect(() => service.send(data), returnsNormally);
      });

      test('send with empty data', () {
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(() => service.send(Uint8List(0)), returnsNormally);
      });

      test('send with large data', () {
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        final largeData = Uint8List(10000);
        expect(() => service.send(largeData), returnsNormally);
      });
    });

    group('Service Lifecycle', () {
      test('close does not throw', () {
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        expect(() => service.close(), returnsNormally);
      });

      test('close marks service as closed', () {
        final repository = _createTestRepository();
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler, null, null, null, null, null,
        );

        // ignore: cascade_invocations
        service.close();

        expect(service.isClosed(), isTrue);
      });
    });
  });
}

/// Test implementation of IErmesRepository
class _TestErmesRepository implements IErmesRepository {
  final List<Uint8List> sentData = [];
  final List<void Function(Uint8List)> _dataCallbacks = [];
  final bool _isConnected = false;

  @override
  void destroy({bool force = false}) {
    sentData.clear();
    _dataCallbacks.clear();
  }

  @override
  bool isOpen() => _isConnected;

  @override
  void addOnMessageDataListener(void Function(Uint8List) callback) {
    _dataCallbacks.add(callback);
  }

  @override
  void removeOnMessageDataListener(void Function(Uint8List) callback) {
    _dataCallbacks.remove(callback);
  }

  @override
  void clearOnMessageDataListeners() {
    _dataCallbacks.clear();
  }

  @override
  void send(Uint8List data) {
    sentData.add(data);
  }

  @override
  bool isClosed() => false;

  Future<void> waitForClose([int? timeoutMs]) async {}

  Future<void> waitForConnect([int? timeoutMs]) async {}

  @override
  bool isClosing() => false;

  bool onClose(void Function() closeCallback) => false;

  bool onClosing(void Function() closingCallback) => false;

  bool onOpen(void Function() openCallback) => false;

  void simulateDataReceived(Uint8List data) {
    for (final callback in _dataCallbacks) {
      callback(data);
    }
  }
}

IErmesRepository _createTestRepository() => _TestErmesRepository();

void main() {
  testErmesServiceImplementation();
}
