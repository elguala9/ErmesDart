import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'ermes_signaling_server.dart';

/// Prefix of the registry keys the standalone factories park their Nostr
/// client under.
///
/// These factories are the non-DI entry points: each builds one signaling
/// client and hands it straight to the returned server. They still need
/// somewhere in the registry to build it, so every call gets its own key —
/// otherwise two servers created in the same process (e.g. both sides of a
/// two-peer test) would overwrite each other's client. `default` is left to
/// the injector-driven graph.
const String ermesSignalingFactoryKeyPrefix = 'ermes_signaling_factory';

/// Counts factory calls so each one registers under a distinct key.
int _factoryCallCount = 0;

/// Creates a signaling server from Nostr key strings.
///
/// Registers and connects an [INostrSignaling] through
/// [NostrSignalingInjection] before wrapping it in an [ErmesSignalingServer].
Future<ErmesSignalingServer> ermesSignalingServerFromKeys({
  required String pubkey,
  required String privkey,
  required IdAccountType accountId,
  List<String> relayUrls = const ['wss://relay.damus.io'],
  bool useCompression = false,
  int maxDedupRecords = defaultMaxDedupRecords,
}) async {
  final keyPair = NostrKeys.fromHex(
    privateKeyHex: privkey,
    publicKeyHex: pubkey,
  );
  final nostrSignaling = await _registerAndConnect(
    NostrSignalingInjection(
      keyPair: keyPair,
      relayUrls: relayUrls,
      useCompression: useCompression,
    ),
  );
  return ErmesSignalingServer(
    nostrSignaling: nostrSignaling,
    accountId: accountId,
    maxDedupRecords: maxDedupRecords,
  );
}

/// Creates a signaling server from a [NostrConfig] JSON file on disk.
Future<ErmesSignalingServer> ermesSignalingServerFromConfig({
  required IdAccountType accountId,
  String configPath = NostrConfig.defaultConfigPath,
  bool useCompression = false,
  int maxDedupRecords = defaultMaxDedupRecords,
}) async {
  final nostrSignaling = await _registerAndConnect(
    NostrSignalingInjection(
      configPath: configPath,
      useCompression: useCompression,
    ),
  );
  return ErmesSignalingServer(
    nostrSignaling: nostrSignaling,
    accountId: accountId,
    maxDedupRecords: maxDedupRecords,
  );
}

/// Runs [injection] under a fresh key, then opens the relay WebSockets so the
/// returned client can actually publish and subscribe.
Future<INostrSignaling> _registerAndConnect(
  NostrSignalingInjection injection,
) async {
  _factoryCallCount++;
  final key = '$ermesSignalingFactoryKeyPrefix$_factoryCallCount';
  await injection.registerAllSingletonsNostrSignalingAsync(key: key);
  final nostrSignaling =
      RegistryManager.instance.getInstance<INostrSignaling>(key: key);
  await nostrSignaling.connect();
  return nostrSignaling;
}
