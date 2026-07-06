import 'dart:convert';

import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

import 'ermes_signal_type.dart';
import 'ermes_signaling_server_listeners.dart';

/// Manages per-peer Nostr subscriptions and caches their latest signals.
class ErmesSignalingServerSubscriptions {
  /// Creates a subscription manager over the given Nostr client and listeners.
  ErmesSignalingServerSubscriptions({
    required this.nostrSignaling,
    required this.listeners,
    required this.maxDedupRecords,
  });

  /// Nostr client used to subscribe to and unsubscribe from peer events.
  final INostrSignaling nostrSignaling;

  /// Listener registry notified about incoming signals and errors.
  final ErmesSignalingServerListeners listeners;

  /// Maximum number of records kept for event de-duplication.
  final int maxDedupRecords;

  /// Latest signal received per peer.
  final Map<IdAccountType, SignalErmes> cachedSignals = {};

  /// Set of peers currently subscribed to.
  final Set<IdAccountType> subscribedPeers = {};

  /// Active event callbacks keyed by the peer they listen to.
  final Map<IdAccountType, EventCallback> eventCallbacks = {};

  /// Subscribes to the peer's events, ignoring duplicate subscriptions.
  void subscribeToPeer(IdAccountType from) {
    if (subscribedPeers.contains(from)) {
      return;
    }
    subscribedPeers.add(from);
    final ec = EventCallback(
      (id, data) => _handleEvent(from, data),
      maxRecords: maxDedupRecords,
    );
    eventCallbacks[from] = ec;
    nostrSignaling.subscribe(from, ec);
  }

  /// Decodes an incoming event into a signal, caches it and notifies
  /// listeners; reports decoding failures as errors.
  void _handleEvent(IdAccountType from, List<int> data) {
    try {
      final signalString = utf8.decode(data);
      final signal = SignalErmes.fromString(signalString);
      final cached = cachedSignals[from];
      // Never regress the cache: with several relays subscribed, one can
      // replay an event older than the newest already received.
      if (cached == null ||
          cached.isExpired() ||
          signal.epochTimestampStartConversation >=
              cached.epochTimestampStartConversation) {
        cachedSignals[from] = signal;
      }
      if (listeners.signalCallbacks.containsKey(from)) {
        listeners.signalCallbacks[from]?.call(signal);
      }
    } on Object catch (e) {
      listeners.notifyError(e);
    }
  }

  /// Unsubscribes from every peer, ignoring errors during teardown.
  Future<void> unsubscribeAll() async {
    for (final entry in eventCallbacks.entries) {
      try {
        await nostrSignaling.unsubscribe(entry.key);
      } on Exception {
        // Ignore unsubscribe errors during destroy
      }
    }
  }

  /// Clears cached signals, subscribed peers and event callbacks.
  void clear() {
    cachedSignals.clear();
    subscribedPeers.clear();
    eventCallbacks.clear();
  }
}
