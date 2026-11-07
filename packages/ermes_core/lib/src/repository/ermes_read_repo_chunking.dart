import 'package:iermes/iermes.dart';

import '../support/ermes_receive_stats.dart';
import 'ermes_read_repo_gone.dart';

/// Chunk reassembly and `gone` handling for `ErmesReadRepo`.
mixin ErmesReadRepoChunking {
  /// Pending chunk reassembly groups keyed by reference id.
  ErmesChunkGroups get chunkGroups;

  /// Optional message-control service tracking received message ids.
  IErmesMessageControlService? get ermesMessageControlService;

  /// Enqueues reassembled data onto the not-read buffer.
  void pushInNotReaded(TypeOfData data);

  /// Feeds a chunk into its reassembly group, pushing the merged buffer when
  /// all pieces have arrived.
  void handleChunkMessage(ChunkMessage mess) {
    final buffer = chunkGroups.add(mess);
    final count = buffer != null
        ? mess.roof
        : chunkGroups.receivedCount(mess.refId);
    ErmesReceiveStats.active?.onChunk(mess.refId, count, mess.roof);
    if (buffer != null) {
      pushInNotReaded(buffer);
    }
  }

  /// Handles a peer `gone` (RFC section 7.3 / 10.2): discards every refId
  /// group containing a named id and stops requesting all affected ids.
  void handleGone(List<IdType> goneIds) {
    final dropped = chunkGroups.discardGone(goneIds);
    for (final id in {...goneIds, ...dropped}) {
      ermesMessageControlService?.idGone(id);
    }
  }

  /// Whether a partially reassembled group for [refId] is still pending.
  bool hasPendingGroup(IdChunkType refId) => chunkGroups.isPending(refId);
}
