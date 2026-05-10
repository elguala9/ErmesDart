import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:callback_handler/callback_handler.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';

import 'ermes_utility/chunk_handler.dart';
import 'ermes_utility/hash_utils.dart';
import 'ermes_utility/observable_queue.dart';
import 'exceptions.dart';
import 'serialization_registry.dart';

/// Deserialize UTF-8 encoded JSON bytes to an Ermes type
///
/// Uses the SerializationRegistry to dispatch to the correct fromJson
/// factory based on the type parameter T. This eliminates the need for
/// large if-else chains and enables extensibility.
///
/// Throws [ArgumentError] if the type T is not registered in the registry.

T uint8ArrayToObject<T>(Uint8List data) {
  // Decode UTF-8 bytes to JSON string
  final jsonString = utf8.decode(data);
  final json = jsonDecode(jsonString) as Map<String, dynamic>;

  // Get the fromJson factory from the registry
  final factory = SerializationRegistry.getFactory<T>();

  // Deserialize using the factory
  return factory(json) as T;
}


Uint8List uint8ArrayToArrayBuffer(Uint8List data) => data;

/// Cache used to deduplicate incoming messages by their integrity hash.
/// Key: hash string (computed on plaintext bytes),
/// Value: unused (bool placeholder).
typedef ErmesDeduplicationCache = IGenericCachingRepository<String, bool>;

/// Configuration options for ErmesReadRepo

class ErmesReadRepoOptions {
  const ErmesReadRepoOptions({
    this.maxBufferSize,
    this.callbackOnDataArrived,
    this.callbackOnMessageProcessed,
  });

  /// Maximum size of the unread message buffer
  final int? maxBufferSize;

  /// Callback called when new data arrives
  final CallbackOnDataArrived? callbackOnDataArrived;

  /// Callback called after a message has been processed (for threshold checks)
  final Future<void> Function()? callbackOnMessageProcessed;
}

/// ErmesReadRepo - Handles message reception and processing
///
/// Main responsibilities:
/// - Message reception from transport repository
/// - Deserialization and integrity validation
/// - Chunk handling for large messages
/// - Automatic missing message control after each reception
/// - Buffer for messages not yet read by user

class ErmesReadRepo {
  /// ErmesReadRepo constructor
  ///
  /// [callbackServiceMessage] - Callback to handle service messages
  /// (control, missing requests, etc.)
  /// [ermesMessageControlService] - Service to track and manage missing
  /// messages (optional)
  /// [options] - Configuration options (buffer size, callbacks, etc.)
  ErmesReadRepo(
    this._repository,
    CallbackServiceMessage callbackServiceMessage,
    this.ermesMessageControlService,
    ErmesReadRepoOptions options,
  ) : _messageNotReaded = ObservableQueue<TypeOfData>(
        options.maxBufferSize ?? 100,
      ),
      _callbackOnMessageProcessed = options.callbackOnMessageProcessed {
    // Initialize callback handlers
    _serviceMessageHandler.register(callbackServiceMessage);

    // Register optional data arrived callback if provided
    if (options.callbackOnDataArrived != null) {
      _onDataArrivedHandler.register(options.callbackOnDataArrived!);
    }

    // Register handler for incoming messages from transport repository
    _repository.addOnMessageDataListener(_handleMessageArrayBuffer);

    storageMessageType =
        getErmesStorageAndCachingMessagesHandlerBaseMessageType()
            .forPeer(_repository.remotePeerId)
            .messageType;

    // Configure observer for messages added to buffer
    // When a message is added, it's immediately passed to user via callback
    _messageNotReaded.onAddCallback = () {
      while (!_messageNotReaded.isEmpty()) {
        final data = _messageNotReaded.shift();
        // Invoke all registered data arrived listeners
        _onDataArrivedHandler.call(data);
      }
    };
  }

  /// Observable buffer of messages ready to be read by user
  final ObservableQueue<TypeOfData> _messageNotReaded;

  /// Deduplication set: tracks already-processed message hashes (synchronous)
  final Set<String> _processedHashes = {};

  /// Map of chunks not yet completely assembled (chunk_id -> ChunkHandler)
  final Map<IdChunkType, ChunkHandler> _messageNotMerged = {};

  late IErmesStorageAndCachingMessages<MessageType> storageMessageType;

  /// Transport repository for network communication
  final IErmesRepository _repository;

  /// Callback handlers for events
  late final CallbackHandler<ServiceMessage, void> _serviceMessageHandler =
      CallbackHandler<ServiceMessage, void>();
  late final CallbackHandler<TypeOfDataExternal, void> _onDataArrivedHandler =
      CallbackHandler<TypeOfDataExternal, void>();

  /// Callback called after processing each message (for missing checks)
  final Future<void> Function()? _callbackOnMessageProcessed;

  /// Service for missing message control
  final IErmesMessageControlService? ermesMessageControlService;

  /// Add a listener for service messages
  void addServiceMessageListener(CallbackServiceMessage callback) {
    _serviceMessageHandler.register(callback);
  }

  /// Remove a listener for service messages
  void removeServiceMessageListener(CallbackServiceMessage callback) {
    _serviceMessageHandler.unregister(callback);
  }

  /// Add a listener for incoming data
  void addOnDataArrivedListener(CallbackOnDataArrived callback) {
    _onDataArrivedHandler.register(callback);
  }

