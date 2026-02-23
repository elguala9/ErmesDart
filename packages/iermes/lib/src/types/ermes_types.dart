import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'ermes/ermes.dart';
import 'type_aliases.dart' show CallbackOnDataArrived, CallbackOnMessage;

// Re-export everything from submodules for backward compatibility
export 'converters/converters.dart';
export 'ermes/ermes.dart';
export 'service/service.dart';

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
