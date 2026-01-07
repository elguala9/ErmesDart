import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'type_aliases.dart';

part 'ermes_types.freezed.dart';
part 'ermes_types.g.dart';

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
      _$MessageRootFromJson(json);
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

  factory InternalMessage.fromJson(Map<String, dynamic> json) =>
      _$InternalMessageFromJson(json);
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

  factory MessageData.fromJson(Map<String, dynamic> json) =>
      _$MessageDataFromJson(json);
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

  factory ChunkMessage.fromJson(Map<String, dynamic> json) =>
      _$ChunkMessageFromJson(json);
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

  factory ChunkInfo.fromJson(Map<String, dynamic> json) =>
      _$ChunkInfoFromJson(json);
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

  factory ServiceMessage.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageFromJson(json);
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

  factory MessageType.fromJson(Map<String, dynamic> json) =>
      _$MessageTypeFromJson(json);
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
