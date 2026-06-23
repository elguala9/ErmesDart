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

/// Implementation of IErmesSignalingServer using INostrSignaling.
///
/// Provides peer discovery and connection establishment using Nostr-based
/// signaling for P2P communication.
@isSingleton
class ErmesSignalingServer implements IErmesSignalingServer {
  ErmesSignalingServer({
    required this.nostrSignaling,
    required this.accountId,
    this.maxDedupRecords = 1000,
  });

  ErmesSignalingServer.emptyForDI() : maxDedupRecords = 1000;

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

  @isInjected
  late INostrSignaling nostrSignaling;
  @isInjected
  late IdAccountType accountId;

  final int maxDedupRecords;
  final ErmesSignalingServerListeners _listeners =
      ErmesSignalingServerListeners();
  ErmesSignalingServerSubscriptions? _subsOrNull;

  ErmesSignalingServerSubscriptions get _subs =>
      _subsOrNull ??= ErmesSignalingServerSubscriptions(
        nostrSignaling: nostrSignaling,
        listeners: _listeners,
        maxDedupRecords: maxDedupRecords,
      );

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

  @override
  Future<IdAccountType> getIdAccount() async => accountId;

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
      _subs.cachedSignals[from] = signal;
      return signal;
    } on Exception catch (e) {
      _listeners.notifyError(e);
      rethrow;
    }
  }

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

  @override
  void onError(void Function(Object err) callback) =>
      _listeners.onError(callback);

  @override
  void onClose(void Function() callback) => _listeners.onClose(callback);

  @override
  Future<void> removeAllListeners() async => _listeners.clear();

  @override
  Future<bool> isConnected() async => nostrSignaling.isConnected();
}
