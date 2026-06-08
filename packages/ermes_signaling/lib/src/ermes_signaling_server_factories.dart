import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

import 'ermes_signaling_server.dart';

/// Creates a signaling server from Nostr key strings.
///
/// Uses [initialPointNostrSignaling] to register the [INostrSignaling]
/// instance in the singleton DI container.
Future<ErmesSignalingServer> ermesSignalingServerFromKeys({
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
Future<ErmesSignalingServer> ermesSignalingServerFromConfig({
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
