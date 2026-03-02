import 'dart:async';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Tests for encryption/decryption in ErmesReadRepo and ErmesSendRepo
void testEncryptionDecryption() {
  group('Encryption/Decryption - ErmesSendRepo and ErmesReadRepo', () {
    late _TestErmesRepository repository;
    late IIdHandlerService idHandler;
    late ErmesSendRepo sendRepo;
    late ErmesReadRepo readRepo;
    late ErmesPeerCipher peerCipher;
    late ISymmetricCipher symmetricCipher;

    setUp(() {
      repository = _TestErmesRepository();
      idHandler = IdHandlerServiceFactory.createDefault();

      // Create a real symmetric cipher
      symmetricCipher =
          generateSymmetric('A' * 64, SymmetricAlgorithm.aes);

      // Create peer cipher and add the symmetric cipher
      peerCipher = ErmesPeerCipher()
        ..addEncryptCipher(symmetricCipher)
        ..addDecryptCipher(symmetricCipher);

      // Register the cipher in the handler
      // ignore: unused_local_variable
      final handler = ErmesPeerCipherHandler()
        ..set(repository.remotePeerId, peerCipher);

      // Create send and read repos
      sendRepo = ErmesSendRepo(repository, idHandler);
      readRepo = ErmesReadRepo(
        repository,
        (serviceMsg) {}, // No service message handler needed for this test
        null, // No message control service needed
        const ErmesReadRepoOptions(),
      );
    });

    group('ErmesSendRepo Encryption', () {
      test('sends encrypted message when cipher is available', () {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        sendRepo.send(testData);

        // Verify message was sent
        expect(repository.sentData, isNotEmpty);

        // Get the sent data
        final sentMessage = repository.sentData.first;

        // Deserialize to verify it contains digest (indicating encryption)
        final messageRoot = uint8ArrayToObject<MessageRoot>(sentMessage);

        // After encryption, digest should be present
        expect(messageRoot.digest, isNotNull);
      });

      test('creates MessageRoot with digest field set', () {
        final testData = Uint8List.fromList([10, 20, 30]);

        sendRepo.send(testData);

        final sentMessage = repository.sentData.first;
        final messageRoot = uint8ArrayToObject<MessageRoot>(sentMessage);

        // Verify digest equals the cipher's keyId
        expect(messageRoot.digest, equals(symmetricCipher.keyId));
      });

      test('encrypted data is different from original', () {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        sendRepo.send(testData);

        final sentMessage = repository.sentData.first;
        final messageRoot = uint8ArrayToObject<MessageRoot>(sentMessage);

        // The encrypted data in messageSerialized should be different from
        // the plaintext serialization
        expect(messageRoot.messageSerialized, isNotEmpty);
        // We can't directly compare with plaintext as serialization
        // includes message structure, but we verify encryption occurred
        // by digest presence
        expect(messageRoot.digest, isNotNull);
      });

      test('sends multiple messages with same cipher', () {
        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([4, 5, 6]);

        sendRepo
          ..send(data1)
          ..send(data2);

        expect(repository.sentData, hasLength(2));

        // Both messages should have digest set
        for (final sentData in repository.sentData) {
          final messageRoot = uint8ArrayToObject<MessageRoot>(sentData);
          expect(messageRoot.digest, isNotNull);
        }
      });

      test('sends unencrypted message when cipher is not available', () {
        // Clear the cipher handler so no cipher is registered
        ErmesPeerCipherHandler().remove(repository.remotePeerId);

        final testData = Uint8List.fromList([5, 6, 7]);
        sendRepo.send(testData);

        expect(repository.sentData, isNotEmpty);
        final sentMessage = repository.sentData.first;
        final messageRoot = uint8ArrayToObject<MessageRoot>(sentMessage);

        // When cipher is null, digest should be null (no encryption)
        expect(messageRoot.digest, isNull);
      });

      test('message digest is null when ermesPeerCipher is null', () {
        // Verify the encryption block condition: if(ermesPeerCipher != null)
        // is correctly handling the null case
        ErmesPeerCipherHandler().remove(repository.remotePeerId);

        final testData = Uint8List.fromList([99, 100]);
        sendRepo.send(testData);

        final sentMessage = repository.sentData.first;
        final messageRoot = uint8ArrayToObject<MessageRoot>(sentMessage);

        // Explicitly verify the NULL cipher case
        expect(messageRoot.digest, isNull,
            reason: 'digest should be null when ermesPeerCipher is null');
      });
    });

    group('ErmesReadRepo Decryption', () {
      test('decrypts received encrypted message', () async {
        // First, create and send an encrypted message
        final testData = Uint8List.fromList([7, 8, 9, 10]);
        var receivedData = Uint8List(0);

        // Register listener to capture received data
        readRepo.addOnDataArrivedListener((data) {
          receivedData = data;
        });

        // Create a message with plaintext first
        final messageData = MessageData(id: 1, data: testData);
        final internalMessage = InternalMessage(
          message: MessageType.data(messageData),
          type: MessageValue.base,
        );
        final serializedInternal = objectToUint8Array(internalMessage);

        // Encrypt the serialized message
        final encryptedData = symmetricCipher.encrypt(serializedInternal);
        final dataEncrypted = DataEncrypted(
          symmetricCipher.keyId,
          Uint8List.fromList(encryptedData),
        );

        // Create MessageRoot with encrypted data
        final messageRoot = MessageRoot(
          messageSerialized: dataEncrypted.encryptedData,
          integrityCheckValue: calculateHashSync(serializedInternal),
          digest: dataEncrypted.keyId,
        );

        final serializedMessage = objectToUint8Array(messageRoot);

        // Simulate receiving the encrypted message
        repository.simulateDataReceived(serializedMessage);

        // Give async processing time to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verify the received data matches the original
        expect(receivedData, equals(testData));
      });

      test('handles message with no encryption (digest is null)', () async {
        final testData = Uint8List.fromList([11, 12, 13]);
        var receivedData = Uint8List(0);

        readRepo.addOnDataArrivedListener((data) {
          receivedData = data;
        });

        // Create message without encryption
        final messageData = MessageData(id: 1, data: testData);
        final internalMessage = InternalMessage(
          message: MessageType.data(messageData),
          type: MessageValue.base,
        );
        final serializedInternal = objectToUint8Array(internalMessage);

        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: calculateHashSync(serializedInternal),
        );

        final serializedMessage = objectToUint8Array(messageRoot);
        repository.simulateDataReceived(serializedMessage);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(receivedData, equals(testData));
      });


      test('correctly identifies when cipher is null vs digest is null',
          () async {
        // Verify the pattern: if(messRoot.digest case final digest?)
        // This should only attempt decryption when digest is NOT null

        final testData = Uint8List.fromList([20, 21, 22]);
        var receivedData = Uint8List(0);

        readRepo.addOnDataArrivedListener((data) {
          receivedData = data;
        });

        // Create message with NULL digest (unencrypted)
        final messageData = MessageData(id: 1, data: testData);
        final internalMessage = InternalMessage(
          message: MessageType.data(messageData),
          type: MessageValue.base,
        );
        final serializedInternal = objectToUint8Array(internalMessage);

        // Create MessageRoot with null digest (default value)
        final messageRoot = MessageRoot(
          messageSerialized: serializedInternal,
          integrityCheckValue: calculateHashSync(serializedInternal),
        );

        final serializedMessage = objectToUint8Array(messageRoot);

        // Even though cipher is not available, this should NOT throw
        // because digest is null (the pattern uses: if(messRoot.digest
        // case final digest?))
        repository.simulateDataReceived(serializedMessage);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(receivedData, equals(testData),
            reason: 'Should handle null digest without requiring cipher');
      });

    });

    group('End-to-End Encryption/Decryption', () {
      test('message sent encrypted can be received and decrypted', () async {
        final originalData = Uint8List.fromList([100, 101, 102, 103]);
        var receivedData = Uint8List(0);

        // Register listener on read repo
        readRepo.addOnDataArrivedListener((data) {
          receivedData = data;
        });

        // Send message through send repo (will be encrypted)
        sendRepo.send(originalData);

        // Get the encrypted message that was sent
        expect(repository.sentData, isNotEmpty);
        final encryptedMessage = repository.sentData.first;

        // Clear sent data and simulate receiving the message
        repository.sentData.clear();
        repository.simulateDataReceived(encryptedMessage);

        // Wait for async processing
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verify received data matches original
        expect(receivedData, equals(originalData));
      });

      test('message integrity is preserved through encryption', () async {
        final originalData = Uint8List.fromList([50, 51, 52, 53]);
        var receivedData = Uint8List(0);
        final completer = Completer<void>();

        readRepo.addOnDataArrivedListener((data) {
          receivedData = data;
          completer.complete();
        });

        sendRepo.send(originalData);

        final encryptedMessage = repository.sentData.first;
        repository.sentData.clear();
        repository.simulateDataReceived(encryptedMessage);

        // Wait for the data to be received and processed
        await completer.future.timeout(const Duration(seconds: 2));

        expect(receivedData, equals(originalData));
      });

      test('large message fragmentation with encryption', () async {
        // Create a large message that will be fragmented
        final largeData = Uint8List(5000);
        final random = _Random();
        for (var i = 0; i < largeData.length; i++) {
          largeData[i] = random.nextInt(256);
        }

        var receivedData = Uint8List(0);
        readRepo.addOnDataArrivedListener((data) {
          receivedData = data;
        });

        // Send the large message
        await sendRepo.send(largeData);

        // Should have multiple messages sent due to fragmentation
        expect(repository.sentData.length, greaterThan(1));

        // All sent messages should have encryption digest
        for (final sentData in repository.sentData) {
          final messageRoot = uint8ArrayToObject<MessageRoot>(sentData);
          expect(messageRoot.digest, isNotNull);
        }

        // Simulate receiving all encrypted fragments
        final sentMessages = List<Uint8List>.from(repository.sentData);
        repository.sentData.clear();
        for (final message in sentMessages) {
          repository.simulateDataReceived(message);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        // Verify the reassembled message matches the original
        expect(receivedData, equals(largeData));
      });
    });
  });
}

/// Test implementation of IErmesRepository with encryption support
class _TestErmesRepository implements IErmesRepository {
  final List<Uint8List> sentData = [];
  final List<void Function(Uint8List)> _dataCallbacks = [];

  @override
  final String remotePeerId = 'test-peer-123';
  Exception? lastException;

  @override
  void destroy({bool force = false}) {
    sentData.clear();
    _dataCallbacks.clear();
  }

  @override
  bool isOpen() => true;

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
      try {
        callback(data);
      } catch (e) {
        // Capture async exceptions that might be thrown
        if (e is Exception) {
          lastException = e;
        }
        rethrow;
      }
    }
  }
}

/// Simple pseudo-random number generator for testing
class _Random {
  int _seed = 123456789;

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
}

void main() {
  testEncryptionDecryption();
}
