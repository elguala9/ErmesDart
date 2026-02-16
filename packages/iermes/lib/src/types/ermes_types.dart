import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'type_aliases.dart';

part 'ermes_types.freezed.dart';

/// JsonConverter for Uint8List serialization (base64 encoding)
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => Uint8List.fromList(base64Decode(json));

  @override
  String toJson(Uint8List object) => base64Encode(object);
}

/// Maximum header size in bytes
const int maxHeader = 81; // 24 bytes for ChunkMessage

/// Enum defining the type of message:
/// - base: Base message
/// - chunk: Chunk message (for large data split into pieces)
/// - service: Service message (control messages)
@includeInBarrelFile
enum MessageValue {
  /// Base message type
  base,

  /// Chunk message type (for large data)
  chunk,

  /// Service message type (control/metadata)
  service,
}

/// Service reason codes as constants
@includeInBarrelFile
class ServiceReasons {
  /// Completed
  static const String completed = 'c';

  /// Send again (retry)
  static const String sendAgain = 's';

  /// Closing connection
  static const String closing = 'x';
}

/// Base interface for messages with ID
@includeInBarrelFile
abstract class MessageWithId {
  /// Unique message identifier
  int get id;
}

/// Root message structure containing serialized data and integrity check
@includeInBarrelFile
@freezed
class MessageRoot with _$MessageRoot {
  const factory MessageRoot({
    /// Serialized message data
    @Uint8ListConverter() required Uint8List messageSerialized,

    /// Integrity check value (can be String, int, or bool)
    required Object integrityCheckValue,
  }) = _MessageRoot;

  factory MessageRoot.fromJson(Map<String, dynamic> json) =>
      MessageRoot(
        messageSerialized: const Uint8ListConverter()
            .fromJson(json['messageSerialized'] as String),
        integrityCheckValue:
            json['integrityCheckValue'] as Object,
      );

  Map<String, dynamic> toJson() => {
        'messageSerialized':
            const Uint8ListConverter()
                .toJson(messageSerialized),
        'integrityCheckValue': integrityCheckValue,
      };
}

/// Internal message wrapper with type information
@includeInBarrelFile
@freezed
class InternalMessage with _$InternalMessage {
  const factory InternalMessage({
    /// The actual message content
    required MessageType message,

    /// Type of message
    required MessageValue type,
  }) = _InternalMessage;

  factory InternalMessage.fromJson(
    Map<String, dynamic> json,
  ) =>
      InternalMessage(
        message: MessageType.fromJson(
          json['message'] as Map<String, dynamic>,
        ),
        type: MessageValue.values
            .byName(json['type'] as String),
      );

  Map<String, dynamic> toJson() => {
        'message': message.toJson(),
        'type': type.name,
      };
}

/// Base data message
@includeInBarrelFile
@freezed
class MessageData with _$MessageData implements MessageWithId {
  const factory MessageData({
    /// Unique message identifier
    required int id,

    /// Message payload data
    @Uint8ListConverter() required Uint8List data,
  }) = _MessageData;

