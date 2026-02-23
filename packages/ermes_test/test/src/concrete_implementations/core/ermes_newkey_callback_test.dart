import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/cryptdart.dart';
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
    late _TestErmesRepository testRepository;

    setUp(() {
      idHandler = IdHandlerServiceFactory.createDefault();
      testRepository = _TestErmesRepository();
      service = ErmesServiceFactory.createService(
        100, // maxBuffer
        1024, // maxByte
        testRepository,
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
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key-material',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCalled, isTrue);
      });

      test('callback receives correct newKey data', () {
        ServiceMessageNewKey? receivedKey;
        service.addOnNewKeyListener((newKey) {
          receivedKey = newKey;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 42,
          algorithm: SymmetricAlgorithm.aes,
          key: 'secret-key-data',
          start: DateTime(2024),
          expiration: DateTime(2025),
          startMessage: 100,
          endMessage: 200,
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(receivedKey, isNotNull);
        expect(receivedKey!.id, equals(42));
        expect(receivedKey!.algorithm, equals(SymmetricAlgorithm.aes));
        expect(receivedKey!.key, equals('secret-key-data'));
        expect(receivedKey!.start, equals(DateTime(2024)));
        expect(receivedKey!.expiration, equals(DateTime(2025)));
        expect(receivedKey!.startMessage, equals(100));
        expect(receivedKey!.endMessage, equals(200));
      });
    });

    group('Multiple Callback Registration', () {
      test('addOnNewKeyListener can register multiple callbacks', () {
        var firstCallbackCalled = false;
        var secondCallbackCalled = false;

        service
          ..addOnNewKeyListener((_) {
            firstCallbackCalled = true;
          })
          ..addOnNewKeyListener((_) {
            secondCallbackCalled = true;
          });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(firstCallbackCalled, isTrue);
        expect(secondCallbackCalled, isTrue);
      });

      test('multiple callbacks are all invoked with correct data', () {
        final receivedKeys = <ServiceMessageNewKey>[];

        service
          ..addOnNewKeyListener(receivedKeys.add)
          ..addOnNewKeyListener(receivedKeys.add)
          ..addOnNewKeyListener(receivedKeys.add);

        final newKeyMessage = ServiceMessageNewKey(
          id: 10,
          algorithm: SymmetricAlgorithm.aes,
          key: 'rsa-key-data',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(receivedKeys.length, equals(3));
        expect(receivedKeys[0].id, equals(10));
        expect(receivedKeys[1].id, equals(10));
        expect(receivedKeys[2].id, equals(10));
      });
    });

    group('Callback Removal', () {
      test('removeOnNewKeyListener removes registered callback', () {
        var callbackCalled = false;
        void callback(_) {
          callbackCalled = true;
        }

        service
          ..addOnNewKeyListener(callback)
          ..removeOnNewKeyListener(callback);

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCalled, isFalse);
      });

      test('removeOnNewKeyListener only removes specific callback', () {
        var firstCallbackCalled = false;
        var secondCallbackCalled = false;

        void firstCallback(_) {
          firstCallbackCalled = true;
        }

        void secondCallback(_) {
          secondCallbackCalled = true;
        }

        service
          ..addOnNewKeyListener(firstCallback)
          ..addOnNewKeyListener(secondCallback)
          ..removeOnNewKeyListener(firstCallback);

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(firstCallbackCalled, isFalse);
        expect(secondCallbackCalled, isTrue);
      });
    });

    group('Clear All Callbacks', () {
      test('clearOnNewKeyListeners removes all callbacks', () {
        var callbackCount = 0;

        service
          ..addOnNewKeyListener((_) {
            callbackCount++;
          })
          ..addOnNewKeyListener((_) {
            callbackCount++;
          })
          ..addOnNewKeyListener((_) {
            callbackCount++;
          })
          ..clearOnNewKeyListeners();

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCount, equals(0));
      });

      test('callbacks can be re-registered after clear', () {
        var callbackCalled = false;

        service
          ..addOnNewKeyListener((_) {
            callbackCalled = true;
          })
          ..clearOnNewKeyListeners();
        callbackCalled = false;

        service.addOnNewKeyListener((_) {
          callbackCalled = true;
        });

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(callbackCalled, isTrue);
      });
    });

    group('Service Lifecycle', () {
      test('callbacks are cleared on service close', () {
        var callbackCalled = false;

        service
          ..addOnNewKeyListener((_) {
            callbackCalled = true;
          })
          ..close();

        final newKeyMessage = ServiceMessageNewKey(
          id: 1,
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key',
        );

        // Try to simulate message after close (should not invoke callback)
        testRepository.simulateNewKeyMessage(newKeyMessage);

        // Since the service is closed and callbacks are cleared,
        // new messages won't trigger the callback
        expect(callbackCalled, isFalse);
      });
    });

    group('Multiple Sequential Messages', () {
      test('callback is invoked for each new key message', () {
        final receivedMessages = <ServiceMessageNewKey>[];

        service.addOnNewKeyListener(receivedMessages.add);

        for (var i = 1; i <= 5; i++) {
          final newKeyMessage = ServiceMessageNewKey(
            id: i,
            algorithm: SymmetricAlgorithm.aes,
            key: 'key-$i',
          );

          testRepository.simulateNewKeyMessage(newKeyMessage);
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
          algorithm: SymmetricAlgorithm.aes,
          key: '',
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

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
          algorithm: SymmetricAlgorithm.aes,
          key: 'test-key',
          start: DateTime.now(),
          expiration: DateTime.now().add(const Duration(days: 30)),
          startMessage: 0,
          endMessage: 1000000,
        );

        testRepository.simulateNewKeyMessage(newKeyMessage);

        expect(receivedKey, isNotNull);
        expect(receivedKey!.start, isNotNull);
        expect(receivedKey!.expiration, isNotNull);
        expect(receivedKey!.startMessage, isNotNull);
        expect(receivedKey!.endMessage, isNotNull);
      });

      test(
        'removeOnNewKeyListener with non-registered callback does nothing',
        () {
          void callback1(_) {}
          void callback2(_) {}

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

/// Test implementation of IErmesRepository with support for NewKey messages
class _TestErmesRepository implements IErmesRepository {
  final List<Uint8List> sentData = [];
  final List<void Function(Uint8List)> _dataCallbacks = [];
  final bool _isConnected = false;

  @override
  IdAccountType get remotePeerId => 'test-peer-id';

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
    final hash = calculateHashSync(serializedInternal);
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
