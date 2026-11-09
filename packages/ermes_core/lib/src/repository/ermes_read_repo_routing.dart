import 'package:iermes/iermes.dart';

import '../support/exceptions.dart';
import 'ermes_read_repo.dart';

/// Data-message routing of [ErmesReadRepo].
extension ErmesReadRepoRouting on ErmesReadRepo {
  /// Routes a non-service message to the not-read queue or chunk reassembler.
  void routeDataMessage(MessageType mess, MessageValue messageType) {
    switch (messageType) {
      case MessageValue.base:
        final dataMsg = mess.asData();
        if (dataMsg != null) {
          pushInNotReaded(dataMsg.data);
        }
      case MessageValue.chunk:
        final chunkMsg = mess.asChunk();
        if (chunkMsg != null) {
          handleChunkMessage(chunkMsg);
        }
      case MessageValue.service:
        throw CoreException('Message type not found: $messageType');
    }
  }
}
