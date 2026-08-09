import 'dart:typed_data';


import 'package:iermes/iermes.dart';

import '../support/exceptions.dart';

// composeUint8Array. For now, implementing a basic concatenation function

/// Concatenates a list of [Uint8List] buffers into a single contiguous buffer.
Uint8List composeUint8Array(List<Uint8List> arrays) {
  final totalLength = arrays.fold<int>(0, (sum, arr) => sum + arr.length);
  final result = Uint8List(totalLength);
  var offset = 0;
  for (final arr in arrays) {
    result.setRange(offset, offset + arr.length, arr);
    offset += arr.length;
  }
  return result;
}

/// Class used to handle chunk assembly

class ChunkHandler {
  /// Creates a handler for a chunked message identified by [_id].
  ///
  /// [roof] is the total expected number of chunks (must be positive).
  /// [maxTotalSize] optionally caps the cumulative size of received data.
  ChunkHandler(this._id, int roof, {int? maxTotalSize})
    : _roof = (roof > 0)
        ? roof
        : throw ErmesValidationException(
            'roof must be positive, got: $roof',
          ),
      _maxTotalSize = maxTotalSize;

  /// Identifier of the chunked message being assembled.
  final IdChunkType _id;

  /// Total number of chunks expected for a complete message.
  final int _roof;

  /// Optional maximum cumulative size (bytes) of assembled data.
  final int? _maxTotalSize;

  /// Running total of bytes received so far.
  int _currentTotalSize = 0;

  /// Received chunks keyed by their index.
  final Map<IdType, TypeOfData> _chunks = {};

  /// Whether all expected chunks have been received.
  bool _isCompleted = false;

  /// Returns the identifier of the chunked message.
  IdChunkType getId() => _id;

  /// Adds a chunk to the handler
  /// Returns the complete data if this is the last chunk, otherwise null
  TypeOfData? addChunk(ChunkMessage chunk) {
    if (chunk.index < 0 || chunk.index >= _roof) {
      throw ErmesValidationException(
        'Chunk index ${chunk.index} out of range [0, $_roof)',
      );
    }
    if (_isDuplicate(chunk)) {
      return null;
    }

    if (_maxTotalSize != null &&
        _currentTotalSize + chunk.data.length > _maxTotalSize) {
      throw CoreException(
        'Total chunk data exceeds max size of $_maxTotalSize',
      );
    }

    _chunks[chunk.index] = chunk.data;
    _currentTotalSize += chunk.data.length;

    if (_roof == _chunks.length) {
      _isCompleted = true;
      return _handleLastChunk();
    }

    return null;
  }

  /// Whether a chunk with the same index has already been received.
  bool _isDuplicate(ChunkMessage chunk) => _chunks.containsKey(chunk.index);

  /// Builds the final message once the last chunk arrives, throwing if any
  /// chunk is still missing.
  TypeOfData _handleLastChunk() {
    final message = createData();
    if (message == null) {
      throw CoreException('Chunks are missing');
    }
    return message;
  }

  /// Creates the original message by merging the chunks
  /// Returns null if not all chunks have been received
  TypeOfData? createData() {
    final sortedValues = _getSortedValues<int, Uint8List>(_chunks);
    if (_isCompleted) {
      return composeUint8Array(sortedValues.values);
    }
    return null;
  }

  /// Returns the indices of missing chunks
  List<int> getMissingChunkIndices() {
    final sortedValues = _getSortedValues<int, Uint8List>(_chunks);
    return getMissingIndices(sortedValues.indexes, _roof);
  }

  /// Sorts the entries of [map] by key and returns their indexes and values.
  _SortedChunk<K, V> _getSortedValues<K extends Comparable<Object>, V>(
    Map<K, V> map,
  ) {
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _SortedChunk(
      indexes: entries.map((e) => e.key).toList(),
      values: entries.map((e) => e.value).toList(),
    );
  }
}


/// Holds chunk indexes and values sorted in parallel by key.
class _SortedChunk<K, V> {
  /// Creates a sorted chunk view from parallel [indexes] and [values].
  _SortedChunk({required this.indexes, required this.values});

  /// Chunk keys in ascending order.
  final List<K> indexes;

  /// Chunk values ordered to match [indexes].
  final List<V> values;
}

/// Returns the missing numbers (holes) in the range [0, max) with
/// respect to the provided array.
///
/// [numbers] - The array of numbers
/// [max] - The maximum value of the range (exclusive)
/// Returns an array of missing numbers in the range [0, max)
List<int> getMissingIndices(List<int> numbers, int max) {
  final numbersSet = numbers.toSet();
  final missing = <int>[];

  for (var i = 0; i < max; i++) {
    if (!numbersSet.contains(i)) {
      missing.add(i);
    }
  }

  return missing;
}
