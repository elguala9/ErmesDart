import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:crypto/crypto.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test completi per il callback system di ServiceMessageNewKey
///
/// Testa l'implementazione del callback pattern per la gestione di messaggi
/// di scambio chiavi (ServiceMessageNewKey) in ErmesService
@includeInBarrelFile
void testNewKeyCallbackSystem() {
  group('ErmesService NewKey Callback System', () {
    late ErmesService service;
    late IIdHandlerService idHandler;
    late _MockErmesRepository mockRepository;

    setUp(() {
      idHandler = IdHandlerServiceFactory.createDefault();
      mockRepository = _MockErmesRepository();
      service = ErmesServiceFactory.createService(
        100, // maxBuffer
        1024, // maxByte
        mockRepository,
        idHandler,
        null, // callbackOnDataArrived
        null, // ermesStorageAndCaching
        null, // ermesMessageControlService
        null, // missingMessagesCheckIntervalMs
        null, // missingMessagesThreshold
      );
    });

    tearDown(() {
      service.close();
    });

    group('Single Callback Registration', () {
      test('addOnNewKeyListener registers single callback', () {
        var callbackCalled = false;
        service.addOnNewKeyListener((newKey) {
          callbackCalled = true;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key-material',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCalled, isTrue);
      });

      test('callback receives correct newKey data', () {
        ServiceMessageNewKey? receivedKey;
        service.addOnNewKeyListener((newKey) {
          receivedKey = newKey;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 42,
          algorithm: 'ECDH',
          key: 'secret-key-data',
          start: DateTime(2024, 1, 1),
          expiration: DateTime(2025, 1, 1),
          startMessage: 100,
          endMessage: 200,
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(receivedKey, isNotNull);
        expect(receivedKey!.id, equals(42));
        expect(receivedKey!.algorithm, equals('ECDH'));
        expect(receivedKey!.key, equals('secret-key-data'));
        expect(receivedKey!.start, equals(DateTime(2024, 1, 1)));
        expect(receivedKey!.expiration, equals(DateTime(2025, 1, 1)));
        expect(receivedKey!.startMessage, equals(100));
        expect(receivedKey!.endMessage, equals(200));
      });
    });

    group('Multiple Callback Registration', () {
      test('addOnNewKeyListener can register multiple callbacks', () {
        var firstCallbackCalled = false;
        var secondCallbackCalled = false;

        service.addOnNewKeyListener((_) {
          firstCallbackCalled = true;
        });

        service.addOnNewKeyListener((_) {
          secondCallbackCalled = true;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(firstCallbackCalled, isTrue);
        expect(secondCallbackCalled, isTrue);
      });

      test('multiple callbacks are all invoked with correct data', () {
        final receivedKeys = <ServiceMessageNewKey>[];

        service.addOnNewKeyListener((newKey) {
          receivedKeys.add(newKey);
        });

        service.addOnNewKeyListener((newKey) {
          receivedKeys.add(newKey);
        });

        service.addOnNewKeyListener((newKey) {
          receivedKeys.add(newKey);
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 10,
          algorithm: 'RSA',
          key: 'rsa-key-data',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(receivedKeys.length, equals(3));
        expect(receivedKeys[0].id, equals(10));
        expect(receivedKeys[1].id, equals(10));
        expect(receivedKeys[2].id, equals(10));
      });
    });

    group('Callback Removal', () {
      test('removeOnNewKeyListener removes registered callback', () {
        var callbackCalled = false;
        final callback = (_) {
          callbackCalled = true;
        };

        service.addOnNewKeyListener(callback);
        service.removeOnNewKeyListener(callback);

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCalled, isFalse);
      });

      test('removeOnNewKeyListener only removes specific callback', () {
        var firstCallbackCalled = false;
        var secondCallbackCalled = false;

        final firstCallback = (_) {
          firstCallbackCalled = true;
        };

        final secondCallback = (_) {
          secondCallbackCalled = true;
        };

        service.addOnNewKeyListener(firstCallback);
        service.addOnNewKeyListener(secondCallback);
        service.removeOnNewKeyListener(firstCallback);

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(firstCallbackCalled, isFalse);
        expect(secondCallbackCalled, isTrue);
      });
    });

    group('Clear All Callbacks', () {
      test('clearOnNewKeyListeners removes all callbacks', () {
        var callbackCount = 0;

        service.addOnNewKeyListener((_) {
          callbackCount++;
        });

        service.addOnNewKeyListener((_) {
          callbackCount++;
        });

        service.addOnNewKeyListener((_) {
          callbackCount++;
        });

        service.clearOnNewKeyListeners();

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCount, equals(0));
      });

      test('callbacks can be re-registered after clear', () {
        var callbackCalled = false;

        service.addOnNewKeyListener((_) {
          callbackCalled = true;
        });

        service.clearOnNewKeyListeners();
        callbackCalled = false;

        service.addOnNewKeyListener((_) {
          callbackCalled = true;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCalled, isTrue);
      });
    });

    group('Service Lifecycle', () {
      test('callbacks are cleared on service close', () {
        var callbackCalled = false;

        service.addOnNewKeyListener((_) {
          callbackCalled = true;
        });

        service.close();

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key',
        );

        // Try to simulate message after close (should not invoke callback)
        mockRepository.simulateNewKeyMessage(newKeyMessage);

        // Since the service is closed and callbacks are cleared,
        // new messages won't trigger the callback
        expect(callbackCalled, isFalse);
      });
    });

    group('Multiple Sequential Messages', () {
      test('callback is invoked for each new key message', () {
        final receivedMessages = <ServiceMessageNewKey>[];

        service.addOnNewKeyListener((newKey) {
          receivedMessages.add(newKey);
        });

        for (var i = 1; i <= 5; i++) {
          final newKeyMessage = ServiceMessageNewKey(
            id: i,
            algorithm: 'AES-256',
            key: 'key-$i',
          );

          mockRepository.simulateNewKeyMessage(newKeyMessage);
        }

        expect(receivedMessages.length, equals(5));
        for (var i = 0; i < 5; i++) {
          expect(receivedMessages[i].id, equals(i + 1));
          expect(receivedMessages[i].key, equals('key-${i + 1}'));
        }
      });
    });

    group('Edge Cases', () {
      test('callback with null key data', () {
        ServiceMessageNewKey? receivedKey;

        service.addOnNewKeyListener((newKey) {
          receivedKey = newKey;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: '',
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(receivedKey, isNotNull);
        expect(receivedKey!.key, isEmpty);
      });

      test('callback with all optional fields', () {
        ServiceMessageNewKey? receivedKey;

        service.addOnNewKeyListener((newKey) {
          receivedKey = newKey;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: 'AES-256',
          key: 'test-key',
          start: DateTime.now(),
          expiration: DateTime.now().add(Duration(days: 30)),
          startMessage: 0,
          endMessage: 1000000,
        );

        mockRepository.simulateNewKeyMessage(newKeyMessage);

        expect(receivedKey, isNotNull);
        expect(receivedKey!.start, isNotNull);
        expect(receivedKey!.expiration, isNotNull);
        expect(receivedKey!.startMessage, isNotNull);
        expect(receivedKey!.endMessage, isNotNull);
      });

      test(
        'removeOnNewKeyListener with non-registered callback does nothing',
        () {
          final callback1 = (_) {};
          final callback2 = (_) {};

          service.addOnNewKeyListener(callback1);
          expect(
            () => service.removeOnNewKeyListener(callback2),
            returnsNormally,
          );
        },
      );
    });
  });
}

/// Mock minimalista di IErmesRepository con supporto per messaggi NewKey
class _MockErmesRepository implements IErmesRepository {
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

  /// Simulate receiving a ServiceMessageNewKey message
  void simulateNewKeyMessage(ServiceMessageNewKey newKeyMessage) {
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

    simulateDataReceived(serializedMessage);
  }
}

void main() {
  testNewKeyCallbackSystem();
}
