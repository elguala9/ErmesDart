import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

// TODO: Find Dart equivalent for 'serialization-utility/src/Array'
// composeUint8Array. For now, implementing a basic concatenation function
@includeInBarrelFile
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
@includeInBarrelFile
class ChunkHandler {
  ChunkHandler(this._id, this._roof);
  final IdChunkType _id;
  final int _roof;
  final Map<IdType, TypeOfData> _chunks = {};
  bool _isCompleted = false;

  IdChunkType getId() => _id;

  /// Adds a chunk to the handler
  /// Returns the complete data if this is the last chunk, otherwise null
  TypeOfData? addChunk(ChunkMessage chunk) {
    if (_isDuplicate(chunk)) {
      return null;
    }

    _chunks[chunk.index] = chunk.data;

    if (_roof == _chunks.length) {
      _isCompleted = true;
      return _handleLastChunk();
    }

    return null;
  }

  bool _isDuplicate(ChunkMessage chunk) => _chunks.containsKey(chunk.index);

  TypeOfData _handleLastChunk() {
    final message = createData();
    if (message == null) {
      throw Exception('Chunks are missing');
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

@includeInBarrelFile
class _SortedChunk<K, V> {
  _SortedChunk({required this.indexes, required this.values});
  final List<K> indexes;
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
