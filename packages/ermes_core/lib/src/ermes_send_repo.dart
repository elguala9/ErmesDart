import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:iermes/iermes.dart';
import 'package:uuid/uuid.dart';

import 'ermes_utility/hash_utils.dart';
import 'utility.dart';

// TODO: Find Dart equivalent for 'serialization-utility' functions
// Temporary placeholders for serialization
@includeInBarrelFile
Uint8List objectToUint8Array(Object obj) {
  late Map<String, dynamic> json;

  // Serialize object to JSON map based on its type
  if (obj is MessageRoot) {
    json = obj.toJson();
  } else if (obj is InternalMessage) {
    json = obj.toJson();
  } else if (obj is MessageData) {
    json = obj.toJson();
  } else if (obj is ChunkMessage) {
    json = obj.toJson();
  } else if (obj is ServiceMessage) {
    json = obj.toJson();
  } else if (obj is MessageType) {
    json = obj.toJson();
  } else {
    throw ArgumentError(
      'Unsupported type for serialization: ${obj.runtimeType}',
    );
  }

  // Convert JSON map to string, then to UTF-8 encoded bytes
  final jsonString = jsonEncode(json);
  return Uint8List.fromList(utf8.encode(jsonString));
}

@includeInBarrelFile
Uint8List uint8ArrayToArrayBuffer(Uint8List data) => data;

/// ErmesSendRepo - Handles message sending and serialization
///
/// Main responsibilities:
/// - Serialization of user data into Ermes messages
/// - Automatic fragmentation for large messages
/// - Calculation and addition of integrity hash
/// - Management of unique IDs via IdHandler
/// - Sending via transport repository
/// - Callbacks to notify user of sending
@includeInBarrelFile
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
  }

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

  /// Backward compatibility getter (kept for now, but legacy code should migrate)
  CallbackOnMessageSending? get callbackOnDataSending => null;

  /// Backward compatibility setter (kept for now, but legacy code should migrate)
  set callbackOnDataSending(CallbackOnMessageSending callback) {
    addOnMessageSendingListener(callback);
  }

  /// Backward compatibility getter (kept for now, but legacy code should migrate)
  CallbackOnMessageSent? get callbackOnDataSended => null;

  /// Backward compatibility setter (kept for now, but legacy code should migrate)
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
  /// Serialization process:
  /// 1. Create InternalMessage with type and content
  /// 2. Serialize to Uint8List
  /// 3. Calculate integrity hash
  /// 4. Create MessageRoot with hash and data
  /// 5. Serialize root and send
  void sendMessageType(List<MessageType> array) {
    for (final element in array) {
      // Create internal message with automatically determined type
      final internalMessage = InternalMessage(
        message: element,
        type: getMessageType(element),
      );

      // Serialize internal message
      final rawData = objectToUint8Array(internalMessage);
      final rawDataArrayBuffer = uint8ArrayToArrayBuffer(rawData);

      // Notify all pre-send listeners (if not already done in send())
      _onMessageSendingHandler.call(element);

      // Create root message with integrity hash
      final messageRoot = MessageRoot(
        messageSerialized: rawData,
        integrityCheckValue: calculateHashSync(rawDataArrayBuffer),
      );

      // Send serialized root message
      _sendRootMessage(messageRoot);

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
    // NOTE: In future implement message tracking and confirmations
  }
}
