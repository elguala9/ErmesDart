import 'dart:convert';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:convert/convert.dart';
import 'package:cryptdart/types/crypto_algorithm.dart';
import 'package:crypto/crypto.dart';
import 'package:shsp_types/shsp_types.dart';

import 'storage_types.dart';
import 'type_aliases.dart';

// TO DO: Serializaion utility?
@includeInBarrelFile
class ErmesPeerInfo extends PeerInfo {
  ErmesPeerInfo({required super.address, required super.port, this.id});
  String? id;
}

/// JsonConverter for Uint8List serialization (base64 encoding)
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => Uint8List.fromList(base64Decode(json));

  @override
  String toJson(Uint8List object) => base64Encode(object);
}

/// JsonConverter for Digest serialization (hex encoding)
class DigestConverter implements JsonConverter<Digest?, String?> {
  const DigestConverter();

  @override
  Digest? fromJson(String? json) =>
      json != null ? Digest(hex.decode(json)) : null;

  @override
  String? toJson(Digest? object) =>
      object != null ? hex.encode(object.bytes) : null;
}

/// JSON converter interface
abstract class JsonConverter<T, S> {
  T fromJson(S json);
  S toJson(T object);
}

/// Interface for Ermes types that can be serialized to JSON
///
/// All root message types (MessageRoot, InternalMessage, etc.) should
/// implement this interface to enable polymorphic serialization via
/// the registry pattern.
@includeInBarrelFile
// ignore: one_member_abstracts
abstract interface class IErmesSerializable {
  /// Serialize this object to JSON
  Map<String, dynamic> toJson();
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

  /// Is sending a new key to use
  static const String newKey = 'k';

  /// Acknowledge
  static const String acknowledge = 'a';
}

/// Base interface for messages with ID
@includeInBarrelFile
abstract class MessageWithId {
  /// Unique message identifier
  int get id;
}

/// Root message structure containing serialized data and integrity check
@includeInBarrelFile
class MessageRoot implements IErmesSerializable {
  const MessageRoot({
    required this.messageSerialized,
    required this.integrityCheckValue,
    this.digest,
    this.messageJson,
  });

  factory MessageRoot.fromJson(Map<String, dynamic> json) {
    final version = json['v'] as int? ?? 1;

    if (version == 2) {
      // Protocol v2: plaintext has nested JSON, encrypted has base64
      if (json.containsKey('message')) {
        // Plaintext message with nested JSON
        return MessageRoot(
          messageJson: json['message'] as Map<String, dynamic>,
          messageSerialized: Uint8List(0), // Empty for plaintext
          integrityCheckValue: json['integrityCheckValue'] as Object,
        );
      } else {
        // Encrypted message with base64 serialized data
        return MessageRoot(
          messageSerialized: const Uint8ListConverter()
              .fromJson(json['messageSerialized'] as String),
          integrityCheckValue: json['integrityCheckValue'] as Object,
          digest: json['digest'] != null
              ? Digest(hex.decode(json['digest'] as String))
              : null,
        );
      }
    } else {
      // Legacy v1: backward compatibility
      return MessageRoot(
        messageSerialized: const Uint8ListConverter()
            .fromJson(json['messageSerialized'] as String),
        integrityCheckValue: json['integrityCheckValue'] as Object,
        digest: json['digest'] != null
            ? Digest(hex.decode(json['digest'] as String))
            : null,
      );
    }
  }

  /// Protocol version number
  static const int _version = 2;

  /// Serialized message data (for encrypted or v1 plaintext)
  final Uint8List messageSerialized;

  /// Message as nested JSON (for v2 plaintext)
  final Map<String, dynamic>? messageJson;

  /// Integrity check value (should be String)
  final Object integrityCheckValue;

  /// Digest of the message (key) - only present for encrypted messages
  final Digest? digest;

  MessageRoot copyWith({
    Uint8List? messageSerialized,
    Map<String, dynamic>? messageJson,
    Object? integrityCheckValue,
    Digest? digest,
  }) =>
      MessageRoot(
        messageSerialized: messageSerialized ?? this.messageSerialized,
        messageJson: messageJson ?? this.messageJson,
        integrityCheckValue: integrityCheckValue ?? this.integrityCheckValue,
        digest: digest ?? this.digest,
      );

