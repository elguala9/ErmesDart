import 'dart:async';
import 'dart:convert';

import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_signal_type.dart';
import 'ermes_signaling_server_factories.dart';
import 'ermes_signaling_server_listeners.dart';
import 'ermes_signaling_server_subscriptions.dart';
import 'exceptions.dart';
import 'package:singleton_manager/singleton_manager.dart';

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

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ErmesSignalingServer.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final nostrSignaling = RegistryManager.instance.getInstance<INostrSignaling>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final accountId = RegistryManager.instance.getInstance<IdAccountType>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final maxDedupRecords = RegistryManager.instance.tryGetInstance<int>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesSignalingServer( // GENERATED CODE - DO NOT MODIFY BY HAND
      nostrSignaling: nostrSignaling, // GENERATED CODE - DO NOT MODIFY BY HAND
      accountId: accountId, // GENERATED CODE - DO NOT MODIFY BY HAND
      maxDedupRecords: maxDedupRecords, // GENERATED CODE - DO NOT MODIFY BY HAND
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
  }) =>
      ermesSignalingServerFromKeys(
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
  }) =>
      ermesSignalingServerFromConfig(
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
    nostrSignaling.destroy();
    _listeners
      ..notifyClose()
      ..clear();
    subs?.clear();
  }

  /// Returns the local account identifier.
  @override
  Future<IdAccountType> getIdAccount() async => accountId;

  /// Retrieves the latest signal published by [from], using the cache unless
  /// [forceRefresh] is set or the cached entry is expired.
  @override
  Future<SignalErmes> getSignal(
    IdAccountType from, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _subs.cachedSignals[from];
      // Never serve a stale signal: an expired cache entry (e.g. a signal
      // persisted on the relay from an earlier session) would otherwise
      // mask a fresh one the peer publishes later.
      if (cached != null && !cached.isExpired()) {
        return cached;
      }
    }
    try {
      final bytes = await nostrSignaling.retrieveLast(from);
      // `retrieveLast` returns an empty list when the relay holds no event
      // yet for `from` — a normal "peer has not published" state, not a
      // malformed payload. Surface it as a SignalingException (an Exception)
      // so the polling callers (`_waitForPeerSignal`, the rendezvous loop)
      // catch it and retry, instead of letting `SignalErmes.fromString`
      // throw an ArgumentError (an Error) that escapes every `on Exception`
      // handler and aborts the whole connection attempt.
      if (bytes.isEmpty) {
        throw SignalingException('No signal published yet for $from');
      }
      final signal = SignalErmes.fromString(utf8.decode(bytes));
      // A relay can answer with an event OLDER than one already seen (another
      // relay's push, or an earlier fetch that raced this one): never let the
      // cache regress, and hand back the newest signal known for [from].
      final cached = _subs.cachedSignals[from];
      final newest = cached != null &&
              !cached.isExpired() &&
              cached.epochTimestampStartConversation >
                  signal.epochTimestampStartConversation
          ? cached
          : signal;
      _subs.cachedSignals[from] = newest;
      return newest;
    } on Exception catch (e) {
      _listeners.notifyError(e);
      rethrow;
    }
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
