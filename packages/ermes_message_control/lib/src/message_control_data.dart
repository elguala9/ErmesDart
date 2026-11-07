import 'package:iermes/iermes.dart';

/// Storage type for message control data

class MessageControlData {
  /// Creates a snapshot with the given [timestamp] and optional [missingIds].
  MessageControlData({required this.timestamp, this.missingIds});
  /// The IDs currently detected as missing, if any.
  final List<IdType>? missingIds;
  /// The moment this snapshot was captured.
  final int timestamp;

  /// Serializes this snapshot into a map for persistence.
  Map<String, dynamic> toMap() => {
    'missing_ids': missingIds,
    'timestamp': timestamp,
  };
}
