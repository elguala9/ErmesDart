import 'dart:async';

import 'package:iermes/iermes.dart';

/// Default poll period of [OrcRepublishedKeyWatcher]: bounds the extra relay
/// reads to one per connected peer per minute.
const Duration defaultRepublishedKeyPollInterval = Duration(seconds: 60);

/// Inputs of [OrcRepublishedKeyWatcher] (see
/// [OrcRepublishedKeyWatcherFactory]).
class OrcRepublishedKeyWatcherInput {
  /// Creates the input. [interval] defaults to
  /// [defaultRepublishedKeyPollInterval].
  const OrcRepublishedKeyWatcherInput({
    required this.peers,
    required this.check,
    this.interval,
  });

  /// Currently connected peers, re-read on every tick.
  final Iterable<IdPeer> Function() peers;

  /// Reads one peer's signal and re-derives its session keys when the same
  /// IdSignaling carries a new public key. Returns whether it re-derived.
  final Future<bool> Function(IdPeer peer) check;

  /// Poll period; `null` uses [defaultRepublishedKeyPollInterval].
  final Duration? interval;
}

/// Periodically polls the signal of every connected peer so a public-key
/// rotation whose in-band `newpubkey` was lost is still picked up
/// (RFC 8.6, 6.1).
class OrcRepublishedKeyWatcher {
  /// Creates a stopped watcher; prefer [OrcRepublishedKeyWatcherFactory].
  OrcRepublishedKeyWatcher(this._input)
      : interval = _input.interval ?? defaultRepublishedKeyPollInterval;

  final OrcRepublishedKeyWatcherInput _input;

  /// Effective poll period.
  final Duration interval;

  Timer? _timer;
  bool _polling = false;
  bool _disposed = false;

  /// Whether the periodic timer is running.
  bool get isRunning => _timer?.isActive ?? false;

  /// Starts polling; idempotent, ignored once disposed.
  void start() {
    if (_disposed || isRunning) {
      return;
    }
    _timer = Timer.periodic(interval, (_) => unawaited(_pollBestEffort()));
  }

  /// Stops polling for good.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }

  /// Timer tick: a relay failure is retried on the next tick.
  Future<void> _pollBestEffort() async {
    try {
      await poll();
    } on Object {
      // best-effort background check
    }
  }

  /// Checks every connected peer once. Overlapping calls are ignored.
  /// Returns the peers whose session keys were re-derived.
  Future<List<IdPeer>> poll() async {
    if (_disposed || _polling) {
      return const [];
    }
    _polling = true;
    final changed = <IdPeer>[];
    try {
      for (final peer in List.of(_input.peers())) {
        if (_disposed) {
          break;
        }
        if (await _input.check(peer)) {
          changed.add(peer);
        }
      }
    } finally {
      _polling = false;
    }
    return changed;
  }
}

/// Factory for [OrcRepublishedKeyWatcher].
class OrcRepublishedKeyWatcherFactory {
  OrcRepublishedKeyWatcherFactory._();

  /// Creates a stopped watcher from [input].
  static OrcRepublishedKeyWatcher create(
    OrcRepublishedKeyWatcherInput input,
  ) =>
      OrcRepublishedKeyWatcher(input);
}
