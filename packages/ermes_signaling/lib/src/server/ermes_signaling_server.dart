import 'dart:async';
import 'dart:convert';

import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../support/ermes_signal_type.dart';
import '../support/exceptions.dart';
import 'ermes_signaling_server_factories.dart';
import 'ermes_signaling_server_listeners.dart';
import 'ermes_signaling_server_subscriptions.dart';

/// Default number of records kept for de-duplicating received signals.
const int defaultMaxDedupRecords = 1000;

/// Implementation of IErmesSignalingServer using INostrSignaling.
///
/// Provides peer discovery and connection establishment using Nostr-based
/// signaling for P2P communication.
@dependencyInjectable
class ErmesSignalingServer implements IErmesSignalingServer {
  /// Creates a server backed by a Nostr signaling client for the given account.
  ///
  /// [maxDedupRecords] is nullable so dependency injection can leave it
  /// unregistered and still fall back to [defaultMaxDedupRecords].
  ErmesSignalingServer({
    required this.nostrSignaling,
    required this.accountId,
    int? maxDedupRecords,
  }) : maxDedupRecords = maxDedupRecords ?? defaultMaxDedupRecords;

  factory ErmesSignalingServer.dependencyInjectionFactory({
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) {
    // GENERATED CODE - DO NOT MODIFY BY HAND
    final nostrSignaling = RegistryManager.instance
        .getInstance<INostrSignaling>(
          key: key,
        ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final accountId = RegistryManager.instance.getInstance<IdAccountType>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final maxDedupRecords = RegistryManager.instance.tryGetInstance<int>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesSignalingServer(
      // GENERATED CODE - DO NOT MODIFY BY HAND
      nostrSignaling: nostrSignaling, // GENERATED CODE - DO NOT MODIFY BY HAND
      accountId: accountId, // GENERATED CODE - DO NOT MODIFY BY HAND
      maxDedupRecords:
          maxDedupRecords, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Builds a server from explicit Nostr key pair and relay configuration.
  static Future<ErmesSignalingServer> fromKeys({
    required String pubkey,
    required String privkey,
    required IdAccountType accountId,
    List<String> relayUrls = const ['wss://relay.damus.io'],
    bool useCompression = false,
    int maxDedupRecords = 1000,
  }) => ermesSignalingServerFromKeys(
    pubkey: pubkey,
    privkey: privkey,
    accountId: accountId,
    relayUrls: relayUrls,
    useCompression: useCompression,
    maxDedupRecords: maxDedupRecords,
  );

  /// Builds a server by loading Nostr configuration from a JSON file.
  static Future<ErmesSignalingServer> fromConfig({
    required IdAccountType accountId,
    String configPath = 'nostr_config.json',
    bool useCompression = false,
    int maxDedupRecords = 1000,
  }) => ermesSignalingServerFromConfig(
    accountId: accountId,
    configPath: configPath,
    useCompression: useCompression,
    maxDedupRecords: maxDedupRecords,
  );

  /// Underlying Nostr signaling client used to publish and retrieve events.
  final INostrSignaling nostrSignaling;

  /// Local account identifier this server operates on behalf of.
  final IdAccountType accountId;

  /// Maximum number of records kept for de-duplicating received signals.
  final int maxDedupRecords;

  /// Registry of signal, error and close listeners.
  final ErmesSignalingServerListeners _listeners =
      ErmesSignalingServerListeners();

  /// Lazily created subscription manager, or null before first use.
  ErmesSignalingServerSubscriptions? _subsOrNull;

  /// Lazily instantiates and returns the subscription manager.
  ErmesSignalingServerSubscriptions get _subs =>
      _subsOrNull ??= ErmesSignalingServerSubscriptions(
        nostrSignaling: nostrSignaling,
        listeners: _listeners,
        maxDedupRecords: maxDedupRecords,
      );

  /// Unsubscribes from all peers, tears down the client and notifies close.
  @override
  Future<void> destroy() async {
    final subs = _subsOrNull;
    if (subs != null) {
      await subs.unsubscribeAll();
    }
    await nostrSignaling.destroy();
    _listeners
      ..notifyClose()
      ..clear();
    subs?.clear();
  }

  /// Returns the local account identifier.
  @override
  Future<IdAccountType> getIdAccount() async => accountId;

  /// Retrieves the latest signal published by [from].
  ///
  /// Default: reads the relay and returns the newest of the relay answer and
  /// the unexpired cached signal. When the relay has nothing (empty answer,
  /// malformed event, network error) the unexpired cached signal is returned;
  /// it throws only when neither the relay nor the cache has one.
  ///
  /// [forceRefresh]: relay only. Returns exactly what the relay holds, or
  /// throws; the cache is never served (it is still updated, never regressed).
  @override
  Future<SignalErmes> getSignal(
    IdAccountType from, {
    bool forceRefresh = false,
  }) async {
    final cached = _subs.cachedSignals[from];
    final usableCache = cached != null && !cached.isExpired() ? cached : null;
    try {
      final signal = await _readRelay(from);
      final newest = usableCache != null &&
              usableCache.epochTimestampStartConversation >
                  signal.epochTimestampStartConversation
          ? usableCache
          : signal;
      _subs.cachedSignals[from] = newest;
      return forceRefresh ? signal : newest;
    } on Exception catch (e) {
      if (!forceRefresh && usableCache != null) {
        return usableCache;
      }
      _listeners.notifyError(e);
      rethrow;
    }
  }

  /// Reads [from]'s last signal from the relay. An empty answer (the relay
  /// holds no event yet) surfaces as a [SignalingException], not an
  /// ArgumentError from `SignalErmes.fromString`, so polling callers catch it
  /// with `on Exception` and retry.
  Future<SignalErmes> _readRelay(IdAccountType from) async {
    final bytes = await nostrSignaling.retrieveLast(from);
    if (bytes.isEmpty) {
      throw SignalingException('No signal published yet for $from');
    }
    return _parseOrDiscard(from, bytes);
  }

  /// Parses a relay payload, discarding any event that does not respect the
  /// wire format (e.g. a legacy 8/9-field signal still held by a public relay
  /// from an older publisher). The discard surfaces as a [SignalingException]
  /// — the same "no usable signal yet" state as an empty relay — so polling
  /// callers retry instead of aborting on an [ArgumentError].
  SignalErmes _parseOrDiscard(IdAccountType from, List<int> bytes) {
    final raw = utf8.decode(bytes, allowMalformed: true);
    final parts = raw.split('|');
    final wellFormed = parts.length == SignalErmes.fieldCount &&
        parts[SignalErmes.fieldCount - 1].isNotEmpty &&
        parts.sublist(5, 9).every((p) => int.tryParse(p) != null);
    if (!wellFormed) {
      throw SignalingException('Discarded malformed signal from $from');
    }
    return SignalErmes.fromString(raw);
  }

  /// Publishes the given signal, optionally targeting a specific recipient.
  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {
    try {
      await nostrSignaling.publish(utf8.encode(signal.toString()));
      _listeners.notifySignal(signal, to);
    } on Object catch (e) {
      _listeners.notifyError(e);
      rethrow;
    }
  }

  /// Registers a signal callback and subscribes to [from] when provided.
  @override
  void onSignal(
    void Function(ISignalErmes data) callback, [
    IdAccountType? from,
  ]) {
    _listeners.onSignal(callback, from);
    if (from != null) {
      _subs.subscribeToPeer(from);
    }
  }

  /// Registers a callback invoked when an error occurs.
  @override
  void onError(void Function(Object err) callback) =>
      _listeners.onError(callback);

  /// Registers a callback invoked when the connection closes.
  @override
  void onClose(void Function() callback) => _listeners.onClose(callback);

  /// Removes all registered listeners.
  @override
  Future<void> removeAllListeners() async => _listeners.clear();

  /// Reports whether the underlying Nostr client is connected.
  @override
  Future<bool> isConnected() async => nostrSignaling.isConnected();
}
