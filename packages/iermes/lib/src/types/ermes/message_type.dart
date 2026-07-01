

import '../service/service_messages.dart';
import '../storage_types.dart';
import 'message_enums.dart';
import 'messages.dart';

/// Union type for all possible message types
/// Using sealed class pattern for type-safe pattern matching
sealed class MessageType implements IErmesSerializable, StorageType {
  /// Const base constructor for sealed subtypes.
  const MessageType();

  /// Builds the matching [MessageType] subtype from JSON by its `type` tag.
  // MANUAL SERIALIZATION: Sealed class dispatch
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

  /// Message id delegated to the wrapped message.
  @override
  int get id => getId();

  /// JSON view of this message, equivalent to [toJson].
  @override
  Map<String, dynamic> get json => toJson();

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

  /// Serializes the wrapped message to JSON, tagging it with its type.
  // MANUAL SERIALIZATION: Sealed class dispatch
  @override
  Map<String, dynamic> toJson({bool includePrivate = false}) => switch (this) {
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

/// Concrete [MessageType] variant wrapping a [MessageData].
class _MessageTypeData extends MessageType {
  const _MessageTypeData(this.message);
  /// The wrapped data message.
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

/// Concrete [MessageType] variant wrapping a [ChunkMessage].
class _MessageTypeChunk extends MessageType {
  const _MessageTypeChunk(this.message);
  /// The wrapped chunk message.
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

/// Concrete [MessageType] variant wrapping a [ServiceMessage].
class _MessageTypeService extends MessageType {
  const _MessageTypeService(this.message);
  /// The wrapped service message.
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
