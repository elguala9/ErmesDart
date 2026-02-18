import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'ermes_types.dart';

/// Type aliases for common data types used throughout Ermes

/// Type used by the Ermes service internally
@includeInBarrelFile
typedef TypeOfData = Uint8List;

/// Type used in the external interfaces
@includeInBarrelFile
typedef TypeOfDataExternal = Uint8List;

/// Serializable data type used by the Ermes repository
@includeInBarrelFile
typedef SerializableDataType = Uint8List;

/// The ID of a peer connection
@includeInBarrelFile
typedef IdPeer = String;

/// Type of message ID
@includeInBarrelFile
typedef IdType = int;

/// Account ID type
@includeInBarrelFile
typedef IdAccountType = String;

/// ID of a chunk message
@includeInBarrelFile
typedef IdChunkType = String;

/// Type for chunk index
@includeInBarrelFile
typedef ChunkIndexType = int;

/// Union type for integrity check values
@includeInBarrelFile
typedef IntegrityCheckType = Object; // Can be String, int, or bool

/// Service reason codes:
/// - 'c' -> completed
/// - 's' -> send again
/// - 'x' -> closing connection
@includeInBarrelFile
typedef ServiceReason = String;

// Callback type definitions

/// Callback for when a service message is received
@includeInBarrelFile
typedef CallbackServiceMessage = void Function(ServiceMessage serviceMessage);

/// Callback for when a data message is received
@includeInBarrelFile
typedef CallbackOnMessageData = void Function(MessageData message);

/// Callback for when any message is received
@includeInBarrelFile
typedef CallbackOnMessage = void Function(MessageType message);

/// Callback for when raw data is received
@includeInBarrelFile
typedef CallbackOnData = void Function(TypeOfData data);

/// Callback for when data has arrived
@includeInBarrelFile
typedef CallbackOnDataArrived = void Function(TypeOfDataExternal data);

/// Callback for when data has arrived from a specific peer
@includeInBarrelFile
typedef CallbackOnDataArrivedFrom = void Function(
  TypeOfDataExternal data,
  IdPeer peer,
);

/// Callback for when a message is being sent
@includeInBarrelFile
typedef CallbackOnMessageSending = CallbackOnMessage;

/// Callback for when a message has been sent
@includeInBarrelFile
typedef CallbackOnMessageSent = CallbackOnMessage;

/// Callback for when data is being sent
@includeInBarrelFile
typedef CallbackOnDataSending = CallbackOnData;

/// Callback for when data has been sent
@includeInBarrelFile
typedef CallbackOnDataSent = CallbackOnData;

/// Callback for repository data handling
@includeInBarrelFile
typedef CallbackOnDataRepository = void Function(SerializableDataType data);

/// Callback for message service handling
@includeInBarrelFile
typedef CallbackOnMessageService = void Function(
  TypeOfData data,
  MessageWithId messageWithId,
);

/// Callback for when a new key has arrived
@includeInBarrelFile
typedef CallbackOnNewKey = void Function(ServiceMessageNewKey newKey);