  factory MessageData.fromJson(
    Map<String, dynamic> json,
  ) =>
      MessageData(
        id: (json['id'] as num).toInt(),
        data: const Uint8ListConverter()
            .fromJson(json['data'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': const Uint8ListConverter().toJson(data),
      };
}

/// Generic message data with custom data type
@includeInBarrelFile
@Freezed(toJson: false, fromJson: false)
class MessageDataGeneric<T> with _$MessageDataGeneric<T> {
  const factory MessageDataGeneric({
    /// Unique message identifier
    required int id,

    /// Message payload data
    required T data,
  }) = _MessageDataGeneric<T>;
}

/// Chunk message for large data transfers
@includeInBarrelFile
@freezed
class ChunkMessage with _$ChunkMessage implements MessageWithId {
  const factory ChunkMessage({
    /// Unique message identifier
    required int id,

    /// Message payload data
    @Uint8ListConverter() required Uint8List data,

    /// Reference ID linking all chunks of the same message
    required String refId,

    /// Index of this chunk in the sequence
    required int index,

    /// Total number of chunks (roof)
    required int roof,
  }) = _ChunkMessage;

  factory ChunkMessage.fromJson(
    Map<String, dynamic> json,
  ) =>
      ChunkMessage(
        id: (json['id'] as num).toInt(),
        data: const Uint8ListConverter()
            .fromJson(json['data'] as String),
        refId: json['refId'] as String,
        index: (json['index'] as num).toInt(),
        roof: (json['roof'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': const Uint8ListConverter().toJson(data),
        'refId': refId,
        'index': index,
        'roof': roof,
      };
}

/// Generic chunk message with custom data type
@includeInBarrelFile
@Freezed(toJson: false, fromJson: false)
class ChunkMessageGeneric<T> with _$ChunkMessageGeneric<T> {
  const factory ChunkMessageGeneric({
    /// Unique message identifier
    required int id,

    /// Message payload data
    required T data,

    /// Reference ID linking all chunks
    required String refId,

    /// Index of this chunk
    required int index,

    /// Total number of chunks
    required int roof,
  }) = _ChunkMessageGeneric<T>;
}

/// Information about a chunk in a sequence
@includeInBarrelFile
@freezed
class ChunkInfo with _$ChunkInfo {
  const factory ChunkInfo({
    /// Chunk identifier
    required int chunkId,

    /// Optional array of indices for this chunk
    List<int>? index,
  }) = _ChunkInfo;

  factory ChunkInfo.fromJson(
    Map<String, dynamic> json,
  ) =>
      ChunkInfo(
        chunkId: (json['chunkId'] as num).toInt(),
        index: (json['index'] as List<dynamic>?)
            ?.cast<num>()
            .map((n) => n.toInt())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'chunkId': chunkId,
        if (index != null) 'index': index,
      };
}

/// Service message for control and coordination
@includeInBarrelFile
@freezed
class ServiceMessage with _$ServiceMessage implements MessageWithId {
  const factory ServiceMessage({
    /// Unique message identifier
    required int id,

    /// Reason/command code ('c', 's', or 'x')
    required String reason,

    /// Optional array of chunk information
    List<ChunkInfo>? arrayChunkInfo,

    /// Optional array of message IDs
    List<int>? arrayId,
  }) = _ServiceMessage;

  factory ServiceMessage.fromJson(
    Map<String, dynamic> json,
  ) =>
      ServiceMessage(
        id: (json['id'] as num).toInt(),
        reason: json['reason'] as String,
        arrayChunkInfo:
            (json['arrayChunkInfo'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(ChunkInfo.fromJson)
                .toList(),
        arrayId: (json['arrayId'] as List<dynamic>?)
            ?.cast<num>()
            .map((n) => n.toInt())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': reason,
        if (arrayChunkInfo != null)
          'arrayChunkInfo': arrayChunkInfo!
              .map((c) => c.toJson())
              .toList(),
        if (arrayId != null) 'arrayId': arrayId,
      };
}

/// Union type for all possible message types
@includeInBarrelFile
@freezed
class MessageType with _$MessageType {
  /// Base message data
  const factory MessageType.data(MessageData message) = MessageTypeData;

  /// Chunk message
  const factory MessageType.chunk(ChunkMessage message) = MessageTypeChunk;

  /// Service message
  const factory MessageType.service(ServiceMessage message) =
      MessageTypeService;

  factory MessageType.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final message = json['message'] as Map<String, dynamic>;

    if (type == 'data') {
      return MessageType.data(MessageData.fromJson(message));
    } else if (type == 'chunk') {
      return MessageType.chunk(ChunkMessage.fromJson(message));
    } else if (type == 'service') {
      return MessageType.service(ServiceMessage.fromJson(message));
    } else {
      throw ArgumentError('Unknown message type: $type');
    }
  }

  Map<String, dynamic> toJson() => when(
        data: (message) => {
          'type': 'data',
          'message': message.toJson(),
        },
        chunk: (message) => {
          'type': 'chunk',
          'message': message.toJson(),
        },
        service: (message) => {
          'type': 'service',
          'message': message.toJson(),
        },
      );

}

/// Callbacks structure for message reception
@includeInBarrelFile
@Freezed(toJson: false, fromJson: false)
class CallbackOnMessageReceived with _$CallbackOnMessageReceived {
  const factory CallbackOnMessageReceived({
    /// Callback for when a message is received
    required CallbackOnMessage callbackOnMessage,

    /// Callback for when data arrives
    required CallbackOnDataArrived callbackOnData,
  }) = _CallbackOnMessageReceived;
}

// Type aliases for Ermes-specific message types

/// Root message type for Ermes with String integrity check
@includeInBarrelFile
typedef MessageRootErmes = MessageRoot;

/// Data message type for Ermes
@includeInBarrelFile
typedef MessageDataErmes = MessageData;

/// Internal message type for Ermes
@includeInBarrelFile
typedef MessageInternalErmes = InternalMessage;

/// Chunk message type for Ermes
@includeInBarrelFile
typedef MessageChunkErmes = ChunkMessage;
