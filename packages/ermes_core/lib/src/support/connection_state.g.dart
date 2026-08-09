// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionState _$ConnectionStateFromJson(Map<String, dynamic> json) =>
    ConnectionState(
      connectionId: json['connectionId'] as String,
      remotePeerId: json['remotePeerId'] as String,
      reconnectAttempts: (json['reconnectAttempts'] as num).toInt(),
      isClosed: json['isClosed'] as bool,
      lastActiveTimestamp: (json['lastActiveTimestamp'] as num).toInt(),
      signalingInfo: json['signalingInfo'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ConnectionStateToJson(ConnectionState instance) =>
    <String, dynamic>{
      'connectionId': instance.connectionId,
      'remotePeerId': instance.remotePeerId,
      'reconnectAttempts': instance.reconnectAttempts,
      'isClosed': instance.isClosed,
      'lastActiveTimestamp': instance.lastActiveTimestamp,
      'signalingInfo': instance.signalingInfo,
    };
