import 'dart:async';
import 'dart:convert';

import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_signal_type.dart';

/// Implementation of IErmesSignalingServer using INostrSignaling
///
/// This class provides peer discovery and connection establishment
/// using Nostr-based signaling for P2P communication.
///
/// New in nostr_signaling 0.3.0:
/// - GZip compression support for reduced bandwidth
/// - Real-time signal subscription via subscribe() with EventCallback dedup
@isSingleton
class ErmesSignalingServer implements IErmesSignalingServer {

  /// Creates a new signaling server instance from an existing INostrSignaling.
  ErmesSignalingServer({
    required this.nostrSignaling,
    required this.accountId,
    this.maxDedupRecords = 1000,
  });

  ErmesSignalingServer.emptyForDI() : maxDedupRecords = 1000;

  /// Creates a signaling server from Nostr key strings.
  ///
  /// Uses [initialPointNostrSignaling] to register the [INostrSignaling]
  /// instance in the singleton DI container, enabling consistent access
  /// for all DI-resolved components.
  ///
  /// [useCompression] enables GZip compression for reduced bandwidth
  /// [maxDedupRecords] max hashes kept by EventCallback dedup (default 1000)
  static Future<ErmesSignalingServer> fromKeys({
    required String pubkey,
    required String privkey,
    required IdAccountType accountId,
    List<String> relayUrls = const ['wss://relay.damus.io'],
    bool useCompression = false,
    int maxDedupRecords = 1000,
  }) async {
    final keyPair = NostrKeys.fromHex(
      privateKeyHex: privkey,
      publicKeyHex: pubkey,
    );
    await initialPointNostrSignaling(
      keyPair: keyPair,
      relayUrls: relayUrls,
      useCompression: useCompression,
    );
    final nostrSignaling = getINostrSignaling();
    await nostrSignaling.connect();
    return ErmesSignalingServer(
      nostrSignaling: nostrSignaling,
      accountId: accountId,
      maxDedupRecords: maxDedupRecords,
    );
  }

  /// Creates a signaling server from a [NostrConfig] JSON file on disk.
  ///
  /// Reads key pair and relays from [configPath].
  /// Uses [initialPointNostrSignalingFromConfig] so the [INostrSignaling]
  /// instance is registered in the singleton DI container.
  static Future<ErmesSignalingServer> fromConfig({
    required IdAccountType accountId,
    String configPath = 'nostr_config.json',
    bool useCompression = false,
    int maxDedupRecords = 1000,
  }) async {
    await initialPointNostrSignalingFromConfig(
      configPath: configPath,
      useCompression: useCompression,
    );
    final nostrSignaling = getINostrSignaling();
    await nostrSignaling.connect();
    return ErmesSignalingServer(
      nostrSignaling: nostrSignaling,
      accountId: accountId,
      maxDedupRecords: maxDedupRecords,
    );
  }

  @isInjected
  late INostrSignaling nostrSignaling;
  @isInjected
  late IdAccountType accountId;

  final int maxDedupRecords;

  final Map<String?, void Function(ISignalErmes data)> _signalCallbacks = {};
  final List<void Function(Object err)> _errorCallbacks = [];
  final List<void Function()> _closeCallbacks = [];

  final Map<IdAccountType, SignalErmes> _cachedSignals = {};
  final Set<IdAccountType> _subscribedPeers = {};
  final Map<IdAccountType, EventCallback> _eventCallbacks = {};

  @override
  Future<void> destroy() async {
    for (final entry in _eventCallbacks.entries) {
      try {
        await nostrSignaling.unsubscribe(entry.key);
      } on Exception {
        // Ignore unsubscribe errors during destroy
      }
    }
    nostrSignaling.destroy();
    _notifyClose();
    _signalCallbacks.clear();
    _errorCallbacks.clear();
    _closeCallbacks.clear();
    _cachedSignals.clear();
    _subscribedPeers.clear();
    _eventCallbacks.clear();
  }

  @override
  Future<IdAccountType> getIdAccount() async => accountId;

  @override
  Future<SignalErmes> getSignal(
    IdAccountType from, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _cachedSignals[from];
      if (cached != null) {
        return cached;
      }
    }
    try {
      final bytes = await nostrSignaling.retrieveLast(from);
      final signalString = utf8.decode(bytes);
      final signal = SignalErmes.fromString(signalString);
      _cachedSignals[from] = signal;
      return signal;
    } on Exception catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {
    try {
      final bytes = utf8.encode(signal.toString());
      await nostrSignaling.publish(bytes);
      _notifySignal(signal, to);
    } on Object catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  @override
  void onSignal(
    void Function(ISignalErmes data) callback, [
    IdAccountType? from,
  ]) {
    _signalCallbacks[from] = callback;
    if (from != null && !_subscribedPeers.contains(from)) {
      _subscribeToPeer(from);
    }
  }

  void _subscribeToPeer(IdAccountType from) {
    _subscribedPeers.add(from);
    final ec = EventCallback(
      (id, data) {
        try {
          final signalString = utf8.decode(data);
          final signal = SignalErmes.fromString(signalString);
          _cachedSignals[from] = signal;
          if (_signalCallbacks.containsKey(from)) {
            _signalCallbacks[from]?.call(signal);
          }
    } on Object catch (e) {
          _notifyError(e);
        }
      },
      maxRecords: maxDedupRecords,
    );
    _eventCallbacks[from] = ec;
    nostrSignaling.subscribe(from, ec);
  }

  @override
  void onError(void Function(Object err) callback) {
    _errorCallbacks.add(callback);
  }

  @override
  void onClose(void Function() callback) {
    _closeCallbacks.add(callback);
  }

  @override
  Future<void> removeAllListeners() async {
    _signalCallbacks.clear();
    _errorCallbacks.clear();
    _closeCallbacks.clear();
  }

  @override
  Future<bool> isConnected() async => nostrSignaling.isConnected();

  void _notifySignal(ISignalErmes signal, IdAccountType? from) {
    if (from != null && _signalCallbacks.containsKey(from)) {
      _signalCallbacks[from]?.call(signal);
    }
    if (_signalCallbacks.containsKey(null)) {
      _signalCallbacks[null]?.call(signal);
    }
  }

  void _notifyError(Object error) {
    for (final callback in _errorCallbacks) {
      callback(error);
    }
  }

  void _notifyClose() {
    for (final callback in _closeCallbacks) {
      callback();
    }
  }
}
