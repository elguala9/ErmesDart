import 'package:iermes/iermes.dart';

import '../utility/chunk_handler.dart';

/// Pending chunk reassembly groups, keyed by `refId`, plus the `gone`
/// discard logic of RFC section 7.3.
///
/// A sender reserves a contiguous id block for the chunks of one logical
/// message (chunk `index` i carries id `minId + i`), so a group covers the
/// id range `[minId, minId + roof)` even for chunks never received.
class ErmesChunkGroups {
  /// Creates an empty group set, capping each group at [maxTotalSize].
  ErmesChunkGroups({int? maxTotalSize}) : _maxTotalSize = maxTotalSize;

  final int? _maxTotalSize;
  final Map<IdChunkType, ChunkHandler> _handlers = {};
  final Map<IdChunkType, ({int minId, int roof})> _ranges = {};
  final Set<IdChunkType> _discarded = {};

  /// Whether a reassembly group for [refId] is pending.
  bool isPending(IdChunkType refId) => _handlers.containsKey(refId);

  /// Feeds [chunk] into its group; returns the merged buffer once complete.
  /// Chunks of a group already discarded by `gone` are ignored.
  TypeOfData? add(ChunkMessage chunk) {
    if (_discarded.contains(chunk.refId)) {
      return null;
    }
    final handler = _handlers.putIfAbsent(
      chunk.refId,
      () => ChunkHandler(chunk.refId, chunk.roof, maxTotalSize: _maxTotalSize),
    );
    _ranges.putIfAbsent(
      chunk.refId,
      () => (minId: chunk.id - chunk.index, roof: chunk.roof),
    );
    final buffer = handler.addChunk(chunk);
    if (buffer != null) {
      _handlers.remove(chunk.refId);
      _ranges.remove(chunk.refId);
    }
    return buffer;
  }

  /// Number of chunks received so far for [refId] (0 when none).
  int receivedCount(IdChunkType refId) => _handlers[refId]?.receivedCount ?? 0;

  /// Discards every pending group containing one of the [goneIds] and
  /// returns all member ids of the discarded groups.
  List<IdType> discardGone(List<IdType> goneIds) {
    final memberIds = <IdType>[];
    final hit = _ranges.entries
        .where((e) => goneIds.any((id) => _inRange(id, e.value)))
        .toList();
    for (final entry in hit) {
      final r = entry.value;
      memberIds.addAll(List.generate(r.roof, (i) => r.minId + i));
      _handlers.remove(entry.key);
      _ranges.remove(entry.key);
      _discarded.add(entry.key);
    }
    return memberIds;
  }

  static bool _inRange(IdType id, ({int minId, int roof}) r) =>
      id >= r.minId && id < r.minId + r.roof;
}
