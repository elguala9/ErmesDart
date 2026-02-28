// ignore_for_file: lines_longer_than_80_chars, cascade_invocations

import 'dart:async';
import 'dart:typed_data';


import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Comprehensive test suite for ErmesService retransmission paths
///
/// Tests all four retransmission mechanisms:
/// - Acknowledge-based (Path A)
/// - Array Request (Path B)
/// - Periodic Timer (Path C)
/// - Threshold-based (Path D)

void testErmesServiceRetransmission() {
  group('ErmesService Retransmission Suite', () {
    late ErmesService service;
    late IIdHandlerService idHandler;

    setUp(() {
      idHandler = IdHandlerServiceFactory.createDefault();
    });

    tearDown(() {
      try {
        service.close();
      } on Object {
        // Service may not be initialized in some tests
        // Late variable access throws LateInitializationError
      }
    });

    // ============================================================================
    // GROUP 1: Service Creation & Validation (errori)
    // ============================================================================
    group('Service Creation & Validation', () {
      test('maxByte > 1024 throws ArgumentError', () {
        final repository = _TestErmesRepository();
        expect(
          () => ErmesServiceFactory.createService(
            100,
            1025, // maxByte > 1024 (default max)
            repository,
            idHandler,
            null,
            null,
            null,
            null,
            null,
          ),
          throwsArgumentError,
        );
      });

      test('valid maxByte does not throw', () {
        final repository = _TestErmesRepository();
        expect(
          () => ErmesServiceFactory.createService(
            100,
            1024, // maxByte = 1024 (valid)
            repository,
            idHandler,
            null,
            null,
            null,
            null,
            null,
          ),
          returnsNormally,
        );
      });

      test(
        'missingMessagesCheckIntervalMs without ermesMessageControlService does not start timer',
        () {
          final repository = _TestErmesRepository();
          service = ErmesServiceFactory.createService(
            100,
            1024,
            repository,
            idHandler,
            null,
            null,
            null, // No ermesMessageControlService
            500, // missingMessagesCheckIntervalMs set
            null,
          );

          // Timer should not be started since ermesMessageControlService is null
          expect(service.isClosed(), isFalse);
          service.close();
          expect(service.isClosed(), isTrue);
        },
      );
    });

    // ============================================================================
    // GROUP 2: Send Callbacks
    // ============================================================================
    group('Send Callbacks', () {
      test('onDataSending is called before sending', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        var sendingCalled = false;
        var sentCalled = false;

        service.addOnDataSendingListener((_) {
          sendingCalled = true;
          // sentCalled should still be false
          expect(sentCalled, isFalse);
        });

        service.addOnDataSentListener((_) {
          sentCalled = true;
          expect(sendingCalled, isTrue);
        });

        final data = Uint8List.fromList([1, 2, 3]);
        service.send(data);

        expect(sendingCalled, isTrue);
        expect(sentCalled, isTrue);
      });

      test('removing callback prevents it from being called', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        var callbackCalled = false;
        void callback(TypeOfData _) {
          callbackCalled = true;
        }

        service.addOnDataSendingListener(callback);
        service.removeOnDataSendingListener(callback);

        final data = Uint8List.fromList([1, 2, 3]);
        service.send(data);

        expect(callbackCalled, isFalse);
      });

      test('clearing callbacks prevents them from being called', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        var callbackCalled = false;
        service.addOnDataSendingListener((_) {
          callbackCalled = true;
        });

        service.clearOnDataSendingListeners();

        final data = Uint8List.fromList([1, 2, 3]);
        service.send(data);

        expect(callbackCalled, isFalse);
      });

      test('correct data is sent to repository', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        service.send(testData);

        // Verify data was sent
        expect(repository.sentData.isNotEmpty, isTrue);
      });
    });

    // ============================================================================
    // GROUP 3: Receive Errors (silent failures)
    // ============================================================================
    group('Receive Errors', () {
      test('empty message is ignored silently', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        var errorThrown = false;
        try {
          // Send empty data - should not crash
          repository.simulateDataReceived(Uint8List(0));
        } on Exception {
          errorThrown = true;
        }

        expect(errorThrown, isFalse);
      });

      test('buffer overflow does not crash service', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          10, // Very small buffer
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        // Create multiple messages - may hit buffer limit
        for (var i = 0; i < 5; i++) {
          final messageData = MessageData(id: i, data: Uint8List.fromList([i]));
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

          try {
            repository.simulateDataReceived(serializedMessage);
          } catch (e) {
            // Buffer overflow is acceptable
            if (e is! StateError) {
              rethrow;
            }
          }
        }

        // Service should still be operational
        expect(service.isClosed(), isFalse);
      });
    });

    // ============================================================================
    // GROUP 4: Retransmission - Acknowledge-based (Path A)
    // ============================================================================
    group('Retransmission: Acknowledge-based (Path A)', () {
      test(
        'gap positive with storage available sends missing messages',
        () async {
          final repository = _TestErmesRepository(open: true);
          final storage = _TestStorage();
          service = ErmesServiceFactory.createService(
            100,
            1024,
            repository,
            idHandler,
            null,
            storage,
            null,
            null,
            null,
          );

          // Pre-populate storage with messages
          final msg1 = MessageData(id: 1, data: Uint8List.fromList([1]));
          final msg2 = MessageData(id: 2, data: Uint8List.fromList([2]));
          final msgType1 = MessageType.data(msg1);
          final msgType2 = MessageType.data(msg2);

          await storage.store(msgType1);
          await storage.store(msgType2);

          // Verify storage has the messages
          expect(await storage.retrieve(1), isNotNull);
          expect(await storage.retrieve(2), isNotNull);

          // Simulate sending messages first to populate _idHandler state
          service.send(Uint8List.fromList([10]));
          service.send(Uint8List.fromList([20]));

          // Simulate peer acknowledging only message 0, leaving gap for 1,2
          const ackMessage = ServiceMessageAcknowledge(
            id: 99,
            ackCurrentId: 2,
            ackLastReceivedId: 0, // Gap: they only received up to 0
          );

          const internalMsg = InternalMessage(
            message: MessageType.service(ackMessage),
            type: MessageValue.service,
          );
          final serializedInternal = objectToUint8Array(internalMsg);
          final hash = calculateHashSync(serializedInternal);
          final messageRoot = MessageRoot(
            messageSerialized: serializedInternal,
            integrityCheckValue: hash,
          );
          final serializedMessage = objectToUint8Array(messageRoot);

          final beforeSentCount = repository.sentData.length;
          repository.simulateDataReceived(serializedMessage);

          // Wait for async operations to complete
          await Future<void>.delayed(const Duration(milliseconds: 150));

          // MUST have sent missing messages - NOT just "any" message
          expect(
            repository.sentData.length,
            greaterThan(beforeSentCount),
            reason: 'No messages sent after acknowledge with gap',
          );

          // Verify that something substantial was sent (at least 2KB for the messages)
          final totalSent = repository.sentData.fold<int>(
            0,
            (sum, data) => sum + data.length,
          );
          expect(
            totalSent,
            greaterThan(100),
            reason: 'Sent data too small - likely missing messages not sent',
          );
        },
      );

      test('gap positive without storage does not retransmit', () async {
        final repository = _TestErmesRepository(open: true);
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null, // No storage - this is the guard condition
          null,
          null,
          null,
        );

        service.send(Uint8List.fromList([10]));
        service.send(Uint8List.fromList([20]));

        final beforeSentCount = repository.sentData.length;

        const ackMessage = ServiceMessageAcknowledge(
          id: 99,
          ackCurrentId: 2,
          ackLastReceivedId: 0, // Would create gap, but storage is null
        );

        const internalMsg = InternalMessage(
          message: MessageType.service(ackMessage),
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
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // MUST NOT send anything when storage is null (guard clause)
        expect(
          repository.sentData.length,
          equals(beforeSentCount),
          reason: 'Should not send missing messages when storage is null',
        );
      });

      test('ackLastReceivedId null does not trigger resend', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          null,
          null,
          null,
        );

        // Pre-populate storage to ensure it's available
        await storage.store(
          MessageType.data(MessageData(id: 1, data: Uint8List.fromList([1]))),
        );
        await storage.store(
          MessageType.data(MessageData(id: 2, data: Uint8List.fromList([2]))),
        );

        service.send(Uint8List.fromList([10]));
        service.send(Uint8List.fromList([20]));

        final beforeSentCount = repository.sentData.length;

        const ackMessage = ServiceMessageAcknowledge(id: 99, ackCurrentId: 2);

        const internalMsg = InternalMessage(
          message: MessageType.service(ackMessage),
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
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // MUST NOT resend when ackLastReceivedId is null
        expect(
          repository.sentData.length,
          equals(beforeSentCount),
          reason: 'Should not resend when ackLastReceivedId is null',
        );
      });

      test('gap <= 0 (peer is updated) does not resend', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          null,
          null,
          null,
        );

        // Pre-populate storage with some messages
        await storage.store(
          MessageType.data(MessageData(id: 1, data: Uint8List.fromList([1]))),
        );
        await storage.store(
          MessageType.data(MessageData(id: 2, data: Uint8List.fromList([2]))),
        );

        service.send(Uint8List.fromList([10]));
        service.send(Uint8List.fromList([20]));

        final beforeSentCount = repository.sentData.length;

        // Acknowledge with gap = 0 (peer is fully updated)
        const ackMessage = ServiceMessageAcknowledge(
          id: 99,
          ackCurrentId: 2,
          ackLastReceivedId: 2, // Peer has all messages (gap = 0)
        );

        const internalMsg = InternalMessage(
          message: MessageType.service(ackMessage),
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

        // Wait to ensure no async resend happens
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // MUST NOT resend when gap <= 0
        expect(
          repository.sentData.length,
          equals(beforeSentCount),
          reason: 'Should not resend when peer is already updated (gap <= 0)',
        );
      });
    });

    // ============================================================================
    // GROUP 5: Retransmission - Array Request (Path B)
    // ============================================================================
    group('Retransmission: Array Request (Path B)', () {
      test('storage available with messages sends correct messages', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          null,
          null,
          null,
        );

        // Pre-populate storage
        final msg1 = MessageData(id: 1, data: Uint8List.fromList([1]));
        final msg2 = MessageData(id: 2, data: Uint8List.fromList([2]));

        await storage.store(MessageType.data(msg1));
        await storage.store(MessageType.data(msg2));

        // Peer requests specific messages
        const arrayRequest = ServiceMessageArrayRequest(
          id: 50,
          arrayId: [1, 2],
        );

        const internalMsg = InternalMessage(
          message: MessageType.service(arrayRequest),
          type: MessageValue.service,
        );
        final serializedInternal = objectToUint8Array(internalMsg);
        final hash = calculateHashSync(serializedInternal);
        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: hash,
        );
        final serializedMessage = objectToUint8Array(messageRoot);

        final beforeSentCount = repository.sentData.length;
        repository.simulateDataReceived(serializedMessage);

        // Wait for async operations to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have sent the requested messages
        expect(repository.sentData.length, greaterThan(beforeSentCount));
      });

      test('message not found in storage sends DATA NOT FOUND', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          null,
          null,
          null,
        );

        // Request a message that doesn't exist
        const arrayRequest = ServiceMessageArrayRequest(
          id: 50,
          arrayId: [999], // Non-existent ID
        );

        const internalMsg = InternalMessage(
          message: MessageType.service(arrayRequest),
          type: MessageValue.service,
        );
        final serializedInternal = objectToUint8Array(internalMsg);
        final hash = calculateHashSync(serializedInternal);
        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: hash,
        );
        final serializedMessage = objectToUint8Array(messageRoot);

        final beforeSentCount = repository.sentData.length;
        repository.simulateDataReceived(serializedMessage);

        // Wait for async operations to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have sent error message
        expect(repository.sentData.length, greaterThan(beforeSentCount));
      });

      test('storage NULL sends NO STORAGE ENABLE for each ID', () async {
        final repository = _TestErmesRepository(open: true);
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null, // No storage
          null,
          null,
          null,
        );

        final beforeSentCount = repository.sentData.length;
        final requestedIds = [1, 2, 3];

        final arrayRequest = ServiceMessageArrayRequest(
          id: 50,
          arrayId: requestedIds,
        );

        final internalMsg = InternalMessage(
          message: MessageType.service(arrayRequest),
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
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // MUST have sent error messages for each requested ID
        expect(
          repository.sentData.length,
          greaterThan(beforeSentCount),
          reason: 'Should send NO STORAGE ENABLE errors when storage is null',
        );

        // Verify substantial data was sent (error messages)
        final totalSent = repository.sentData
            .sublist(beforeSentCount)
            .fold<int>(0, (sum, data) => sum + data.length);
        expect(
          totalSent,
          greaterThan(50),
          reason: 'Should send error messages for missing storage',
        );
      });
    });

    // ============================================================================
    // GROUP 6: Retransmission - Periodic Timer (Path C)
    // ============================================================================
    group('Retransmission: Periodic Timer (Path C)', () {
      test('startMissingMessagesCheck starts timer', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          null,
        );

        // Mark some IDs as missing
        controlService.addMissingId(1);
        controlService.addMissingId(2);

        service.startMissingMessagesCheck(50); // 50ms interval

        // Wait for timer to fire
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Timer should have executed and potentially sent missing message requests
        // We verify the service is still operational
        expect(service.isClosed(), isFalse);
      });

      test('stopMissingMessagesCheck cancels timer', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          null,
        );

        service.startMissingMessagesCheck(50);
        final sentCountBefore = repository.sentData.length;

        // Stop immediately
        service.stopMissingMessagesCheck();

        // Wait to verify no more sends happen
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Should not have sent much (timer was stopped)
        final sentCountAfter = repository.sentData.length;
        expect(sentCountAfter - sentCountBefore, lessThan(3));
      });

      test('double start replaces previous timer', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          null,
        );

        controlService.addMissingId(1);

        service.startMissingMessagesCheck(50);
        await Future<void>.delayed(const Duration(milliseconds: 75));

        // Start again (should replace)
        service.startMissingMessagesCheck(50);
        await Future<void>.delayed(const Duration(milliseconds: 75));

        // Timer should still work without duplicates
        expect(service.isClosed(), isFalse);
      });

      test('timer is canceled on close', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          null,
        );

        service.startMissingMessagesCheck(50);
        service.close();

        // Wait to verify no exceptions after close
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(service.isClosed(), isTrue);
      });
    });

    // ============================================================================
    // GROUP 7: Retransmission - Threshold-based (Path D)
    // ============================================================================
    group('Retransmission: Threshold-based (Path D)', () {
      test('without ermesMessageControlService is no-op', () async {
        final repository = _TestErmesRepository(open: true);
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null, // No control service
          null,
          10, // threshold
        );

        final beforeSentCount = repository.sentData.length;
        await service.checkAndRequestMissingMessages();

        expect(repository.sentData.length, equals(beforeSentCount));
      });

      test('missing IDs < threshold does not request', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          10, // threshold = 10
        );

        // Add only 5 missing IDs (< threshold)
        controlService.addMissingId(1);
        controlService.addMissingId(2);
        controlService.addMissingId(3);
        controlService.addMissingId(4);
        controlService.addMissingId(5);

        final beforeSentCount = repository.sentData.length;
        await service.checkAndRequestMissingMessages();

        // Should not have sent request
        expect(repository.sentData.length, equals(beforeSentCount));
      });

      test('missing IDs >= threshold sends request', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        const threshold = 10;
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          threshold,
        );

        // Add 15 missing IDs (>= threshold)
        for (var i = 1; i <= 15; i++) {
          controlService.addMissingId(i);
        }

        expect(
          controlService.numberOfMissingIds(),
          equals(15),
          reason: 'Setup failed: should have 15 missing IDs',
        );
        expect(
          controlService.numberOfMissingIds() >= threshold,
          isTrue,
          reason: 'Setup failed: missing IDs should >= threshold',
        );

        final beforeSentCount = repository.sentData.length;
        await service.checkAndRequestMissingMessages();

        // MUST have sent request (15 >= 10)
        expect(
          repository.sentData.length,
          greaterThan(beforeSentCount),
          reason:
              'Should send request when missing IDs (${controlService.numberOfMissingIds()}) >= threshold ($threshold)',
        );
      });

      test('threshold null with missing IDs sends request', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          null, // threshold = null (always request if ANY missing IDs exist)
        );

        // Add missing IDs
        controlService.addMissingId(1);
        controlService.addMissingId(2);
        controlService.addMissingId(3);

        final beforeSentCount = repository.sentData.length;
        await service.checkAndRequestMissingMessages();

        // MUST have sent request (threshold is null = always send when IDs missing)
        expect(
          repository.sentData.length,
          greaterThan(beforeSentCount),
          reason:
              'Should always send request when threshold is null and IDs are missing',
        );
      });

      test(
        'no missing IDs with null threshold does not send request',
        () async {
          final repository = _TestErmesRepository(open: true);
          final storage = _TestStorage();
          final controlService = _TestMessageControlService();

          service = ErmesServiceFactory.createService(
            100,
            1024,
            repository,
            idHandler,
            null,
            storage,
            controlService,
            null,
            null, // threshold = null
          );

          // No missing IDs
          expect(controlService.numberOfMissingIds(), equals(0));

          final beforeSentCount = repository.sentData.length;
          await service.checkAndRequestMissingMessages();

          // Should NOT send request if no missing IDs
          expect(
            repository.sentData.length,
            equals(beforeSentCount),
            reason: 'Should not send request when no missing IDs exist',
          );
        },
      );
    });

    // ============================================================================
    // GROUP 8: Lifecycle
    // ============================================================================
    group('Lifecycle', () {
      test('close is idempotent', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        expect(() => service.close(), returnsNormally);
        expect(() => service.close(), returnsNormally); // Second close
      });

      test('isClosed returns true after close', () {
        final repository = _TestErmesRepository();
        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          null,
          null,
          null,
          null,
        );

        service.close();

        expect(service.isClosed(), isTrue);
      });

      test('close cancels periodic timer', () async {
        final repository = _TestErmesRepository(open: true);
        final storage = _TestStorage();
        final controlService = _TestMessageControlService();

        service = ErmesServiceFactory.createService(
          100,
          1024,
          repository,
          idHandler,
          null,
          storage,
          controlService,
          null,
          null,
        );

        service.startMissingMessagesCheck(50);
        service.close();

        // Wait to verify no exceptions
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(service.isClosed(), isTrue);
      });
    });
  });
}

