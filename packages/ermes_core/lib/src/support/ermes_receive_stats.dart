/// Counters for the inbound message pipeline.
///
/// Diagnostic only and opt-in: [ErmesReadRepo] reports to [active], which is
/// null by default, so production pays a single null check per frame. Every
/// silent drop is counted, so a payload that "never arrives" shows where it
/// was lost.
class ErmesReceiveStats {
  /// The installed counters, or null when receive diagnostics are off.
  static ErmesReceiveStats? active;

  /// Wire frames handed to the read pipeline.
  int frames = 0;

  /// Frames dropped by the envelope decoder (empty, undecryptable, bad hash
  /// or duplicate).
  int decodeDropped = 0;

  /// Decode drops split by reason: empty frame, no cipher registered for
  /// the peer, decryption failure, integrity-hash mismatch, duplicate.
  int dropEmpty = 0;

  /// See [dropEmpty].
  int dropNoCipher = 0;

  /// See [dropEmpty].
  int dropDecrypt = 0;

  /// See [dropEmpty].
  int dropHash = 0;

  /// See [dropEmpty].
  int dropDuplicate = 0;

  /// Text of the last decryption failure (e.g. unknown key digest).
  String? lastDecryptError;

  /// Frames that threw while being decoded or dispatched.
  int failed = 0;

  /// Chunks accepted into a reassembly handler.
  int chunks = 0;

  /// Chunked messages fully reassembled.
  int reassembled = 0;

  /// Data messages dropped because the not-read buffer was full.
  int bufferFullDropped = 0;

  /// The last error raised while processing a frame.
  Object? lastError;

  /// Chunks received so far and expected, per message still being assembled.
  final Map<String, (int, int)> _pending = {};

  /// Records a frame entering the pipeline.
  void onFrame() => frames++;

  /// Records a frame the envelope decoder dropped.
  void onDecodeDropped() => decodeDropped++;

  /// Records a frame dropped as empty.
  void onDropEmpty() => dropEmpty++;

  /// Records an encrypted frame dropped for lack of a peer cipher.
  void onDropNoCipher() => dropNoCipher++;

  /// Records an encrypted frame whose decryption failed with [error].
  void onDropDecrypt(Object error) {
    dropDecrypt++;
    lastDecryptError = error.toString();
  }

  /// Records a frame dropped on integrity-hash mismatch.
  void onDropHash() => dropHash++;

  /// Records a frame dropped as an already-processed duplicate.
  void onDropDuplicate() => dropDuplicate++;

  /// Records a frame that failed with [error].
  void onFailed(Object error) {
    failed++;
    lastError = error;
  }

  /// Records chunk progress for [refId]: [received] of [roof] pieces held.
  void onChunk(String refId, int received, int roof) {
    chunks++;
    if (received >= roof) {
      reassembled++;
      _pending.remove(refId);
    } else {
      _pending[refId] = (received, roof);
    }
  }

  /// Records a data message dropped on a full buffer.
  void onBufferFull() => bufferFullDropped++;

  /// Resets the counters; messages still being assembled are kept.
  void reset() {
    frames = decodeDropped = failed = chunks = reassembled = 0;
    bufferFullDropped = dropEmpty = dropNoCipher = dropDecrypt = 0;
    dropHash = dropDuplicate = 0;
    lastError = lastDecryptError = null;
  }

  @override
  String toString() {
    final pending = _pending.entries
        .map((e) => '${e.key}:${e.value.$1}/${e.value.$2}')
        .join(',');
    return 'frames=$frames decodeDropped=$decodeDropped '
        '(empty=$dropEmpty noCipher=$dropNoCipher decrypt=$dropDecrypt '
        'hash=$dropHash dup=$dropDuplicate) failed=$failed '
        'chunks=$chunks reassembled=$reassembled '
        'bufferFullDropped=$bufferFullDropped lastError=$lastError '
        'lastDecryptError=$lastDecryptError '
        'pending=[$pending]';
  }
}
