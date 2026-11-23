import 'package:iermes/iermes.dart';

/// Retention window of the retransmission mapping fixed by protocol
/// version 3.0 (RFC sections 7.5 and 10.2).
final Duration ermesRetransmissionRetention =
    ErmesProtocolParameters.current.retentionWindow;

/// Applies the RFC section 10.2 eviction rules to the outbound
/// retransmission mapping held in [storage] (cache and persistent storage):
/// entries acknowledged by the counterpart are evicted, and unacknowledged
/// entries older than [window] are evicted too.
class ErmesRetransmissionRetention {
  /// Creates a retention policy over [storage]; [clock] defaults to
  /// [DateTime.now] and [window] to [ermesRetransmissionRetention].
  ErmesRetransmissionRetention({
    required this.storage,
    DateTime Function()? clock,
    Duration? window,
  })  : window = window ?? ermesRetransmissionRetention,
        _clock = clock ?? DateTime.now;

  /// Mapping of outbound ids to their stored roots.
  final IErmesStorageAndCachingMessages<MessageRootStorage> storage;

  /// Maximum age of an unacknowledged entry.
  final Duration window;

  final DateTime Function() _clock;

  /// Stores [root] stamped with the current time.
  Future<void> store(MessageRootStorage root) => storage.store(
        root.copyWith(storedAtMs: _clock().millisecondsSinceEpoch),
      );

  /// Returns the root stored for [id], or null when absent or expired.
  /// An expired (or unstamped legacy) entry is evicted on access, so it
  /// can never be resurrected from persistent storage.
  Future<MessageRootStorage?> retrieve(IdType id) async {
    final root = await storage.retrieve(id);
    if (root == null) {
      return null;
    }
    if (_isExpired(root)) {
      await storage.delete(id);
      return null;
    }
    return root;
  }

  /// Evicts every entry with an id up to and including [lastAcked]
  /// (acknowledged via `ackLastReceivedId`), then every expired entry.
  Future<void> evictAcknowledged(IdType lastAcked) async {
    for (final id in await storage.listOfIds()) {
      if (id <= lastAcked) {
        await storage.delete(id);
      } else {
        await retrieve(id);
      }
    }
  }

  /// Evicts every entry older than [window].
  Future<void> evictExpired() async {
    for (final id in await storage.listOfIds()) {
      await retrieve(id);
    }
  }

  bool _isExpired(MessageRootStorage root) {
    final storedAt = root.storedAtMs;
    if (storedAt == null) {
      return true;
    }
    final age = _clock().millisecondsSinceEpoch - storedAt;
    return age > window.inMilliseconds;
  }
}
