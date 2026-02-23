import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../converters/converters.dart';
import 'message_enums.dart';
import 'message_type.dart';

part 'messages.g.dart';

// Helper functions for Uint8List JSON conversion
Uint8List _uint8ListFromJson(String json) =>
    const Uint8ListConverter().fromJson(json);

String _uint8ListToJson(Uint8List data) =>
    const Uint8ListConverter().toJson(data);

/// Base data message
@includeInBarrelFile
@JsonSerializable()
class MessageData implements MessageWithId, IErmesSerializable {
  const MessageData({
    required this.id,
    required this.data,
  });

  factory MessageData.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$MessageDataFromJson(json);

  @override
  final int id;

  @JsonKey(
    fromJson: _uint8ListFromJson,
    toJson: _uint8ListToJson,
  )
  final Uint8List data;

  MessageData copyWith({
    int? id,
    Uint8List? data,
  }) =>
      MessageData(
        id: id ?? this.id,
        data: data ?? this.data,
      );

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
@JsonSerializable()
class ChunkMessage implements MessageWithId, IErmesSerializable {
  const ChunkMessage({
    required this.id,
    required this.data,
    required this.refId,
    required this.index,
    required this.roof,
  });

  factory ChunkMessage.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ChunkMessageFromJson(json);

  @override
  final int id;

  @JsonKey(
    fromJson: _uint8ListFromJson,
    toJson: _uint8ListToJson,
  )
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
@JsonSerializable()
class ChunkInfo implements IErmesSerializable {
  const ChunkInfo({
    required this.chunkId,
    this.index,
  });

  factory ChunkInfo.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ChunkInfoFromJson(json);

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
@includeInBarrelFile
class InternalMessage implements IErmesSerializable {
  const InternalMessage({
    required this.message,
    required this.type,
  });

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

  InternalMessage copyWith({
    MessageType? message,
    MessageValue? type,
  }) =>
      InternalMessage(
        message: message ?? this.message,
        type: type ?? this.type,
      );

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
