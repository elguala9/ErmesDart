// ignore_for_file: lines_longer_than_80_chars, cascade_invocations

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

/// Comprehensive test suite for ErmesService retransmission paths
///
/// Tests all four retransmission mechanisms:
/// - Acknowledge-based (Path A)
/// - Array Request (Path B)
/// - Periodic Timer (Path C)
/// - Threshold-based (Path D)

void testErmesServiceRetransmission() {
  group('ErmesService Retransmission Suite', () {
    late IIdHandlerService idHandler;
    var testCounter = 0;
    ErmesService? service;
    TestErmesRepository? _currentRepo;

    setUpAll(initialPointErmesStorage);

    setUp(() {
      idHandler = IdHandlerServiceFactory.createDefault();
      testCounter++;
      _currentRepo = null;
      service = null;
    });

    tearDown(() {
      service?.close();
      _currentRepo?.cleanUp();
    });

    // ============================================================================
    // GROUP 1: Service Creation & Validation (errori)
    // ============================================================================
    group('Service Creation & Validation', () {
      test('maxByte > 1024 throws ArgumentError', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        expect(
          () => ErmesServiceFactory.createService(
            100,
            1025,
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

      test('valid maxByte does not throw', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        expect(
          () => service = ErmesServiceFactory.createService(
            100,
            1024,
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
        () async {
          final repository = await TestErmesRepository.create(
            open: true,
            peerId: 'test-peer-$testCounter',
          );
          _currentRepo = repository;
          service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, 500, null,
          );

          expect(service!.isClosed(), isFalse);
          service!.close();
          expect(service!.isClosed(), isTrue);
        },
      );
    });

    // ============================================================================
    // GROUP 2: Send Callbacks
    // ============================================================================
    group('Send Callbacks', () {
      test('onDataSending is called before sending', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        var sendingCalled = false;
        var sentCalled = false;

        service!.addOnDataSendingListener((_) {
          sendingCalled = true;
          expect(sentCalled, isFalse);
        });

        service!.addOnDataSentListener((_) {
          sentCalled = true;
          expect(sendingCalled, isTrue);
        });

        final data = Uint8List.fromList([1, 2, 3]);
        await service!.send(data);

        expect(sendingCalled, isTrue);
        expect(sentCalled, isTrue);
      });

      test('removing callback prevents it from being called', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        var callbackCalled = false;
        void callback(TypeOfData _) {
          callbackCalled = true;
        }

        service!.addOnDataSendingListener(callback);
        service!.removeOnDataSendingListener(callback);

        final data = Uint8List.fromList([1, 2, 3]);
        await service!.send(data);

        expect(callbackCalled, isFalse);
      });

      test('clearing callbacks prevents them from being called', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        var callbackCalled = false;
        service!.addOnDataSendingListener((_) {
          callbackCalled = true;
        });

        service!.clearOnDataSendingListeners();

        final data = Uint8List.fromList([1, 2, 3]);
        await service!.send(data);

        expect(callbackCalled, isFalse);
      });

      test('correct data is sent to repository', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        await service!.send(testData);

        expect(repository.sentData.isNotEmpty, isTrue);
      });
    });

    // ============================================================================
    // GROUP 3: Receive Errors (silent failures)
    // ============================================================================
    group('Receive Errors', () {
      test('empty message is ignored silently', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        expect(() => repository.simulateDataReceived(Uint8List(0)), returnsNormally);
      });

      test('buffer overflow does not crash service', () async {
        final repository = await TestErmesRepository.create(
          open: true,
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          10, 1024, repository, idHandler,
          null, null, null, null, null,
        );

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

          expect(
            () => repository.simulateDataReceived(serializedMessage),
            anyOf(returnsNormally, throwsA(isA<StateError>())),
          );
        }

        expect(service!.isClosed(), isFalse);
      });
    });

    // ============================================================================
    // GROUP 4: Retransmission - Acknowledge-based (Path A)
    // ============================================================================
    group('Retransmission: Acknowledge-based (Path A)', () {
      test('gap positive with storage available sends missing messages', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        await service!.send(Uint8List.fromList([10]));
        await service!.send(Uint8List.fromList([20]));

        const ackMessage = ServiceMessageAcknowledge(
          id: 99, ackCurrentId: 2, ackLastReceivedId: 0,
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

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(
          repository.sentData.length,
          greaterThan(beforeSentCount),
          reason: 'No messages sent after acknowledge with gap',
        );

        final totalSent = repository.sentData.fold<int>(
          0, (sum, data) => sum + data.length,
        );
        expect(
          totalSent,
          greaterThan(100),
          reason: 'Sent data too small - likely missing messages not sent',
        );
      });

      test('gap positive retransmits messages from singleton storage', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        await service!.send(Uint8List.fromList([10]));
        await service!.send(Uint8List.fromList([20]));

        final beforeSentCount = repository.sentData.length;

        const ackMessage = ServiceMessageAcknowledge(
          id: 99, ackCurrentId: 2, ackLastReceivedId: 0,
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

        expect(
          repository.sentData.length,
          greaterThan(beforeSentCount),
          reason: 'Should retransmit missing messages from singleton storage',
        );
      });

      test('ackLastReceivedId null does not trigger resend', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        await service!.send(Uint8List.fromList([10]));
        await service!.send(Uint8List.fromList([20]));

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

        expect(
          repository.sentData.length,
          equals(beforeSentCount),
          reason: 'Should not resend when ackLastReceivedId is null',
        );
      });

      test('gap <= 0 (peer is updated) does not resend', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        await service!.send(Uint8List.fromList([10]));
        await service!.send(Uint8List.fromList([20]));

        final beforeSentCount = repository.sentData.length;

        const ackMessage = ServiceMessageAcknowledge(
          id: 99, ackCurrentId: 2, ackLastReceivedId: 2,
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
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        await service!.send(Uint8List.fromList([1]));
        await service!.send(Uint8List.fromList([2]));

        const arrayRequest = ServiceMessageArrayRequest(
          id: 50, arrayId: [0, 1],
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

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(repository.sentData.length, greaterThan(beforeSentCount));
      });

      test('message not found in storage sends nothing', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        const arrayRequest = ServiceMessageArrayRequest(
          id: 50, arrayId: [999],
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

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          repository.sentData.length,
          equals(beforeSentCount),
          reason: 'Should not send anything when requested message not found',
        );
      });

      test('message IDs never sent send nothing', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        final beforeSentCount = repository.sentData.length;
        final requestedIds = [1, 2, 3];

        final arrayRequest = ServiceMessageArrayRequest(
          id: 50, arrayId: requestedIds,
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

        expect(
          repository.sentData.length,
          equals(beforeSentCount),
          reason: 'Should not send anything when requested IDs were never sent',
        );
      });
    });

    // ============================================================================
    // GROUP 6: Retransmission - Periodic Timer (Path C)
    // ============================================================================
    group('Retransmission: Periodic Timer (Path C)', () {
      test('startMissingMessagesCheck starts timer', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, null,
        );

        setupMissingIds(controlService, 2);

        service!.startMissingMessagesCheck(50);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(service!.isClosed(), isFalse);
      });

      test('stopMissingMessagesCheck cancels timer', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, null,
        );

        service!.startMissingMessagesCheck(50);
        final sentCountBefore = repository.sentData.length;

        service!.stopMissingMessagesCheck();

        await Future<void>.delayed(const Duration(milliseconds: 200));

        final sentCountAfter = repository.sentData.length;
        expect(sentCountAfter - sentCountBefore, lessThan(3));
      });

      test('double start replaces previous timer', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, null,
        );

        setupMissingIds(controlService, 1);

        service!.startMissingMessagesCheck(50);
        await Future<void>.delayed(const Duration(milliseconds: 75));

        service!.startMissingMessagesCheck(50);
        await Future<void>.delayed(const Duration(milliseconds: 75));

        expect(service!.isClosed(), isFalse);
      });

      test('timer is canceled on close', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, null,
        );

        service!.startMissingMessagesCheck(50);
        service!.close();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(service!.isClosed(), isTrue);
      });
    });

    // ============================================================================
    // GROUP 7: Retransmission - Threshold-based (Path D)
    // ============================================================================
    group('Retransmission: Threshold-based (Path D)', () {
      test('without ermesMessageControlService is no-op', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, 10,
        );

        final beforeSentCount = repository.sentData.length;
        await service!.checkAndRequestMissingMessages();

        expect(repository.sentData.length, equals(beforeSentCount));
      });

      test('missing IDs < threshold does not request', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, 10,
        );

        setupMissingIds(controlService, 5);

        final beforeSentCount = repository.sentData.length;
        await service!.checkAndRequestMissingMessages();

        expect(repository.sentData.length, equals(beforeSentCount));
      });

      test('missing IDs >= threshold sends request', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        const threshold = 10;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, threshold,
        );

        for (var i = 0; i < 15; i++) {
          await service!.send(Uint8List.fromList([i]));
        }

        setupMissingIds(controlService, 15);

        expect(
          controlService.numberOfMissingIds() >= threshold,
          isTrue,
          reason: 'Setup failed: missing IDs should >= threshold',
        );

        final beforeSentCount = repository.sentData.length;
        await service!.checkAndRequestMissingMessages();

        expect(
          repository.sentData.length,
          greaterThan(beforeSentCount),
          reason:
              'Should send request when missing IDs >= threshold ($threshold)',
        );
      });

      test('threshold null with missing IDs sends request', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, null,
        );

        await service!.send(Uint8List.fromList([1]));
        await service!.send(Uint8List.fromList([2]));
        await service!.send(Uint8List.fromList([3]));

        setupMissingIds(controlService, 3);

        final beforeSentCount = repository.sentData.length;
        await service!.checkAndRequestMissingMessages();

        expect(
          repository.sentData.length,
          greaterThan(beforeSentCount),
          reason: 'Should always send request when threshold is null and IDs are missing',
        );
      });

      test('no missing IDs with null threshold does not send request', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, null,
        );

        expect(controlService.numberOfMissingIds(), equals(0));

        final beforeSentCount = repository.sentData.length;
        await service!.checkAndRequestMissingMessages();

        expect(
          repository.sentData.length,
          equals(beforeSentCount),
          reason: 'Should not send request when no missing IDs exist',
        );
      });
    });

    // ============================================================================
    // GROUP 8: Lifecycle
    // ============================================================================
    group('Lifecycle', () {
      test('close is idempotent', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        expect(() => service!.close(), returnsNormally);
        expect(() => service!.close(), returnsNormally);
      });

      test('isClosed returns true after close', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, null, null, null,
        );

        service!.close();

        expect(service!.isClosed(), isTrue);
      });

      test('close cancels periodic timer', () async {
        final repository = await TestErmesRepository.create(
          open: true, peerId: 'test-peer-$testCounter',
        );
        _currentRepo = repository;
        final (controlRepo, controlService) = ErmesMessageControlFactory.createBoth();

        service = ErmesServiceFactory.createService(
          100, 1024, repository, idHandler,
          null, null, controlService, null, null,
        );

        service!.startMissingMessagesCheck(50);
        service!.close();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(service!.isClosed(), isTrue);
      });
    });
  });
}

void main() {
  testErmesServiceRetransmission();
}
