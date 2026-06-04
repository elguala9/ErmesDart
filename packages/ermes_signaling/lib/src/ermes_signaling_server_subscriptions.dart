import 'dart:convert';

import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

import 'ermes_signal_type.dart';
import 'ermes_signaling_server_listeners.dart';

class ErmesSignalingServerSubscriptions {
  ErmesSignalingServerSubscriptions({
    required this.nostrSignaling,
    required this.listeners,
    required this.maxDedupRecords,
  });

  final INostrSignaling nostrSignaling;
  final ErmesSignalingServerListeners listeners;
  final int maxDedupRecords;

  final Map<IdAccountType, SignalErmes> cachedSignals = {};
  final Set<IdAccountType> subscribedPeers = {};
  final Map<IdAccountType, EventCallback> eventCallbacks = {};

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

  void _handleEvent(IdAccountType from, List<int> data) {
    try {
      final signalString = utf8.decode(data);
      final signal = SignalErmes.fromString(signalString);
      cachedSignals[from] = signal;
      if (listeners.signalCallbacks.containsKey(from)) {
        listeners.signalCallbacks[from]?.call(signal);
      }
    } on Object catch (e) {
      listeners.notifyError(e);
    }
  }

  Future<void> unsubscribeAll() async {
    for (final entry in eventCallbacks.entries) {
      try {
        await nostrSignaling.unsubscribe(entry.key);
      } on Exception {
        // Ignore unsubscribe errors during destroy
      }
    }
  }

  void clear() {
    cachedSignals.clear();
    subscribedPeers.clear();
    eventCallbacks.clear();
  }
}
