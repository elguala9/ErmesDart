
import 'package:cryptdart/types/crypto_algorithm.dart';
import 'package:json_annotation/json_annotation.dart';

import '../ermes/message_enums.dart';

part 'service_messages.g.dart';

/// Service message for control and coordination
/// Uses sealed class pattern for type-safe message handling by reason
sealed class ServiceMessage implements MessageWithId, IErmesSerializable {
  const ServiceMessage({required this.id});

  // MANUAL SERIALIZATION: Polymorphic dispatch on json['reason']
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
          algorithm: CryptoAlgorithm.values.byName(json['algorithm'] as String),
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
@JsonSerializable()
final class ServiceMessageConnectionClose extends ServiceMessage {
  const ServiceMessageConnectionClose({required super.id});

  factory ServiceMessageConnectionClose.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageConnectionCloseFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
        ..._$ServiceMessageConnectionCloseToJson(this),
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
@JsonSerializable()
final class ServiceMessageControl extends ServiceMessage {
  const ServiceMessageControl({required super.id});

  factory ServiceMessageControl.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageControlFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
        ..._$ServiceMessageControlToJson(this),
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
@JsonSerializable()
final class ServiceMessageAcknowledge extends ServiceMessage {
  const ServiceMessageAcknowledge({
    required super.id,
    this.ackCurrentId,
    this.ackLastReceivedId,
  });

  factory ServiceMessageAcknowledge.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageAcknowledgeFromJson(json);

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
        ..._$ServiceMessageAcknowledgeToJson(this),
        'reason': 'a',
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
@JsonSerializable()
final class ServiceMessageArrayRequest extends ServiceMessage {
  const ServiceMessageArrayRequest({
    required super.id,
    required this.arrayId,
  });

  factory ServiceMessageArrayRequest.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageArrayRequestFromJson(json);

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
        ..._$ServiceMessageArrayRequestToJson(this),
        'reason': 'array',
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

  // MANUAL SERIALIZATION: DateTime + CryptoAlgorithm converters
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': 'newkey',
        'algorithm': algorithm.name,
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
