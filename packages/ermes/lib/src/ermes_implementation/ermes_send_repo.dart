import 'dart:typed_data';

import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';
import 'package:uuid/uuid.dart';

import '../utility.dart';

// TODO: Find Dart equivalent for 'serialization-utility' functions
// Temporary placeholders for serialization
Uint8List objectToUint8Array(Object obj) {
  // This should serialize object to Uint8List
  // Implementation depends on serialization format (JSON, MessagePack, etc.)
  throw UnimplementedError('objectToUint8Array needs implementation');
}

Uint8List uint8ArrayToArrayBuffer(Uint8List data) => data;

String calculateHashSync(Uint8List data) {
  // This should use a proper hash algorithm like SHA-256
  return data.hashCode.toString();
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
  ErmesSendRepo(
    this._repository,
    this._idHandler, [
    int maxByte = 1024,
  ]) : _maxByte = maxByte + maxHeader {
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

  /// Callback called before sending (for storage/caching)
  CallbackOnMessageSending? _callbackOnMessageSending;

  /// Callback called after sending
  CallbackOnMessageSent? _callbackOnMessageSended;

  /// UUID generator for chunk reference IDs
  final Uuid _uuid = const Uuid();

  /// Set callback called before sending a message
  /// Used mainly for storage/caching
  void setCallbackOnDataSending(CallbackOnMessageSending callback) {
    _callbackOnMessageSending = callback;
  }

  /// Set callback called after sending a message
  void setCallbackOnDataSended(CallbackOnMessageSent callback) {
    _callbackOnMessageSended = callback;
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

      // Notify callback for each chunk (for storage/caching)
      if (_callbackOnMessageSending != null) {
        for (final chunk in rawDataArray) {
          _callbackOnMessageSending!(MessageType.chunk(chunk));
        }
      }

      sendMessageType(rawDataArray.map(MessageType.chunk).toList());
      return;
    }

    // Small message: direct sending without fragmentation
    final newId = _idHandler.getNewId();
    final message = createMessageDataErmes(rawData, newId);

    // Notify callback before sending (for storage/caching)
    if (_callbackOnMessageSending != null) {
      _callbackOnMessageSending!(MessageType.data(message));
    }

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

      // Notify pre-send callback (if not already done in send())
      if (_callbackOnMessageSending != null) {
        _callbackOnMessageSending!(element);
      }

      // Create root message with integrity hash
      final messageRoot = MessageRoot(
        messageSerialized: rawData,
        integrityCheckValue: calculateHashSync(rawDataArrayBuffer),
      );

      // Send serialized root message
      _sendRootMessage(messageRoot);

      // Notify post-send callback
      if (_callbackOnMessageSended != null) {
        _callbackOnMessageSended!(element);
      }
    }
  }

  /// Serialize and send a MessageRoot via transport repository
  void _sendRootMessage(MessageRoot message) {
    final rawData = objectToUint8Array(message);
    _sendWithRepo(rawData);
  }

  /// Actual sending via transport repository
  ///
  /// Interface point with transport layer (WebRTC, WebSocket, etc.)
  /// Future: implement retry logic and reception confirmations
  void _sendWithRepo(SerializableDataType dataRaw) {
    _repository.send(dataRaw);

    // For now we assume sending is always successful
    // In a real implementation, should wait for confirmation
    // NOTE: In future implement message tracking and confirmations
  }
}
