import 'dart:convert';
import 'dart:typed_data';


import 'package:callback_handler/callback_handler.dart';
import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';
import 'package:uuid/uuid.dart';

import 'ermes_utility/hash_utils.dart';
import 'utility.dart';
import 'package:ermes_storage/ermes_storage.dart';

// Serialization utility for Ermes types

Uint8List objectToUint8Array(IErmesSerializable obj) {
  // Serialize the object to JSON
  final json = obj.toJson();

  // Convert JSON map to string, then to UTF-8 encoded bytes
  final jsonString = jsonEncode(json);
  return Uint8List.fromList(utf8.encode(jsonString));
}


/// ErmesSendRepo - Handles message sending and serialization
///
/// Main responsibilities:
/// - Serialization of user data into Ermes messages
/// - Automatic fragmentation for large messages
/// - Calculation and addition of integrity hash
/// - Management of unique IDs via IdHandler
/// - Sending via transport repository
/// - Callbacks to notify user of sending

class ErmesSendRepo {
  /// ErmesSendRepo constructor
  ///
  /// [repository] - Transport repository for sending messages
  /// [idHandler] - Service to generate unique IDs for messages
  /// [maxByte] - Maximum message size (default: 1024 bytes)
  ErmesSendRepo(this._repository, this._idHandler, [int maxByte = 1024])
    : _maxByte = maxByte + maxHeader {
    // Add space for headers
    if (maxByte >= 1200) {
      throw ArgumentError('Max byte cannot be more than 1299');
    }

    storageRoot = ErmesStorageAndCachingMessagesHandler.instance
        .forPeer(_repository.remotePeerId)
        .messageRoot;
  }

  late ErmesStorageAndCachingMessageRoot storageRoot;
  /// Transport repository for actual sending
  final IErmesRepository _repository;

  /// Maximum size of a single message (including headers)
  final int _maxByte;

  /// Service for generating unique IDs
  final IIdHandlerService _idHandler;

  /// Callback handlers for message sending events
  late final CallbackHandler<MessageType, void> _onMessageSendingHandler =
      CallbackHandler<MessageType, void>();
  late final CallbackHandler<MessageType, void> _onMessageSentHandler =
      CallbackHandler<MessageType, void>();

  /// UUID generator for chunk reference IDs
  final Uuid _uuid = const Uuid();

  /// Register a listener for pre-send events (for storage/caching)
  void addOnMessageSendingListener(CallbackOnMessageSending callback) {
    _onMessageSendingHandler.register(callback);
  }

  /// Remove a listener for pre-send events
  void removeOnMessageSendingListener(CallbackOnMessageSending callback) {
    _onMessageSendingHandler.unregister(callback);
  }

  /// Clear all pre-send listeners
  void clearOnMessageSendingListeners() {
    _onMessageSendingHandler.clear();
  }

  /// Register a listener for post-send events
  void addOnMessageSentListener(CallbackOnMessageSent callback) {
    _onMessageSentHandler.register(callback);
  }

  /// Remove a listener for post-send events
  void removeOnMessageSentListener(CallbackOnMessageSent callback) {
    _onMessageSentHandler.unregister(callback);
  }

  /// Clear all post-send listeners
  void clearOnMessageSentListeners() {
    _onMessageSentHandler.clear();
  }

  /// Backward compatibility getter
  /// (kept for now, but legacy code should migrate)
  CallbackOnMessageSending? get callbackOnDataSending => null;

  /// Backward compatibility setter
  /// (kept for now, but legacy code should migrate)
  set callbackOnDataSending(CallbackOnMessageSending callback) {
    addOnMessageSendingListener(callback);
  }

  /// Backward compatibility getter
  /// (kept for now, but legacy code should migrate)
  CallbackOnMessageSent? get callbackOnDataSended => null;

  /// Backward compatibility setter
  /// (kept for now, but legacy code should migrate)
  set callbackOnDataSended(CallbackOnMessageSent callback) {
    addOnMessageSentListener(callback);
  }

