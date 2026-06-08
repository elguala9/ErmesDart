import 'package:iermes/iermes.dart';

import 'exceptions.dart';

/// Default maximum message size in bytes

const int defaultMaxSize = 1024;

/// Runs [action], rethrowing any failure as a [CoreException] prefixed with
/// [message]. Centralises the "wrap-and-rethrow" pattern used across the
/// orchestrator's connection lifecycle.
Future<void> guardCoreOp(String message, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    throw CoreException('$message: $e');
  }
}

/// Splits a Uint8List into chunks of a maximum size.
///
/// [idHandler] - The ID handler service to generate chunk IDs
/// [buffer] - The data to be chunked
/// [refId] - Reference ID linking all chunks of the same message
/// [maxByte] - The maximum number of bytes allowed per chunk
/// Returns a list of ChunkMessage objects, each containing a chunk of the
/// original data

List<ChunkMessage> chunkArrayBuffer(
  IIdHandlerService idHandler,
  TypeOfData buffer,
  IdChunkType refId,
  int maxByte,
) {
  final totalLength = buffer.length;
  final numChunks = (totalLength / maxByte).ceil();
  final chunks = <ChunkMessage>[];

  for (var i = 0; i < numChunks; i++) {
    final start = i * maxByte;
    final end = start + maxByte < totalLength ? start + maxByte : totalLength;
    final chunkBuffer = buffer.sublist(start, end);

    chunks.add(
      ChunkMessage(
        data: chunkBuffer,
        index: i,
        roof: numChunks,
        id: idHandler.getNewId(),
        refId: refId,
      ),
    );
  }

  return chunks;
}

/// Determines the type of message
///
/// Returns:
/// - MessageValue.chunk if the message is a ChunkMessage
/// - MessageValue.service if the message is a ServiceMessage
/// - MessageValue.base if the message is a base MessageData

MessageValue getMessageType(MessageType message) => message.getType();

/// Creates a MessageData object from raw data and a new ID.
///
/// [rawData] - The data to be included in the message
/// [newId] - The ID to be assigned to the message
/// Returns a MessageData object with the provided data and ID

MessageData createMessageDataErmes(TypeOfData rawData, IdType newId) =>
    MessageData(data: rawData, id: newId);

/// Creates a MessageData object from raw data and generates a new ID using
/// the provided ID handler.
///
/// [idHandler] - The ID handler service to generate a new ID
/// [rawData] - The data to be included in the message
/// Returns a MessageData object with the provided data and a newly generated ID

MessageData createMessageDataErmesWithNewId(
  IIdHandlerService idHandler,
  TypeOfData rawData,
) {
  final newId = idHandler.getNewId();
  return createMessageDataErmes(rawData, newId);
}
