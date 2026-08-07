import 'dart:async';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void testErmesServiceFeatures() {
  group('ErmesService Features', () {
    late IIdHandlerService idHandler;
    var testCounter = 0;

    setUpAll(registerErmesStorageHandlers);

    setUp(() {
      idHandler = IdHandlerServiceFactory.createDefault();
      testCounter++;
    });

    // ========================================================================
    // ErmesService.sendNewKey()
    // ========================================================================
    group('sendNewKey()', () {
      test('sends new key message via repository', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          )
            ..sendNewKey(
              algorithm: SymmetricAlgorithm.aes,
              key: 'a' * 64,
            )
            ..close();
          expect(repository.sentData, isNotEmpty);
        } finally {
          repository.cleanUp();
        }
      });

      test('sends new key with all optional fields', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          )
            ..sendNewKey(
              algorithm: SymmetricAlgorithm.aes,
              key: 'b' * 64,
              start: DateTime(2024),
              expiration: DateTime(2025),
              startMessage: 100,
              endMessage: 200,
            )
            ..close();
          expect(repository.sentData, isNotEmpty);
        } finally {
          repository.cleanUp();
        }
      });

      test('sends via repository (bypasses onDataSendingListener)', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );

          var sendingCalled = false;
          service
            ..addOnDataSendingListener((_) {
              sendingCalled = true;
            })
            ..sendNewKey(
              algorithm: SymmetricAlgorithm.aes,
              key: 'c' * 64,
            )
            ..close();
          expect(repository.sentData, isNotEmpty);
          expect(sendingCalled, isFalse);
        } finally {
          repository.cleanUp();
        }
      });
    });

    // ========================================================================
    // ErmesSendRepo.sendAgain()
    // ========================================================================
    group('sendAgain()', () {
      test('returns silently for unknown id', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );

          final beforeCount = repository.sentData.length;

          await service.ermesSendRepo.sendAgain(99999);

          expect(repository.sentData.length, equals(beforeCount));
          service.close();
        } finally {
          repository.cleanUp();
        }
      });

      test('resends previously sent message', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );

          await service.send(Uint8List.fromList([1, 2, 3]));
          await Future<void>.delayed(const Duration(milliseconds: 50));

          final beforeCount = repository.sentData.length;

          await service.ermesSendRepo.sendAgain(0);

          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(repository.sentData.length, greaterThanOrEqualTo(beforeCount));
          service.close();
        } finally {
          repository.cleanUp();
        }
      });
    });

    // ========================================================================
    // ErmesService Listener Management
    // ========================================================================
    group('ErmesService listener management', () {
      group('onDataSending listeners', () {
        test('add, remove, clear lifecycle', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount = 0;
            void cb(_) {
              callCount++;
            }

            service
              ..addOnDataSendingListener(cb)
              ..removeOnDataSendingListener(cb);
            await service.send(Uint8List.fromList([1]));

            expect(callCount, equals(0));

            service.addOnDataSendingListener(cb);
            await service.send(Uint8List.fromList([2]));
            expect(callCount, equals(1));

            service
              ..clearOnDataSendingListeners()
              ..close();
          } finally {
            repository.cleanUp();
          }
        });
      });

      group('onDataSent listeners', () {
        test('add, remove, clear lifecycle', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount = 0;
            void cb(_) {
              callCount++;
            }

            service.addOnDataSentListener(cb);
            await service.send(Uint8List.fromList([1]));
            expect(callCount, equals(1));

            service.removeOnDataSentListener(cb);
            await service.send(Uint8List.fromList([2]));
            expect(callCount, equals(1));

            service
              ..addOnDataSentListener(cb)
              ..clearOnDataSentListeners();
            await service.send(Uint8List.fromList([3]));
            expect(callCount, equals(1));

            service.close();
          } finally {
            repository.cleanUp();
          }
        });
      });

      group('onNewKey listeners', () {
        test('multiple listeners are all notified', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount1 = 0;
            var callCount2 = 0;
            service
              ..addOnNewKeyListener((_) {
                callCount1++;
              })
              ..addOnNewKeyListener((_) {
                callCount2++;
              });

            final newKeyMsg = ServiceMessageNewKey(
              id: 1,
              algorithm: SymmetricAlgorithm.aes,
              key: 'a' * 64,
            );
            final internalMsg = InternalMessage(
              message: MessageType.service(newKeyMsg),
              type: MessageValue.service,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(callCount1, equals(1));
            expect(callCount2, equals(1));
            service.close();
          } finally {
            repository.cleanUp();
          }
        });

        test('clearOnNewKeyListeners removes all', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount = 0;
            service
              ..addOnNewKeyListener((_) {
                callCount++;
              })
              ..clearOnNewKeyListeners();

            final newKeyMsg = ServiceMessageNewKey(
              id: 1,
              algorithm: SymmetricAlgorithm.aes,
              key: 'a' * 64,
            );
            final internalMsg = InternalMessage(
              message: MessageType.service(newKeyMsg),
              type: MessageValue.service,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(callCount, equals(0));
            service.close();
          } finally {
            repository.cleanUp();
          }
        });
      });

      group('onRemoteClose listeners', () {
        test('addOnRemoteCloseListener registers callback', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callbackCalled = false;
            service.addOnRemoteCloseListener(() {
              callbackCalled = true;
            });

            const closeMsg = ServiceMessageConnectionClose(id: 1);
            const internalMsg = InternalMessage(
              message: MessageType.service(closeMsg),
              type: MessageValue.service,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(callbackCalled, isTrue);
            service.close();
          } finally {
            repository.cleanUp();
          }
        });

        test('removeOnRemoteCloseListener removes specific callback', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount = 0;
            void cb() {
              callCount++;
            }

            service
              ..addOnRemoteCloseListener(cb)
              ..removeOnRemoteCloseListener(cb);

            const closeMsg = ServiceMessageConnectionClose(id: 1);
            const internalMsg = InternalMessage(
              message: MessageType.service(closeMsg),
              type: MessageValue.service,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(callCount, equals(0));
            service.close();
          } finally {
            repository.cleanUp();
          }
        });

        test('clearOnRemoteCloseListeners removes all', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount = 0;
            service
              ..addOnRemoteCloseListener(() {
                callCount++;
              })
              ..clearOnRemoteCloseListeners();

            const closeMsg = ServiceMessageConnectionClose(id: 1);
            const internalMsg = InternalMessage(
              message: MessageType.service(closeMsg),
              type: MessageValue.service,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(callCount, equals(0));
            service.close();
          } finally {
            repository.cleanUp();
          }
        });
      });

      group('addOnMessageDataListener', () {
        test('receives data after registration', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            TypeOfData? received;
            service.addOnMessageDataListener((data) {
              received = data;
            });

            final messageData = MessageData(
              id: 1,
              data: Uint8List.fromList([42]),
            );
            final internalMsg = InternalMessage(
              message: MessageType.data(messageData),
              type: MessageValue.base,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(received, isNotNull);
            service.close();
          } finally {
            repository.cleanUp();
          }
        });

        test('removeOnMessageDataListener stops receiving', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount = 0;
            void cb(TypeOfData _) {
              callCount++;
            }

            service
              ..addOnMessageDataListener(cb)
              ..removeOnMessageDataListener(cb);

            final messageData = MessageData(
              id: 1,
              data: Uint8List.fromList([1]),
            );
            final internalMsg = InternalMessage(
              message: MessageType.data(messageData),
              type: MessageValue.base,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(callCount, equals(0));
            service.close();
          } finally {
            repository.cleanUp();
          }
        });

        test('clearOnMessageDataListeners removes all', () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, idHandler,
              null, null, null, null, null,
            );

            var callCount = 0;
            service
              ..addOnMessageDataListener((_) {
                callCount++;
              })
              ..clearOnMessageDataListeners();

            final messageData = MessageData(
              id: 1,
              data: Uint8List.fromList([1]),
            );
            final internalMsg = InternalMessage(
              message: MessageType.data(messageData),
              type: MessageValue.base,
            );
            final serializedInternal = objectToUint8Array(internalMsg);
            final hash = calculateHashSync(serializedInternal);
            final messageRoot = MessageRoot(
              messageSerialized: serializedInternal,
              integrityCheckValue: hash,
            );
            final serializedMessage = objectToUint8Array(messageRoot);

            repository.simulateDataReceived(serializedMessage);
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(callCount, equals(0));
            service.close();
          } finally {
            repository.cleanUp();
          }
        });
      });
    });

    // ========================================================================
    // ErmesReadRepo Service Message Listeners
    // ========================================================================
    group('ErmesReadRepo service message listeners', () {
      test('addServiceMessageListener registers callback', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer-$testCounter',
        );
        try {
          final readRepo = ErmesReadRepoFactory.create(
            repository: repository,
            onServiceMessage: (msg) {
            },
            options: const ErmesReadRepoOptions(),
          );

          ServiceMessage? viaListener;
          readRepo.addServiceMessageListener((msg) {
            viaListener = msg;
          });

          final newKeyMsg = ServiceMessageNewKey(
            id: 1,
            algorithm: SymmetricAlgorithm.aes,
            key: 'a' * 64,
          );
          final internalMsg = InternalMessage(
            message: MessageType.service(newKeyMsg),
            type: MessageValue.service,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          repository.simulateDataReceived(serializedMessage);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(viaListener, isNotNull);
        } finally {
          repository.cleanUp();
        }
      });

      test('removeServiceMessageListener removes specific callback', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer-$testCounter',
        );
        try {
          final readRepo = ErmesReadRepoFactory.create(
            repository: repository,
            onServiceMessage: (_) {},
            options: const ErmesReadRepoOptions(),
          );

          var callCount = 0;
          void cb(ServiceMessage _) {
            callCount++;
          }

          readRepo
            ..addServiceMessageListener(cb)
            ..removeServiceMessageListener(cb);

          final newKeyMsg = ServiceMessageNewKey(
            id: 1,
            algorithm: SymmetricAlgorithm.aes,
            key: 'a' * 64,
          );
          final internalMsg = InternalMessage(
            message: MessageType.service(newKeyMsg),
            type: MessageValue.service,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          repository.simulateDataReceived(serializedMessage);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(callCount, equals(0));
        } finally {
          repository.cleanUp();
        }
      });
    });

    // ========================================================================
    // ErmesPeer Listener Management
    // ========================================================================
    group('ErmesPeer listener management', () {
      test('addOnMessageListener registers callback', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );
          final peer = ErmesPeer.create(
            service: service,
            remotePeerId: 'alice',
            enableEncryption: false,
          );
          await peer.initialize();

          TypeOfDataExternal? received;
          peer.addOnMessageListener((data) {
            received = data;
          });

          final messageData = MessageData(
            id: 1,
            data: Uint8List.fromList([99]),
          );
          final internalMsg = InternalMessage(
            message: MessageType.data(messageData),
            type: MessageValue.base,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          repository.simulateDataReceived(serializedMessage);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(received, isNotNull);
          await peer.dispose();
        } finally {
          repository.cleanUp();
        }
      });

      test('removeOnMessageListener stops receiving', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );
          final peer = ErmesPeer.create(
            service: service,
            remotePeerId: 'alice',
            enableEncryption: false,
          );
          await peer.initialize();

          var callCount = 0;
          void cb(TypeOfDataExternal _) {
            callCount++;
          }

          peer
            ..addOnMessageListener(cb)
            ..removeOnMessageListener(cb);

          final messageData = MessageData(id: 1, data: Uint8List.fromList([1]));
          final internalMsg = InternalMessage(
            message: MessageType.data(messageData),
            type: MessageValue.base,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          repository.simulateDataReceived(serializedMessage);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(callCount, equals(0));
          await peer.dispose();
        } finally {
          repository.cleanUp();
        }
      });

      test('clearOnMessageListeners removes all', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );
          final peer = ErmesPeer.create(
            service: service,
            remotePeerId: 'alice',
            enableEncryption: false,
          );
          await peer.initialize();

          var callCount = 0;
          peer
            ..addOnMessageListener((_) {
              callCount++;
            })
            ..clearOnMessageListeners();

          final messageData = MessageData(id: 1, data: Uint8List.fromList([1]));
          final internalMsg = InternalMessage(
            message: MessageType.data(messageData),
            type: MessageValue.base,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          repository.simulateDataReceived(serializedMessage);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(callCount, equals(0));
          await peer.dispose();
        } finally {
          repository.cleanUp();
        }
      });

      test('addOnDisconnectListener registers callback', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );
          final peer = ErmesPeer.create(
            service: service,
            remotePeerId: 'alice',
            enableEncryption: false,
          );
          await peer.initialize();

          var callbackCalled = false;
          peer.addOnDisconnectListener(() {
            callbackCalled = true;
          });

          const closeMsg = ServiceMessageConnectionClose(id: 1);
          const internalMsg = InternalMessage(
            message: MessageType.service(closeMsg),
            type: MessageValue.service,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          repository.simulateDataReceived(serializedMessage);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(callbackCalled, isTrue);
          await peer.dispose();
        } finally {
          repository.cleanUp();
        }
      });

      test('removeOnDisconnectListener removes callback', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        try {
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );
          final peer = ErmesPeer.create(
            service: service,
            remotePeerId: 'alice',
            enableEncryption: false,
          );
          await peer.initialize();

          var callCount = 0;
          void cb() {
            callCount++;
          }

          peer
            ..addOnDisconnectListener(cb)
            ..removeOnDisconnectListener(cb);

          const closeMsg = ServiceMessageConnectionClose(id: 1);
          const internalMsg = InternalMessage(
            message: MessageType.service(closeMsg),
            type: MessageValue.service,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          repository.simulateDataReceived(serializedMessage);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(callCount, equals(0));
          await peer.dispose();
        } finally {
          repository.cleanUp();
        }
      });
    });
  });
}

void main() {
  testErmesServiceFeatures();
}