  /// Main method for sending user data
  ///
  /// Sending process:
  /// 1. Generate unique ID for message
  /// 2. Create MessageData with data
  /// 3. Determine if fragmentation is needed
  /// 4. Send message (whole or fragmented)
  void send(TypeOfData rawData) {
    // If data exceeds maximum size, fragmentation is necessary
    if (rawData.length > _maxByte) {
      // Generate unique ID for fragmented message
      final chunkedId = _uuid.v4();

      // Create chunk array with optimal size (300 byte margin for headers)
      final rawDataArray = chunkArrayBuffer(
        _idHandler,
        rawData,
        chunkedId,
        _maxByte - 300,
      );

      // Notify all pre-send listeners for each chunk (for storage/caching)
      for (final chunk in rawDataArray) {
        _onMessageSendingHandler.call(MessageType.chunk(chunk));
      }

      sendMessageType(rawDataArray.map(MessageType.chunk).toList());
      return;
    }

    // Small message: direct sending without fragmentation
    final newId = _idHandler.getNewId();
    final message = createMessageDataErmes(rawData, newId);

    // Notify all pre-send listeners (for storage/caching)
    _onMessageSendingHandler.call(MessageType.data(message));

    sendMessageType([MessageType.data(message)]);
  }

  /// Convert MessageType to root messages and send via repository
  ///
  /// Serialization process (v2 wire format):
  /// 1. Create InternalMessage with type and content
  /// 2. Serialize to JSON and then to bytes (calculate hash on plaintext bytes)
  /// 3. Optionally encrypt the bytes
  /// 4. Create MessageRoot with:
  ///    - messageJson: nested JSON (if plaintext, no cipher)
  ///    - messageSerialized: encrypted bytes (if cipher available)
  ///    - digest: cipher key ID (if encrypted)
  void sendMessageType(List<MessageType> array) {
    for (final element in array) {
      // Create internal message with automatically determined type
      final internalMessage = InternalMessage(
        message: element,
        type: getMessageType(element),
      );

      // Serialize internal message to JSON
      final innerJson = internalMessage.toJson();
      final innerBytes = Uint8List.fromList(utf8.encode(jsonEncode(innerJson)));

      // Calculate hash on plaintext (before encryption)
      final hash = calculateHashSync(innerBytes);

      Digest? digest;
      Uint8List? encryptedBytes;

      // Check if encryption is available
      final handler = ErmesPeerCipherHandler();
      final ermesPeerCipher = handler.get(_repository.remotePeerId);
      if (ermesPeerCipher != null) {
        final dataEncrypted = ermesPeerCipher.encrypt(innerBytes);
        encryptedBytes = dataEncrypted.encryptedData;
        digest = dataEncrypted.keyId;
      }

      // Notify all pre-send listeners (if not already done in send())
      _onMessageSendingHandler.call(element);

      // Create root message with wire format v2
      final messageRoot = MessageRoot(
        // plaintext: nested JSON, encrypted: null
        messageJson: digest == null ? innerJson : null,
        // encrypted: bytes (base64 in toJson)
        messageSerialized: encryptedBytes ?? Uint8List(0),
        integrityCheckValue: hash,
        digest: digest,
      );

      // Send serialized root message
      _sendRootMessage(messageRoot);
      storageRoot.store(
        // I always use the id of the message to store
        MessageRootStorage.fromMessageRoot(messageRoot, element.id)
      );
      // Notify all post-send listeners
      _onMessageSentHandler.call(element);
    }
  }

  /// Serialize and send a MessageRoot via transport repository
  void _sendRootMessage(MessageRoot message) {
    final rawData = objectToUint8Array(message);
    _sendWithRepo(rawData);
  }

  /// Actual sending via transport repository
  ///
  /// Interface point with transport layer (Peer, WebSocket, etc.)
  /// Future: implement retry logic and reception confirmations
  void _sendWithRepo(SerializableDataType dataRaw) {
    _repository.send(dataRaw);

    // For now we assume sending is always successful
    // In a real implementation, should wait for confirmation
    // TODO: In future implement message tracking and confirmations
  }
}
