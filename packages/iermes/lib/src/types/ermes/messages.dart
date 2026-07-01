import 'dart:typed_data';


import 'package:json_annotation/json_annotation.dart';

import '../converters/converters.dart';
import 'message_enums.dart';
import 'message_type.dart';

part 'messages.g.dart';

// Helper functions for Uint8List JSON conversion
/// Decodes a base64 string into raw bytes for JSON deserialization.
Uint8List _uint8ListFromJson(String json) =>
    const Uint8ListConverter().fromJson(json);

/// Encodes raw bytes into a base64 string for JSON serialization.
String _uint8ListToJson(Uint8List data) =>
    const Uint8ListConverter().toJson(data);

/// Base data message
@JsonSerializable()
class MessageData implements MessageWithId, IErmesSerializable {
  /// Creates a data message with its id and raw payload.
  const MessageData({
    required this.id,
    required this.data,
  });

  /// Builds a [MessageData] from its JSON representation.
  factory MessageData.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$MessageDataFromJson(json);

  /// Unique message identifier.
  @override
  final int id;

  /// Raw payload bytes carried by the message.
  @JsonKey(
    fromJson: _uint8ListFromJson,
    toJson: _uint8ListToJson,
  )
  final Uint8List data;

  /// Returns a copy of this message with the given fields replaced.
  MessageData copyWith({
    int? id,
    Uint8List? data,
  }) =>
      MessageData(
        id: id ?? this.id,
        data: data ?? this.data,
      );

  /// Serializes this message to its JSON representation.
  @override
  Map<String, dynamic> toJson() => _$MessageDataToJson(this);

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
class MessageDataGeneric<T> {
  /// Creates a generic data message with its id and typed payload.
  const MessageDataGeneric({
    required this.id,
    required this.data,
  });

  /// Unique message identifier.
  final int id;
  /// Typed payload carried by the message.
  final T data;

  /// Returns a copy of this message with the given fields replaced.
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
@JsonSerializable()
class ChunkMessage implements MessageWithId, IErmesSerializable {
  /// Creates a chunk belonging to a larger fragmented message.
  const ChunkMessage({
    required this.id,
    required this.data,
    required this.refId,
    required this.index,
    required this.roof,
  });

  /// Builds a [ChunkMessage] from its JSON representation.
  factory ChunkMessage.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ChunkMessageFromJson(json);

  /// Unique message identifier.
  @override
  final int id;

  /// Raw payload bytes for this chunk.
  @JsonKey(
    fromJson: _uint8ListFromJson,
    toJson: _uint8ListToJson,
  )
  final Uint8List data;
  /// Reference id linking all chunks of the same original message.
  final String refId;
  /// Position of this chunk within the sequence.
  final int index;
  /// Total number of chunks in the sequence.
  final int roof;

  /// Returns a copy of this chunk with the given fields replaced.
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

  /// Serializes this chunk to its JSON representation.
  @override
  Map<String, dynamic> toJson() => _$ChunkMessageToJson(this);

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
class ChunkMessageGeneric<T> {
  /// Creates a generic chunk with a typed payload.
  const ChunkMessageGeneric({
    required this.id,
    required this.data,
    required this.refId,
    required this.index,
    required this.roof,
  });

  /// Unique message identifier.
  final int id;
  /// Typed payload for this chunk.
  final T data;
  /// Reference id linking all chunks of the same original message.
  final String refId;
  /// Position of this chunk within the sequence.
  final int index;
  /// Total number of chunks in the sequence.
  final int roof;

  /// Returns a copy of this chunk with the given fields replaced.
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
@JsonSerializable()
class ChunkInfo implements IErmesSerializable {
  /// Creates chunk metadata identifying a chunk and its received indexes.
  const ChunkInfo({
    required this.chunkId,
    this.index,
  });

  /// Builds a [ChunkInfo] from its JSON representation.
  factory ChunkInfo.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ChunkInfoFromJson(json);

  /// Identifier of the chunk sequence.
  final int chunkId;
  /// Indexes of the chunks referenced, when applicable.
  final List<int>? index;

  /// Returns a copy of this chunk info with the given fields replaced.
  ChunkInfo copyWith({
    int? chunkId,
    List<int>? index,
  }) =>
      ChunkInfo(
        chunkId: chunkId ?? this.chunkId,
        index: index ?? this.index,
      );

  /// Serializes this chunk info to its JSON representation.
  @override
  Map<String, dynamic> toJson() => _$ChunkInfoToJson(this);

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

/// Internal message wrapper with type information
class InternalMessage implements IErmesSerializable {
  /// Creates an internal wrapper pairing a message with its type tag.
  const InternalMessage({
    required this.message,
    required this.type,
  });

  /// Builds an [InternalMessage] from its JSON representation.
  // MANUAL SERIALIZATION: Sealed MessageType dispatch
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

  /// The actual message content
  final MessageType message;

  /// Type of message
  final MessageValue type;

  /// Returns a copy of this wrapper with the given fields replaced.
  InternalMessage copyWith({
    MessageType? message,
    MessageValue? type,
  }) =>
      InternalMessage(
        message: message ?? this.message,
        type: type ?? this.type,
      );

  /// Serializes this wrapper to its JSON representation.
  // MANUAL SERIALIZATION: Sealed MessageType dispatch
  @override
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