  @override
  Map<String, dynamic> toJson() {
    // Plaintext message with nested JSON (v2)
    if (messageJson != null && digest == null) {
      return {
        'v': _version,
        'message': messageJson,
        'integrityCheckValue': integrityCheckValue,
      };
    }

    // Encrypted message (v2 or v1 compatible)
    return {
      'v': _version,
      'messageSerialized': const Uint8ListConverter().toJson(messageSerialized),
      'integrityCheckValue': integrityCheckValue,
      if (digest != null) 'digest': hex.encode(digest!.bytes),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRoot &&
          runtimeType == other.runtimeType &&
          messageSerialized == other.messageSerialized &&
          messageJson == other.messageJson &&
          integrityCheckValue == other.integrityCheckValue &&
          digest == other.digest;

  @override
  int get hashCode =>
      Object.hash(messageSerialized, messageJson, integrityCheckValue, digest);

  @override
  String toString() =>
      'MessageRoot(messageSerialized: $messageSerialized, '
      'messageJson: $messageJson, integrityCheckValue: $integrityCheckValue, '
      'digest: $digest)';
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

/// Base data message
@includeInBarrelFile
class MessageData implements MessageWithId, IErmesSerializable {
  const MessageData({
    required this.id,
    required this.data,
  });

  factory MessageData.fromJson(
    Map<String, dynamic> json,
  ) =>
      MessageData(
        id: (json['id'] as num).toInt(),
        data: const Uint8ListConverter()
            .fromJson(json['data'] as String),
      );

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

  @override
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
      ChunkMessage(
        id: (json['id'] as num).toInt(),
        data: const Uint8ListConverter()
            .fromJson(json['data'] as String),
        refId: json['refId'] as String,
        index: (json['index'] as num).toInt(),
        roof: (json['roof'] as num).toInt(),
      );

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

  @override
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
class ChunkInfo implements IErmesSerializable {
  const ChunkInfo({
    required this.chunkId,
    this.index,
  });

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
/// Uses sealed class pattern for type-safe message handling by reason
@includeInBarrelFile
sealed class ServiceMessage implements MessageWithId, IErmesSerializable {
  const ServiceMessage({required this.id});

  factory ServiceMessage.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final reason = json['reason'] as String;

    switch (reason) {
      case 'x':
        return ServiceMessageConnectionClose(id: id);
      case 'c':
        return ServiceMessageControl(id: id);
      case 'a':
        return ServiceMessageAcknowledge(
          id: id,
          ackCurrentId: (json['ackCurrentId'] as num?)?.toInt(),
          ackLastReceivedId: (json['ackLastReceivedId'] as num?)?.toInt(),
        );
      case 'newkey':
        return ServiceMessageNewKey(
          id: id,
          algorithm: json['algorithm'] as CryptoAlgorithm,
          key: json['key'] as String,
          start: json['start'] != null
              ? DateTime.parse(json['start'] as String)
              : null,
          expiration: json['expiration'] != null
              ? DateTime.parse(json['expiration'] as String)
              : null,
          startMessage: (json['startMessage'] as num?)?.toInt(),
          endMessage: (json['endMessage'] as num?)?.toInt(),
        );
      default:
        if (json['arrayId'] != null) {
          return ServiceMessageArrayRequest(
            id: id,
            arrayId: (json['arrayId'] as List<dynamic>)
                .cast<num>()
                .map((n) => n.toInt())
                .toList(),
          );
        }
        throw ArgumentError('Unknown service message reason: $reason');
    }
  }

  @override
  final int id;

  @override
  Map<String, dynamic> toJson();
}

/// Connection close request (reason: 'x')
@includeInBarrelFile
final class ServiceMessageConnectionClose extends ServiceMessage {
  const ServiceMessageConnectionClose({required super.id});

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': 'x',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageConnectionClose && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceMessageConnectionClose(id: $id)';
}

/// Control command (reason: 'c')
@includeInBarrelFile
final class ServiceMessageControl extends ServiceMessage {
  const ServiceMessageControl({required super.id});

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': 'c',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageControl && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceMessageControl(id: $id)';
}

/// Acknowledge message (reason: 'a')
/// Contains ID tracking information for synchronization
@includeInBarrelFile
final class ServiceMessageAcknowledge extends ServiceMessage {
  const ServiceMessageAcknowledge({
    required super.id,
    this.ackCurrentId,
    this.ackLastReceivedId,
  });

  /// My current outgoing message ID counter (after this message)
  final int? ackCurrentId;

  /// Last message ID received from the remote peer
  final int? ackLastReceivedId;

  ServiceMessageAcknowledge copyWith({
    int? id,
    int? ackCurrentId,
    int? ackLastReceivedId,
  }) =>
      ServiceMessageAcknowledge(
        id: id ?? this.id,
        ackCurrentId: ackCurrentId ?? this.ackCurrentId,
        ackLastReceivedId: ackLastReceivedId ?? this.ackLastReceivedId,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': 'a',
        if (ackCurrentId != null) 'ackCurrentId': ackCurrentId,
        if (ackLastReceivedId != null) 'ackLastReceivedId': ackLastReceivedId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageAcknowledge &&
          id == other.id &&
          ackCurrentId == other.ackCurrentId &&
          ackLastReceivedId == other.ackLastReceivedId;

  @override
  int get hashCode => Object.hash(id, ackCurrentId, ackLastReceivedId);

  @override
  String toString() =>
      'ServiceMessageAcknowledge(id: $id, ackCurrentId: $ackCurrentId, '
      'ackLastReceivedId: $ackLastReceivedId)';
}

/// Array request - request to send specific messages
@includeInBarrelFile
final class ServiceMessageArrayRequest extends ServiceMessage {
  const ServiceMessageArrayRequest({
    required super.id,
    required this.arrayId,
  });

  final List<int> arrayId;

  ServiceMessageArrayRequest copyWith({
    int? id,
    List<int>? arrayId,
  }) =>
      ServiceMessageArrayRequest(
        id: id ?? this.id,
        arrayId: arrayId ?? this.arrayId,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': 'array',
        'arrayId': arrayId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageArrayRequest &&
          id == other.id &&
          arrayId == other.arrayId;

  @override
  int get hashCode => Object.hash(id, arrayId);

  @override
  String toString() =>
      'ServiceMessageArrayRequest(id: $id, arrayId: $arrayId)';
}

/// New key exchange message (reason: 'newkey')
/// Distributes encryption key material with validity windows
@includeInBarrelFile
final class ServiceMessageNewKey extends ServiceMessage {
  const ServiceMessageNewKey({
    required super.id,
    required this.algorithm,
    required this.key,
    this.start,
    this.expiration,
    this.startMessage,
    this.endMessage,
  });

  /// Cryptographic algorithm for this key
  final CryptoAlgorithm algorithm;

  /// The key material as string
  final String key;

  /// When this key becomes valid
  final DateTime? start;

  /// When this key expires
  final DateTime? expiration;

  /// First message ID this key applies to
  final int? startMessage;

  /// Last message ID this key applies to
  final int? endMessage;

  ServiceMessageNewKey copyWith({
    int? id,
    CryptoAlgorithm? algorithm,
    String? key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  }) =>
      ServiceMessageNewKey(
        id: id ?? this.id,
        algorithm: algorithm ?? this.algorithm,
        key: key ?? this.key,
        start: start ?? this.start,
        expiration: expiration ?? this.expiration,
        startMessage: startMessage ?? this.startMessage,
        endMessage: endMessage ?? this.endMessage,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': 'newkey',
        'algorithm': algorithm,
        'key': key,
        if (start != null) 'start': start!.toIso8601String(),
        if (expiration != null) 'expiration': expiration!.toIso8601String(),
        if (startMessage != null) 'startMessage': startMessage,
        if (endMessage != null) 'endMessage': endMessage,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageNewKey &&
          id == other.id &&
          algorithm == other.algorithm &&
          key == other.key &&
          start == other.start &&
          expiration == other.expiration &&
          startMessage == other.startMessage &&
          endMessage == other.endMessage;

  @override
  int get hashCode => Object.hash(
        id,
        algorithm,
        key,
        start,
        expiration,
        startMessage,
        endMessage,
      );

  @override
  String toString() {
    final keyPreview = key.substring(0, (key.length ~/ 4).clamp(0, 8));
    return 'ServiceMessageNewKey(id: $id, algorithm: $algorithm, '
        'key: $keyPreview..., start: $start, expiration: $expiration, '
        'startMessage: $startMessage, endMessage: $endMessage)';
  }
}

/// Union type for all possible message types
/// Using sealed class pattern for type-safe pattern matching
@includeInBarrelFile
sealed class MessageType implements IErmesSerializable, StorageType{
  const MessageType();

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
      
  @override
  int get id => getId();

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

  @override
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
