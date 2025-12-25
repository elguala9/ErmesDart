import 'dart:typed_data';

import 'ermes_types.dart';

/// Type aliases for common data types used throughout Ermes

/// Type used by the Ermes service internally
typedef TypeOfData = Uint8List;

/// Type used in the external interfaces
typedef TypeOfDataExternal = Uint8List;

/// Serializable data type used by the Ermes repository
typedef SerializableDataType = Uint8List;

/// The ID of a peer connection
typedef IdPeer = String;

/// Type of message ID
typedef IdType = int;

/// ID of a chunk message
typedef IdChunkType = String;

/// Type for chunk index
typedef ChunkIndexType = int;

/// Union type for integrity check values
typedef IntegrityCheckType = Object; // Can be String, int, or bool

/// Service reason codes:
/// - 'c' -> completed
/// - 's' -> send again
/// - 'x' -> closing connection
typedef ServiceReason = String;

// Callback type definitions

/// Callback for when a service message is received
typedef CallbackServiceMessage = void Function(ServiceMessage serviceMessage);

/// Callback for when a data message is received
typedef CallbackOnMessageData = void Function(MessageData message);

/// Callback for when any message is received
typedef CallbackOnMessage = void Function(MessageType message);

/// Callback for when raw data is received
typedef CallbackOnData = void Function(TypeOfData data);

/// Callback for when data has arrived
typedef CallbackOnDataArrived = void Function(TypeOfDataExternal data);

/// Callback for when data has arrived from a specific peer
typedef CallbackOnDataArrivedFrom = void Function(
  TypeOfDataExternal data,
  IdPeer peer,
);

/// Callback for when a message is being sent
typedef CallbackOnMessageSending = CallbackOnMessage;

/// Callback for when a message has been sent
typedef CallbackOnMessageSent = CallbackOnMessage;

/// Callback for when data is being sent
typedef CallbackOnDataSending = CallbackOnData;

/// Callback for when data has been sent
typedef CallbackOnDataSent = CallbackOnData;

/// Callback for repository data handling
typedef CallbackOnDataRepository = void Function(SerializableDataType data);

/// Callback for message service handling
typedef CallbackOnMessageService = void Function(
  TypeOfData data,
  MessageWithId messageWithId,
);