  /// Remove a listener for incoming data
  void removeOnDataArrivedListener(CallbackOnDataArrived callback) {
    _onDataArrivedHandler.unregister(callback);
  }

  /// Clear all incoming data listeners
  void clearOnDataArrivedListeners() {
    _onDataArrivedHandler.clear();
  }

  /// Main handler for raw messages received from transport repository
  ///
  /// Processing phases:
  /// 1. Validation of received message
  /// 2. Deserialization of MessageRoot structure
  /// 3. Integrity verification via hash
  /// 4. Deserialization of internal message
  /// 5. Routing to appropriate handler
  Future<void> _handleMessageArrayBuffer(SerializableDataType message) async {

    // Basic validation: verify message is not empty or corrupted
    if (message.isEmpty) {
      // ignore: avoid_print
      print('Received empty or invalid message');
      return;
    }

    // Deserialize outer message structure (contains hash + serialized data)
    final messRoot = uint8ArrayToObject<MessageRoot>(message);

    // Determine if encrypted (has digest) or plaintext (has messageJson)
    late final Uint8List plainBytes;

    if (messRoot.digest case final digest?) {
      // Encrypted message: decrypt first
      final handler = ErmesPeerCipherHandler();
      final ermesPeerCipher = handler.get(_repository.remotePeerId);
      if (ermesPeerCipher == null) {
        throw CoreException('Cipher not found for peer');
      }

      final decrypted = ermesPeerCipher.decrypt(
        DataEncrypted(digest, messRoot.messageSerialized),
      );
      plainBytes = decrypted;
    } else if (messRoot.messageJson case final json?) {
      // Plaintext message (v2): reconstruct bytes from nested JSON
      plainBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(json)),
      );
    } else {
      // Legacy v1 or malformed: treat messageSerialized as plaintext
      plainBytes = messRoot.messageSerialized;
    }

    if (plainBytes.isEmpty) {
      // ignore: avoid_print
      print('Decrypted or extracted plaintext is empty, discarding');
      return;
    }

    // Verify message integrity via hash (hash is computed on plaintext)
    final computedHash = calculateHashSync(plainBytes);
    if (messRoot.integrityCheckValue.toString() != computedHash.toString()) {
      // ignore: avoid_print
      print('Hash mismatch - message corrupted, discarding');
      return;
    }

    // Deduplicate: discard messages whose hash was already processed
    if (!_processedHashes.add(computedHash)) {
      return;
    }

    // Deserialize actual internal message from plaintext bytes
    final messageDeserialized = uint8ArrayToObject<InternalMessage>(plainBytes);
    await _handleMessageType(messageDeserialized);

  }

  /// Handle routing of deserialized messages based on their type
  ///
  /// Supported message types:
  /// - service: control messages (missing requests, commands, etc.)
  /// - base: simple data messages
  /// - chunk: fragments of large messages
  ///
  /// After processing, triggers automatic missing message control
  Future<void> _handleMessageType(InternalMessage mess) async {
    final messageType = mess.type;

    // Register message ID arrival in control system (if available)
    final messageId = mess.message.getId();
    ermesMessageControlService?.idArrived(messageId);

    unawaited(storageMessageType.store(mess.message));

    // Service messages have special handling (control, missing, etc.)
    if (messageType == MessageValue.service) {
      final serviceMsg = mess.message.asService();
      if (serviceMsg != null) {
        _serviceMessageHandler.call(serviceMsg);
      }
      return;
    }

    // Handle data messages (base or chunk)
    _handleMessage(mess.message, messageType);

    // After processing message, check if missing messages need to be requested
    if (_callbackOnMessageProcessed != null) {
      await _callbackOnMessageProcessed();
    }
  }

  /// Secondary router for data messages (non-service)
  void _handleMessage(MessageType mess, MessageValue messageType) {
    if (messageType == MessageValue.base) {
      final dataMsg = mess.asData();
      if (dataMsg != null) {
        _handleBaseMessage(dataMsg);
      }
      return;
    }
    if (messageType == MessageValue.chunk) {
      final chunkMsg = mess.asChunk();
      if (chunkMsg != null) {
        _handleChunkMessage(chunkMsg);
      }
      return;
    }

    throw CoreException('Message type not found: $messageType');
  }

  /// Handle base messages (complete, non-fragmented)
  /// Adds them directly to buffer for user
  void _handleBaseMessage(MessageData mess) {
    _pushInNotReaded(mess.data);
  }

  /// Handle chunks of fragmented messages
  /// Assembles fragments progressively until completion
  void _handleChunkMessage(ChunkMessage mess) {
    var handler = _messageNotMerged[mess.refId];
    // If this is the first chunk of this message, create a new ChunkHandler
    if (handler == null) {
      handler = ChunkHandler(mess.refId, mess.roof);
      _messageNotMerged[mess.refId] = handler;
    }

    _addChunk(handler, mess);
  }

  /// Add a chunk to ChunkHandler and check if message is complete
  void _addChunk(ChunkHandler handler, ChunkMessage mess) {
    final buffer = handler.addChunk(mess);
    // If message has been completely assembled
    if (buffer != null) {
      _pushInNotReaded(buffer);
      // Remove handler from processing messages
      _messageNotMerged.remove(mess.refId);
    }
  }

  /// Add data to buffer of messages ready for user
  /// Automatically triggers callback if configured
  void _pushInNotReaded(TypeOfData data) {
    _messageNotReaded.push(data);
  }
}
