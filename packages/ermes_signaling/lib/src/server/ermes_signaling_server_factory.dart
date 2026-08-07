
import 'package:iermes/iermes.dart';

import 'ermes_signaling_server.dart';

/// Factory for creating ErmesSignalingServer instances
///
/// This factory creates signaling server instances that implement
/// the IErmesSignalingServer interface, encapsulating Nostr signaling
/// details so callers only need ermes_signaling.

class ErmesSignalingServerFactory {
  ErmesSignalingServerFactory._();

  /// Creates a signaling server from Nostr key strings.
  ///
  /// [pubkey] The Nostr public key hex
  /// [privkey] The Nostr private key hex
  /// [relayUrls] List of relay WebSocket URLs
  /// [accountId] The account ID of the current user
  static Future<ErmesSignalingServer> createFromKeys({
    required String pubkey,
    required String privkey,
    required IdAccountType accountId,
    List<String> relayUrls = const ['wss://relay.damus.io'],
    bool useCompression = false,
    int maxDedupRecords = defaultMaxDedupRecords,
  }) =>
      ErmesSignalingServer.fromKeys(
        pubkey: pubkey,
        privkey: privkey,
        accountId: accountId,
        relayUrls: relayUrls,
        useCompression: useCompression,
        maxDedupRecords: maxDedupRecords,
      );

  /// Creates a signaling server from a [NostrConfig] JSON file.
  ///
  /// [configPath] Path to the JSON config file (default: nostr_config.json)
  /// [accountId] The account ID of the current user
  static Future<ErmesSignalingServer> createFromConfig({
    required IdAccountType accountId,
    String configPath = 'nostr_config.json',
    bool useCompression = false,
    int maxDedupRecords = defaultMaxDedupRecords,
  }) =>
      ErmesSignalingServer.fromConfig(
        accountId: accountId,
        configPath: configPath,
        useCompression: useCompression,
        maxDedupRecords: maxDedupRecords,
      );
}
