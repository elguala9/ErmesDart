import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'type_aliases.dart';

/// JsonConverter for Uint8List serialization (base64 encoding)
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => Uint8List.fromList(base64Decode(json));

  @override
  String toJson(Uint8List object) => base64Encode(object);
}

/// JSON converter interface
abstract class JsonConverter<T, S> {
  T fromJson(S json);
  S toJson(T object);
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
class MessageRoot {
  const MessageRoot({
    required this.messageSerialized,
    required this.integrityCheckValue,
  });

  /// Serialized message data
  final Uint8List messageSerialized;

  /// Integrity check value (can be String, int, or bool)
  final Object integrityCheckValue;

  MessageRoot copyWith({
    Uint8List? messageSerialized,
    Object? integrityCheckValue,
  }) =>
      MessageRoot(
        messageSerialized: messageSerialized ?? this.messageSerialized,
        integrityCheckValue: integrityCheckValue ?? this.integrityCheckValue,
      );

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRoot &&
          runtimeType == other.runtimeType &&
          messageSerialized == other.messageSerialized &&
          integrityCheckValue == other.integrityCheckValue;

  @override
  int get hashCode => Object.hash(messageSerialized, integrityCheckValue);

  @override
  String toString() =>
      'MessageRoot(messageSerialized: $messageSerialized, '
      'integrityCheckValue: $integrityCheckValue)';
}

/// Internal message wrapper with type information
@includeInBarrelFile
class InternalMessage {
  const InternalMessage({
    required this.message,
    required this.type,
  });

  /// The actual message content
  final MessageType message;

  /// Type of message
  final MessageValue type;

  InternalMessage copyWith({
    MessageType? message,
    MessageValue? type,
  }) =>
      InternalMessage(
        message: message ?? this.message,
        type: type ?? this.type,
      );

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InternalMessage &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          type == other.type;

  @override
  int get hashCode => Object.hash(message, type);

  @override
  String toString() =>
      'InternalMessage(message: $message, type: $type)';
}

/// Base data message
@includeInBarrelFile
class MessageData implements MessageWithId {
  const MessageData({
    required this.id,
    required this.data,
  });

  @override
  final int id;

  final Uint8List data;

  MessageData copyWith({
    int? id,
    Uint8List? data,
  }) =>
      MessageData(
        id: id ?? this.id,
        data: data ?? this.data,
      );

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data;

  @override
  int get hashCode => Object.hash(id, data);

  @override
  String toString() =>
      'MessageData(id: $id, data: $data)';
}

/// Generic message data with custom data type
@includeInBarrelFile
class MessageDataGeneric<T> {
  const MessageDataGeneric({
    required this.id,
    required this.data,
  });

  final int id;
  final T data;

  MessageDataGeneric<T> copyWith({
    int? id,
    T? data,
  }) =>
      MessageDataGeneric(
        id: id ?? this.id,
        data: data ?? this.data,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageDataGeneric<T> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data;

  @override
  int get hashCode => Object.hash(id, data);

  @override
  String toString() =>
      'MessageDataGeneric(id: $id, data: $data)';
}

/// Chunk message for large data transfers
@includeInBarrelFile
class ChunkMessage implements MessageWithId {
  const ChunkMessage({
    required this.id,
    required this.data,
    required this.refId,
    required this.index,
    required this.roof,
  });

  @override
  final int id;

  final Uint8List data;
  final String refId;
  final int index;
  final int roof;

  ChunkMessage copyWith({
    int? id,
    Uint8List? data,
    String? refId,
    int? index,
    int? roof,
  }) =>
      ChunkMessage(
        id: id ?? this.id,
        data: data ?? this.data,
        refId: refId ?? this.refId,
        index: index ?? this.index,
        roof: roof ?? this.roof,
      );

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChunkMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data &&
          refId == other.refId &&
          index == other.index &&
          roof == other.roof;

  @override
  int get hashCode => Object.hash(id, data, refId, index, roof);

  @override
  String toString() =>
      'ChunkMessage(id: $id, data: $data, refId: $refId, '
      'index: $index, roof: $roof)';
}

/// Generic chunk message with custom data type
@includeInBarrelFile
class ChunkMessageGeneric<T> {
  const ChunkMessageGeneric({
    required this.id,
    required this.data,
    required this.refId,
    required this.index,
    required this.roof,
  });

  final int id;
  final T data;
  final String refId;
  final int index;
  final int roof;

  ChunkMessageGeneric<T> copyWith({
    int? id,
    T? data,
    String? refId,
    int? index,
    int? roof,
  }) =>
      ChunkMessageGeneric(
        id: id ?? this.id,
        data: data ?? this.data,
        refId: refId ?? this.refId,
        index: index ?? this.index,
        roof: roof ?? this.roof,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChunkMessageGeneric<T> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data &&
          refId == other.refId &&
          index == other.index &&
          roof == other.roof;

  @override
  int get hashCode => Object.hash(id, data, refId, index, roof);

  @override
  String toString() =>
      'ChunkMessageGeneric(id: $id, data: $data, refId: $refId, '
      'index: $index, roof: $roof)';
}

/// Information about a chunk in a sequence
@includeInBarrelFile
class ChunkInfo {
  const ChunkInfo({
    required this.chunkId,
    this.index,
  });

  final int chunkId;
  final List<int>? index;

