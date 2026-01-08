import 'dart:async';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import '../ermes_utility/chunk_handler.dart';

// TODO: Find Dart equivalent for 'observable-list' package
// Temporary implementation of a simple observable list
@includeInBarrelFile
class ObservableList<T> {
  ObservableList([this._maxSize]);
  final List<T> _items = [];
  final int? _maxSize;
  void Function()? _onAdd;

  void onAdd(void Function() callback) {
    _onAdd = callback;
  }

  void push(T item) {
    if (_maxSize != null && _items.length >= _maxSize) {
      throw StateError('Buffer is full');
    }
    _items.add(item);
    _onAdd?.call();
  }

  T shift() {
    if (_items.isEmpty) {
      throw StateError('Buffer is empty');
    }
    return _items.removeAt(0);
  }

  bool isEmpty() => _items.isEmpty;
}

// TODO: Find Dart equivalent for 'serialization-utility' Hash functions
// Temporary placeholder for hash calculation
String calculateHashSync(Uint8List data) {
  // This should use a proper hash algorithm like SHA-256
  // For now, returning a placeholder
  return data.hashCode.toString();
}

// TODO: Find Dart equivalent for 'serialization-utility' Serialization functions
// Temporary placeholders for serialization
@includeInBarrelFile
T uint8ArrayToObject<T>(Uint8List data) {
  // This should deserialize Uint8List to object
  // Implementation depends on serialization format (JSON, MessagePack, etc.)
  throw UnimplementedError('uint8ArrayToObject needs implementation');
}

@includeInBarrelFile
Uint8List uint8ArrayToArrayBuffer(Uint8List data) => data;

/// Configuration options for ErmesReadRepo
@includeInBarrelFile
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
@includeInBarrelFile
class ErmesReadRepo {
  /// ErmesReadRepo constructor
  ///
  /// [repository] - Transport repository for communication
  /// [callbackServiceMessage] - Callback to handle service messages (control, missing requests, etc.)
  /// [ermesMessageControlService] - Service to track and manage missing messages (optional)
  /// [options] - Configuration options (buffer size, callbacks, etc.)
  ErmesReadRepo(
    this._repository,
    this._callbackServiceMessage,
    this.ermesMessageControlService,
    ErmesReadRepoOptions options,
  ) : _messageNotReaded = ObservableList<TypeOfData>(
        options.maxBufferSize ?? 100,
      ),
      _callbackOnDataArrived = options.callbackOnDataArrived,
      _callbackOnMessageProcessed = options.callbackOnMessageProcessed {
    // Register handler for incoming messages from transport repository
    _repository.onMessage(_handleMessageArrayBuffer);

    // Configure observer for messages added to buffer
    // When a message is added, it's immediately passed to user via callback
    _messageNotReaded.onAdd(() {
      if (_callbackOnDataArrived != null) {
        while (!_messageNotReaded.isEmpty()) {
          final data = _messageNotReaded.shift();
          _callbackOnDataArrived!(data);
        }
      }
    });
  }

  /// Observable buffer of messages ready to be read by user
  final ObservableList<TypeOfData> _messageNotReaded;

  /// Map of chunks not yet completely assembled (chunk_id -> ChunkHandler)
  final Map<IdChunkType, ChunkHandler> _messageNotMerged = {};

  /// Transport repository for network communication
  final IErmesRepository _repository;

  /// Callback to handle service messages
  CallbackServiceMessage _callbackServiceMessage;

  /// Callback called when data is ready for user
  CallbackOnDataArrived? _callbackOnDataArrived;

  /// Callback called after processing each message (for missing checks)
  final Future<void> Function()? _callbackOnMessageProcessed;

  /// Service for missing message control
  final IErmesMessageControlService? ermesMessageControlService;

  /// Set callback for service messages
  void setCallbackServiceMessage(
    CallbackServiceMessage callbackServiceMessage,
  ) {
    _callbackServiceMessage = callbackServiceMessage;
  }

  /// Set callback for incoming data
  void setMessageDataCallback(CallbackOnDataArrived callback) {
    _callbackOnDataArrived = callback;
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
    try {
      // Basic validation: verify message is not empty or corrupted
      if (message.isEmpty) {
        // ignore: avoid_print
        print('Received empty or invalid message');
        return;
      }

      // Deserialize outer message structure (contains hash + serialized data)
      final messRoot = uint8ArrayToObject<MessageRoot>(message);
      final dataArrayBuffer = uint8ArrayToArrayBuffer(
        messRoot.messageSerialized,
      );

      // Verify message integrity via hash
      if (messRoot.integrityCheckValue != calculateHashSync(dataArrayBuffer)) {
        throw Exception('Hash mismatch not implemented.');
      }

      // Deserialize actual internal message
      final messageDeserialized = uint8ArrayToObject<InternalMessage>(
        messRoot.messageSerialized,
      );
      await _handleMessageType(messageDeserialized);
    } catch (error) {
      // ignore: avoid_print
      print('Error processing message: $error');
      // Don't rethrow error to avoid system crash
    }
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
    final messageId = mess.message.when(
      data: (m) => m.id,
      chunk: (m) => m.id,
      service: (m) => m.id,
    );
    ermesMessageControlService?.idArrived(messageId);

    // Service messages have special handling (control, missing, etc.)
    if (messageType == MessageValue.service) {
      mess.message.when(
        data: (_) {},
        chunk: (_) {},
        service: (serviceMsg) => _callbackServiceMessage(serviceMsg),
      );
      return;
    }

    // Handle data messages (base or chunk)
    _handleMessage(mess.message, messageType);

    // After processing message, check if missing messages need to be requested
    if (_callbackOnMessageProcessed != null) {
      try {
        await _callbackOnMessageProcessed();
      } catch (error) {
        // ignore: avoid_print
        print('Error in callbackOnMessageProcessed: $error');
      }
    }
  }

  /// Secondary router for data messages (non-service)
  void _handleMessage(MessageType mess, MessageValue messageType) {
    if (messageType == MessageValue.base) {
      mess.when(data: _handleBaseMessage, chunk: (_) {}, service: (_) {});
      return;
    }
    if (messageType == MessageValue.chunk) {
      mess.when(data: (_) {}, chunk: _handleChunkMessage, service: (_) {});
      return;
    }

    throw Exception('Message type not found: $messageType');
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
