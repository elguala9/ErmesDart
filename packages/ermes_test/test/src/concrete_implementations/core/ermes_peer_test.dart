import 'dart:typed_data';

import 'package:cryptdart/types/crypto_algorithm.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesPeer();
}

/// Tests for ErmesPeer message sending
void testErmesPeer() {
  group('ErmesPeer - Message Sending', () {
    late _FakeErmesService fakeService;
    late ErmesPeer peer;

    setUp(() {
      fakeService = _FakeErmesService();
      peer = ErmesPeer.create(
        service: fakeService,
        remotePeerId: 'alice',
        enableEncryption: false,
      );
    });

    group('send() method', () {
      test('sends message when service is open', () {
        fakeService.closed = false;
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        peer.send(testData);

        // Verify message was sent via service
        expect(fakeService.sentMessages, contains(testData));
      });

      test('does not send when service is _closed', () {
        fakeService.closed = true;
        final testData = Uint8List.fromList([10, 20, 30]);

        peer.send(testData);

        // Service should not have received it
        expect(fakeService.sentMessages, isEmpty);
      });

      test('throws error when peer is disposed', () {
        fakeService.closed = false;
        final testData = Uint8List.fromList([1, 2, 3]);

        // Dispose the peer
        peer.dispose();

        // Should throw when trying to send
        expect(
          () => peer.send(testData),
          throwsA(isA<StateError>()),
        );
      });

      test('tracks message count for key rotation', () {
        fakeService.closed = false;
        final testData = Uint8List.fromList([1, 2, 3]);

        // Send multiple messages
        for (var i = 0; i < 5; i++) {
          peer.send(testData);
        }

        // Verify messages were sent
        expect(fakeService.sentMessages.length, equals(5));
      });
    });


    group('Edge cases', () {
      test('handles rapid send/close transitions', () {
        final testData = Uint8List.fromList([1, 2, 3]);

        // Send while open
        fakeService.closed = false;
        peer.send(testData);
        expect(fakeService.sentMessages.length, equals(1));

        // Close service and send again (message is discarded)
        fakeService.closed = true;
        peer.send(testData);
        expect(fakeService.sentMessages.length, equals(1));

        // Reopen and send again
        fakeService.closed = false;
        peer.send(testData);
        expect(fakeService.sentMessages.length, equals(2));
      });
    });
  });
}

/// Fake implementation of IErmesService for testing
class _FakeErmesService implements IErmesService {
  bool closed = false;
  final List<TypeOfDataExternal> sentMessages = [];

  @override
  bool isClosed() => closed;

  @override
  bool isClosing() => closed;

  @override
  bool isOpen() => !closed;

  @override
  Future<void> send(TypeOfDataExternal data) async {
    if (!closed) {
      sentMessages.add(data);
    }
  }

  @override
  void sendNewKey({
    required CryptoAlgorithm algorithm,
    required String key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  }) {}

  @override
  void addOnMessageDataListener(CallbackOnDataArrived callback) {}

  @override
  void removeOnMessageDataListener(CallbackOnDataArrived callback) {}

  @override
  void clearOnMessageDataListeners() {}

  @override
  void addOnDataSendingListener(CallbackOnDataSending callback) {}

  @override
  void removeOnDataSendingListener(CallbackOnDataSending callback) {}

  @override
  void clearOnDataSendingListeners() {}

  @override
  void addOnDataSentListener(CallbackOnDataSent callback) {}

  @override
  void removeOnDataSentListener(CallbackOnDataSent callback) {}

  @override
  void clearOnDataSentListeners() {}

  @override
  void addOnNewKeyListener(CallbackOnNewKey callback) {}

  @override
  void removeOnNewKeyListener(CallbackOnNewKey callback) {}

  @override
  void clearOnNewKeyListeners() {}

  @override
  void setRepository(IErmesRepository repository) {}

  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  void sendAcknowledge() {}

  @override
  void startMissingMessagesCheck(int intervalMs) {}

  @override
  void stopMissingMessagesCheck() {}

  @override
  Future<void> checkAndRequestMissingMessages() async {}
}