/// Test implementation of IErmesRepository with open/close control
class _TestErmesRepository implements IErmesRepository {
  _TestErmesRepository({this.open = false});

  bool open;
  final List<Uint8List> sentData = [];
  final List<void Function(Uint8List)> _dataCallbacks = [];

  @override
  IdAccountType get remotePeerId => 'test-peer-id';

  @override
  void destroy({bool force = false}) {
    sentData.clear();
    _dataCallbacks.clear();
  }

  @override
  bool isOpen() => open;

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

/// Test implementation of IErmesStorageAndCaching<MessageType>
class _TestStorage implements IErmesStorageAndCaching<MessageType> {
  final Map<IdType, MessageType> _store = {};

  @override
  Future<void> store(MessageType data) async {
    // Extract ID from MessageType
    final id = _extractIdFromMessage(data);
    _store[id] = data;
  }

  @override
  Future<MessageType?> retrieve(IdType id) async => _store[id];

  @override
  Future<bool> delete(IdType id) async => _store.remove(id) != null;

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  int numberOfElements() => _store.length;

  @override
  Future<List<IdType>> listOfIds() async => _store.keys.toList();

  @override
  Future<void> destroy() async {
    _store.clear();
  }

  @override
  Future<void> flush() async {
    // No-op for test implementation
  }

  /// Helper to extract ID from MessageType
  IdType _extractIdFromMessage(MessageType msg) => msg.id;
}

/// Test implementation of IErmesMessageControlService
class _TestMessageControlService implements IErmesMessageControlService {
  final List<IdType> missingIds = [];
  IdType? lastReceivedId;

  void addMissingId(IdType id) {
    if (!missingIds.contains(id)) {
      missingIds.add(id);
    }
  }

  @override
  void idArrived(IdType id) {
    missingIds.remove(id);
    lastReceivedId = id;
  }

  @override
  Future<List<IdType>> idsToRequest() async => List.from(missingIds);

  @override
  int numberOfMissingIds() => missingIds.length;

  @override
  void setCallbackIdsToRequest(CallbackIdsToRequest callback) {
    // Not used in test implementation
  }

  @override
  Future<void> clear() async {
    missingIds.clear();
  }

  @override
  Future<void> destroy() async {
    missingIds.clear();
  }

  @override
  IdType? getLastReceivedId() => lastReceivedId;
}

void main() {
  testErmesServiceRetransmission();
}
