part of 'service_messages.dart';

/// Acknowledge message (reason: 'a')
/// Contains ID tracking information for synchronization
@JsonSerializable()
final class ServiceMessageAcknowledge extends ServiceMessage {
  /// Creates an acknowledge message carrying id-tracking counters.
  const ServiceMessageAcknowledge({
    required super.id,
    this.ackCurrentId,
    this.ackLastReceivedId,
  });

  /// Builds a [ServiceMessageAcknowledge] from its JSON representation.
  factory ServiceMessageAcknowledge.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageAcknowledgeFromJson(json);

  /// My current outgoing message ID counter (after this message)
  final int? ackCurrentId;

  /// Last message ID received from the remote peer
  final int? ackLastReceivedId;

  /// Returns a copy of this acknowledge message with fields replaced.
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

  /// Serializes this message to JSON, tagging it with reason 'a'.
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
  /// Creates a request asking the peer to resend the listed message ids.
  const ServiceMessageArrayRequest({
    required super.id,
    required this.arrayId,
  });

  /// Builds a [ServiceMessageArrayRequest] from its JSON representation.
  factory ServiceMessageArrayRequest.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageArrayRequestFromJson(json);

  /// Message ids being requested from the peer.
  final List<int> arrayId;

  /// Returns a copy of this request with the given fields replaced.
  ServiceMessageArrayRequest copyWith({
    int? id,
    List<int>? arrayId,
  }) =>
      ServiceMessageArrayRequest(
        id: id ?? this.id,
        arrayId: arrayId ?? this.arrayId,
      );

  /// Serializes this message to JSON, tagging it with reason 'array'.
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
