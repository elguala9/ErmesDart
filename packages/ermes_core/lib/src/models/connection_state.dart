import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';

/// Represents the state of an active connection for persistence.
///
/// This model captures connection metadata that can be persisted and restored
/// to enable reconnection to previously established connections.
@includeInBarrelFile
class ConnectionState {
  /// Creates a ConnectionState instance.
  ConnectionState({
    required this.connectionId,
    required this.remotePeerId,
    required this.reconnectAttempts,
    required this.isClosed,
    required this.lastActiveTimestamp,
    this.signalingInfo,
  });

  /// Creates a ConnectionState from a JSON map.
  factory ConnectionState.fromJson(Map<String, dynamic> json) =>
      ConnectionState(
        connectionId: json['connectionId'] as IdPeer,
        remotePeerId: json['remotePeerId'] as IdAccountType,
        reconnectAttempts: json['reconnectAttempts'] as int,
        isClosed: json['isClosed'] as bool,
        lastActiveTimestamp: json['lastActiveTimestamp'] as int,
        signalingInfo: json['signalingInfo'] as Map<String, dynamic>?,
      );

  /// Unique identifier for this connection
  final IdPeer connectionId;

  /// Remote peer's account ID
  final IdAccountType remotePeerId;

  /// Number of reconnection attempts made
  final int reconnectAttempts;

  /// Whether the connection is currently closed
  final bool isClosed;

  /// Unix timestamp (milliseconds) of last activity
  final int lastActiveTimestamp;

  /// Optional signaling-specific connection metadata
  final Map<String, dynamic>? signalingInfo;

  /// Converts this state to a JSON map for serialization.
  Map<String, dynamic> toJson() => {
    'connectionId': connectionId,
    'remotePeerId': remotePeerId,
    'reconnectAttempts': reconnectAttempts,
    'isClosed': isClosed,
    'lastActiveTimestamp': lastActiveTimestamp,
    'signalingInfo': signalingInfo,
  };

  @override
  String toString() => 'ConnectionState('
      'connectionId: $connectionId, '
      'remotePeerId: $remotePeerId, '
      'reconnectAttempts: $reconnectAttempts, '
      'isClosed: $isClosed, '
      'lastActiveTimestamp: $lastActiveTimestamp)';
}
