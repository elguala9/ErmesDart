part of 'service_messages.dart';

/// Connection close request (reason: 'x')
@JsonSerializable()
final class ServiceMessageConnectionClose extends ServiceMessage {
  /// Creates a connection-close request with its id.
  const ServiceMessageConnectionClose({required super.id});

  /// Builds a [ServiceMessageConnectionClose] from its JSON representation.
  factory ServiceMessageConnectionClose.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageConnectionCloseFromJson(json);

  /// Serializes this message to JSON, tagging it with reason 'x'.
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
  /// Creates a control command message with its id.
  const ServiceMessageControl({required super.id});

  /// Builds a [ServiceMessageControl] from its JSON representation.
  factory ServiceMessageControl.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageControlFromJson(json);

  /// Serializes this message to JSON, tagging it with reason 'c'.
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
