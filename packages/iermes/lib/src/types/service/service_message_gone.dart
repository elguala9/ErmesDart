part of 'service_messages.dart';

/// Retransmission unavailable (reason: 'gone'), RFC section 7.2 / 10.2.
///
/// Answer to an array request or an acknowledge-implied gap naming ids the
/// sender can no longer resend. A `gone` is never itself answered.
@JsonSerializable()
final class ServiceMessageGone extends ServiceMessage {
  /// Creates a gone message listing the unavailable message ids.
  const ServiceMessageGone({required super.id, required this.arrayId});

  /// Builds a [ServiceMessageGone] from its JSON representation.
  factory ServiceMessageGone.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageGoneFromJson(json);

  /// Wire value of the `reason` field.
  static const String reason = 'gone';

  /// Message ids that can no longer be retransmitted.
  final List<int> arrayId;

  /// Serializes this message to JSON, tagging it with reason 'gone'.
  @override
  Map<String, dynamic> toJson() => {
    ..._$ServiceMessageGoneToJson(this),
    'reason': reason,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageGone &&
          id == other.id &&
          _sameIds(arrayId, other.arrayId);

  @override
  int get hashCode => Object.hash(id, Object.hashAll(arrayId));

  @override
  String toString() => 'ServiceMessageGone(id: $id, arrayId: $arrayId)';
}

bool _sameIds(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
