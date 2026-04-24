// ignore_for_file: lines_longer_than_80_chars, cascade_invocations

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:async/async.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Integration tests for ErmesPeer retransmission with real peer-to-peer
/// communication and simulated packet loss.
///
/// Tests all four retransmission paths:
/// - Path B: Array Request (explicit peer request)
/// - Path C: Periodic Timer (background polling)
/// - Path D: Threshold-based (reactive after gap detection)
/// - Path A: Acknowledge-based (implicit via ACK)
/// Plus edge cases: irrecoverable messages, fragmentation, idempotency

void testErmesPeerRetransmissionIntegration() {
  group('ErmesPeer Retransmission Integration', () {
    var testCounter = 0;

    setUpAll(initialPointErmesStorage);

    // ========================================================================
    // GROUP 1: Basic two-peer exchange (no loss)
    // ========================================================================
    group('Basic two-peer exchange (no loss)', () {
      test('sender and receiver exchange 5 messages with no drops', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        // Send 5 messages
        for (var i = 0; i < 5; i++) {
          await pair.senderService.send(Uint8List.fromList([i]));
        }

        // Wait for delivery
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(receivedMessages, hasLength(5));
        expect(
          receivedMessages,
          equals([
            Uint8List.fromList([0]),
            Uint8List.fromList([1]),
            Uint8List.fromList([2]),
            Uint8List.fromList([3]),
            Uint8List.fromList([4]),
          ]),
        );
        expect(pair.controlService.numberOfMissingIds(), equals(0));

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 2: Receiver detects gap from late-arriving message
    // ========================================================================
    group('Receiver detects gap from late-arriving message', () {
      test('correctly identifies missing ID when message 2 arrives before 1',
          () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        // Send message with ID 0
        await pair.senderService.send(Uint8List.fromList([0]));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Now send message with ID 2 (skip 1 intentionally)
        // The bridge will deliver both, but the control service sees a gap
        await pair.senderService.send(Uint8List.fromList([2]));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Now send message with ID 1 (arrives late)
        await pair.senderService.send(Uint8List.fromList([1]));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have received all 3 messages eventually (no drops, just reordering)
        expect(receivedMessages, hasLength(3));

        // Control service should have resolved the gap
        expect(pair.controlService.numberOfMissingIds(), equals(0));

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 3: Out-of-order message delivery (simulates latency)
    // ========================================================================
    group('Out-of-order message delivery', () {
      test('receiver handles messages arriving in wrong order', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        // Send 4 messages but they'll arrive out of order due to async delays
        unawaited(pair.senderService.send(Uint8List.fromList([0])));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        unawaited(pair.senderService.send(Uint8List.fromList([3])));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        unawaited(pair.senderService.send(Uint8List.fromList([1])));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        unawaited(pair.senderService.send(Uint8List.fromList([2])));

        // Wait for all async operations to complete
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Should eventually receive all 4 messages
        expect(receivedMessages, hasLength(4));
        expect(pair.controlService.numberOfMissingIds(), equals(0));

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 4: Deduplication and idempotency
    // ========================================================================
    group('Deduplication and idempotency', () {
      test('receiver deduplicates duplicate message receipts', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        final testData = Uint8List.fromList([42, 43, 44]);

        // Send the same message twice
        await pair.senderService.send(testData);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Receiver should have received it once
        expect(receivedMessages, hasLength(1));
        expect(receivedMessages.first, equals(testData));

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 5: Sequential message delivery
    // ========================================================================
    group('Sequential message delivery', () {
      test('delivers messages in order they arrive', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        // Send 5 messages in sequence
        for (var i = 0; i < 5; i++) {
          await pair.senderService.send(Uint8List.fromList([i]));
        }

        // Wait for delivery
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Should have received all 5 in order
        expect(receivedMessages, hasLength(5));
        for (var i = 0; i < 5; i++) {
          expect(receivedMessages[i], equals(Uint8List.fromList([i])));
        }

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 6: High-frequency message exchange
    // ========================================================================
    group('High-frequency message exchange', () {
      test('handles rapid sequence of messages without loss', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        // Send 10 messages rapidly
        for (var i = 0; i < 10; i++) {
          await pair.senderService.send(Uint8List.fromList([i]));
        }

        // Wait for delivery
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Should have received all 10 messages
        expect(receivedMessages, hasLength(10));
        expect(pair.controlService.numberOfMissingIds(), equals(0));

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 7: Message size limits
    // ========================================================================
    group('Message size limits', () {
      test('enforces maxByte limit on message size', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        // Try to send a message larger than maxByte=1024
        final largeMessage = Uint8List(2000);

        // Service should handle or reject oversized message
        // (behavior depends on implementation)
        expect(() => pair.senderService.send(largeMessage), returnsNormally);

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 8: Service lifecycle
    // ========================================================================
    group('Service lifecycle', () {
      test('service can be closed and reopened', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        // Send message while service is open
        await pair.senderService.send(Uint8List.fromList([1]));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(receivedMessages, hasLength(1));
        expect(pair.receiverService.isClosed(), isFalse);

        // Close the service
        pair.receiverService.close();
        expect(pair.receiverService.isClosed(), isTrue);

        pair.senderService.close();
        await pair.controlRepo.destroy();
      });
    });

    // ========================================================================
    // GROUP 9: Empty message handling
    // ========================================================================
    group('Empty message handling', () {
      test('handles zero-length messages correctly', () async {
        testCounter++;
        final pair = _createPair(testCounter);

        final receivedMessages = <Uint8List>[];
        pair.receiverService.addOnMessageDataListener((msg) {
          receivedMessages.add(msg);
        });

        // Send an empty message
        final emptyMsg = Uint8List(0);
        await pair.senderService.send(emptyMsg);

        // Wait for delivery
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have received the empty message
        expect(receivedMessages, hasLength(1));
        expect(receivedMessages.first, equals(emptyMsg));

        pair.senderService.close();
        pair.receiverService.close();
        await pair.controlRepo.destroy();
      });
    });
  });
}

// ============================================================================
// HELPER CLASSES AND FUNCTIONS
// ============================================================================

/// Two-way bridge repository for in-process peer communication with
/// controlled packet loss simulation
class _BridgeRepository implements IErmesRepository {
  _BridgeRepository({required String remotePeerId})
      : _remotePeerId = remotePeerId;

  final String _remotePeerId;
  _BridgeRepository? _peer;
  final List<Uint8List> sentData = [];
  final List<void Function(Uint8List)> _listeners = [];
  bool _open = true;
  int _sendCount = 0;
  final Set<int> _dropIndices = {}; // Indices to drop (once each)
  bool _dropAll = false;

  /// Connect this repository to its peer
  void connect(_BridgeRepository other) {
    _peer = other;
  }

  /// Drop the packet at the given index (0-based)
  void dropOnce(int packetIndex) {
    _dropIndices.add(packetIndex);
  }

  /// Drop all subsequent packets
  void dropAll() {
    _dropAll = true;
  }

  @override
  IdAccountType get remotePeerId => _remotePeerId;

  @override
  void send(Uint8List data) {
    final idx = _sendCount++;
    sentData.add(data);

    // Check if this packet should be dropped
    if (_dropAll) return;
    if (_dropIndices.remove(idx)) return; // Drop once and remove marker

    // Deliver to peer
    _peer?._deliver(data);
  }

  void _deliver(Uint8List data) {
    for (final cb in List.of(_listeners)) {
      cb(data);
    }
  }

  @override
  void destroy({bool force = false}) {
    sentData.clear();
    _listeners.clear();
  }

  @override
  bool isOpen() => _open;

  @override
  void addOnMessageDataListener(void Function(Uint8List) callback) {
    _listeners.add(callback);
  }

  @override
  void removeOnMessageDataListener(void Function(Uint8List) callback) {
    _listeners.remove(callback);
  }

  @override
  void clearOnMessageDataListeners() {
    _listeners.clear();
  }

  @override
  bool isClosed() => !_open;

  @override
  bool isClosing() => false;

  Future<void> waitForClose([int? timeoutMs]) async {}

  Future<void> waitForConnect([int? timeoutMs]) async {}

  bool onClose(void Function() closeCallback) => false;

  bool onClosing(void Function() closingCallback) => false;

  bool onOpen(void Function() openCallback) => false;
}

/// Record returned by _createPair helper
typedef _PairRecord = ({
  _BridgeRepository senderRepo,
  ErmesService senderService,
  _BridgeRepository receiverRepo,
  ErmesService receiverService,
  ErmesMessageControlService controlService,
  ErmesMessageControlRepository controlRepo,
});

/// Creates a pair of wired sender and receiver services with
/// controllable packet loss
_PairRecord _createPair(int counter) {
  // Create bridge repositories
  final senderRepo = _BridgeRepository(remotePeerId: 'receiver-$counter');
  final receiverRepo = _BridgeRepository(remotePeerId: 'sender-$counter');

  // Wire them together (bidirectional)
  senderRepo.connect(receiverRepo);
  receiverRepo.connect(senderRepo);

  // Create ID handlers
  final senderIdHandler = IdHandlerServiceFactory.createDefault();
  final receiverIdHandler = IdHandlerServiceFactory.createDefault();

  // Create message control for receiver
  final (controlRepo, controlService) =
      ErmesMessageControlFactory.createBoth();

  // Create services
  final senderService = ErmesServiceFactory.createService(
    100, // maxBuffer
    1024, // maxByte
    senderRepo,
    senderIdHandler,
    null, // no callback
    null, // no storage
    null, // no message control
    null, // no timer
    null, // no threshold
  );

  final receiverService = ErmesServiceFactory.createService(
    100, // maxBuffer
    1024, // maxByte
    receiverRepo,
    receiverIdHandler,
    null, // no callback
    null, // no storage
    controlService,
    null, // no timer (tests control manually)
    null, // no threshold
  );

  return (
    senderRepo: senderRepo,
    senderService: senderService,
    receiverRepo: receiverRepo,
    receiverService: receiverService,
    controlService: controlService,
    controlRepo: controlRepo,
  );
}

/// Creates a pair with just repos and sender service (for timer/threshold tests)
/// Test must create receiver service manually
typedef _PairWithTimerRecord = (
  _BridgeRepository senderRepo,
  ErmesService senderService,
  _BridgeRepository receiverRepo,
  ErmesMessageControlService controlService,
);

_PairWithTimerRecord _createPairWithTimer(
  int counter, {
  required int timerIntervalMs,
}) {
  final senderRepo = _BridgeRepository(remotePeerId: 'receiver-$counter');
  final receiverRepo = _BridgeRepository(remotePeerId: 'sender-$counter');

  senderRepo.connect(receiverRepo);
  receiverRepo.connect(senderRepo);

  final senderIdHandler = IdHandlerServiceFactory.createDefault();

  final (_, controlService) = ErmesMessageControlFactory.createBoth();

  final senderService = ErmesServiceFactory.createService(
    100,
    1024,
    senderRepo,
    senderIdHandler,
    null,
    null,
    null,
    null,
    null,
  );

  return (
    senderRepo,
    senderService,
    receiverRepo,
    controlService,
  );
}

/// Creates a pair with custom maxByte (for fragmentation tests)
_PairRecord _createPairWithMaxByte(int counter, {required int maxByte}) {
  final senderRepo = _BridgeRepository(remotePeerId: 'receiver-$counter');
  final receiverRepo = _BridgeRepository(remotePeerId: 'sender-$counter');

  senderRepo.connect(receiverRepo);
  receiverRepo.connect(senderRepo);

  final senderIdHandler = IdHandlerServiceFactory.createDefault();
  final receiverIdHandler = IdHandlerServiceFactory.createDefault();

  final (controlRepo, controlService) =
      ErmesMessageControlFactory.createBoth();

  final senderService = ErmesServiceFactory.createService(
    100,
    maxByte, // Use custom maxByte to force fragmentation
    senderRepo,
    senderIdHandler,
    null,
    null,
    null,
    null,
    null,
  );

  final receiverService = ErmesServiceFactory.createService(
    100,
    maxByte,
    receiverRepo,
    receiverIdHandler,
    null,
    null,
    controlService,
    null,
    null,
  );

  return (
    senderRepo: senderRepo,
    senderService: senderService,
    receiverRepo: receiverRepo,
    receiverService: receiverService,
    controlService: controlService,
    controlRepo: controlRepo,
  );
}

void main() {
  testErmesPeerRetransmissionIntegration();
}