  ChunkInfo copyWith({
    int? chunkId,
    List<int>? index,
  }) =>
      ChunkInfo(
        chunkId: chunkId ?? this.chunkId,
        index: index ?? this.index,
      );

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChunkInfo &&
          runtimeType == other.runtimeType &&
          chunkId == other.chunkId &&
          index == other.index;

  @override
  int get hashCode => Object.hash(chunkId, index);

  @override
  String toString() =>
      'ChunkInfo(chunkId: $chunkId, index: $index)';
}

/// Service message for control and coordination
@includeInBarrelFile
class ServiceMessage implements MessageWithId {
  const ServiceMessage({
    required this.id,
    required this.reason,
    this.arrayChunkInfo,
    this.arrayId,
  });

  @override
  final int id;

  final String reason;
  final List<ChunkInfo>? arrayChunkInfo;
  final List<int>? arrayId;

  ServiceMessage copyWith({
    int? id,
    String? reason,
    List<ChunkInfo>? arrayChunkInfo,
    List<int>? arrayId,
  }) =>
      ServiceMessage(
        id: id ?? this.id,
        reason: reason ?? this.reason,
        arrayChunkInfo: arrayChunkInfo ?? this.arrayChunkInfo,
        arrayId: arrayId ?? this.arrayId,
      );

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reason == other.reason &&
          arrayChunkInfo == other.arrayChunkInfo &&
          arrayId == other.arrayId;

  @override
  int get hashCode =>
      Object.hash(id, reason, arrayChunkInfo, arrayId);

  @override
  String toString() =>
      'ServiceMessage(id: $id, reason: $reason, '
      'arrayChunkInfo: $arrayChunkInfo, arrayId: $arrayId)';
}

/// Union type for all possible message types
/// Using sealed class pattern for type-safe pattern matching
@includeInBarrelFile
sealed class MessageType {
  const MessageType();

  /// Base message data
  const factory MessageType.data(MessageData message) = _MessageTypeData;

  /// Chunk message
  const factory MessageType.chunk(ChunkMessage message) = _MessageTypeChunk;

  /// Service message
  const factory MessageType.service(ServiceMessage message) =
      _MessageTypeService;

  /// Get the message type value
  MessageValue getType() => switch (this) {
        _MessageTypeData() => MessageValue.base,
        _MessageTypeChunk() => MessageValue.chunk,
        _MessageTypeService() => MessageValue.service,
      };

  /// Get the message ID
  int getId() => switch (this) {
        _MessageTypeData(:final message) => message.id,
        _MessageTypeChunk(:final message) => message.id,
        _MessageTypeService(:final message) => message.id,
      };

  /// Get as MessageData if this is a data message
  MessageData? asData() => switch (this) {
        _MessageTypeData(:final message) => message,
        _ => null,
      };

  /// Get as ChunkMessage if this is a chunk message
  ChunkMessage? asChunk() => switch (this) {
        _MessageTypeChunk(:final message) => message,
        _ => null,
      };

  /// Get as ServiceMessage if this is a service message
  ServiceMessage? asService() => switch (this) {
        _MessageTypeService(:final message) => message,
        _ => null,
      };

  factory MessageType.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final message = json['message'] as Map<String, dynamic>;

    return switch (type) {
      'data' => MessageType.data(MessageData.fromJson(message)),
      'chunk' => MessageType.chunk(ChunkMessage.fromJson(message)),
      'service' => MessageType.service(ServiceMessage.fromJson(message)),
      _ => throw ArgumentError('Unknown message type: $type'),
    };
  }

  Map<String, dynamic> toJson() => switch (this) {
        _MessageTypeData(:final message) => {
          'type': 'data',
          'message': message.toJson(),
        },
        _MessageTypeChunk(:final message) => {
          'type': 'chunk',
          'message': message.toJson(),
        },
        _MessageTypeService(:final message) => {
          'type': 'service',
          'message': message.toJson(),
        },
      };
}

class _MessageTypeData extends MessageType {
  const _MessageTypeData(this.message);
  final MessageData message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MessageTypeData &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => 'MessageType.data($message)';
}

class _MessageTypeChunk extends MessageType {
  const _MessageTypeChunk(this.message);
  final ChunkMessage message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MessageTypeChunk &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => 'MessageType.chunk($message)';
}

class _MessageTypeService extends MessageType {
  const _MessageTypeService(this.message);
  final ServiceMessage message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MessageTypeService &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => 'MessageType.service($message)';
}

/// Callbacks structure for message reception
@includeInBarrelFile
class CallbackOnMessageReceived {
  const CallbackOnMessageReceived({
    required this.callbackOnMessage,
    required this.callbackOnData,
  });

  final CallbackOnMessage callbackOnMessage;
  final CallbackOnDataArrived callbackOnData;

  CallbackOnMessageReceived copyWith({
    CallbackOnMessage? callbackOnMessage,
    CallbackOnDataArrived? callbackOnData,
  }) =>
      CallbackOnMessageReceived(
        callbackOnMessage: callbackOnMessage ?? this.callbackOnMessage,
        callbackOnData: callbackOnData ?? this.callbackOnData,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallbackOnMessageReceived &&
          runtimeType == other.runtimeType &&
          callbackOnMessage == other.callbackOnMessage &&
          callbackOnData == other.callbackOnData;

  @override
  int get hashCode => Object.hash(callbackOnMessage, callbackOnData);

  @override
  String toString() =>
      'CallbackOnMessageReceived(callbackOnMessage: $callbackOnMessage, '
      'callbackOnData: $callbackOnData)';
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
