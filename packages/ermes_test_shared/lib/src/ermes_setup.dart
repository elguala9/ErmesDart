import 'dart:io';

import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// Configuration for spinning up an [OrcErmes] instance inside the Docker
/// test harness: identity keys, STUN/SHSP endpoints, relay URLs and the
/// well-known peer pubkeys used by the multi-peer scenarios.
class DockerErmesConfig {
  /// Creates a config with explicit identity, STUN and relay parameters.
  const DockerErmesConfig({
    required this.pubkey,
    required this.privkey,
    required this.accountId,
    required this.stunHost,
    required this.stunPort,
    required this.alicePubkey,
    required this.bobPubkey,
    required this.charliePubkey,
    this.shspPort,
    this.relayUrls = const ['wss://relay.damus.io'],
  });

  /// Builds a config from environment variables, substituting sensible
  /// defaults (placeholder pubkeys, coturn host, default relay) when absent.
  factory DockerErmesConfig.fromEnv() => DockerErmesConfig(
        pubkey: Platform.environment['NOSTR_PUBKEY'] ?? '',
        privkey: Platform.environment['NOSTR_PRIVKEY'] ?? '',
        accountId: Platform.environment['ACCOUNT_ID'] ?? '',
        stunHost: Platform.environment['STUN_HOST'] ?? 'coturn',
        stunPort: int.parse(Platform.environment['STUN_PORT'] ?? '3478'),
        shspPort: Platform.environment['SHSP_PORT'] != null
            ? int.tryParse(Platform.environment['SHSP_PORT']!)
            : null,
        alicePubkey:
            Platform.environment['ALICE_PUBKEY'] ?? 'a' * 64,
        bobPubkey:
            Platform.environment['BOB_PUBKEY'] ?? 'b' * 64,
        charliePubkey:
            Platform.environment['CHARLIE_PUBKEY'] ?? 'c' * 64,
        relayUrls:
            (Platform.environment['NOSTR_RELAYS'] ?? 'wss://relay.damus.io')
                .split(','),
      );

  /// This peer's Nostr public key.
  final String pubkey;

  /// This peer's Nostr private key.
  final String privkey;

  /// Account identifier used for signaling/book lookups.
  final String accountId;

  /// Hostname of the STUN server.
  final String stunHost;

  /// UDP port of the STUN server.
  final int stunPort;

  /// Optional fixed SHSP port; null lets the handler pick one.
  final int? shspPort;

  /// Well-known public key for the "alice" test peer.
  final String alicePubkey;

  /// Well-known public key for the "bob" test peer.
  final String bobPubkey;

  /// Well-known public key for the "charlie" test peer.
  final String charliePubkey;

  /// Nostr relay WebSocket URLs to publish/subscribe signals through.
  final List<String> relayUrls;
}

/// Boots the full Ermes stack (STUN/SHSP, DI, signaling) from [config] and
/// returns a connected [IOrcErmes] ready to open peer connections.
Future<IOrcErmes<BookData>> createDockerOrcErmes(
    DockerErmesConfig config) async {
  final keyPair = NostrKeyPair(
    privateKey: config.privkey,
    publicKey: config.pubkey,
  );

  await initializePointStunShsp();
  SingletonDIAccess.get<IStunShspHandler>()
    .setStunServer(config.stunHost, config.stunPort);

  await initialPointErmesCore(
    keyPair: keyPair,
    relayUrls: config.relayUrls,
    accountId: config.accountId,
    // Open the Nostr relay WebSockets before any signal publish. Without
    // this the DI path never connects and every setSignal fails with
    // "All relays failed to publish".
    connectSignaling: true,
  );

  return getIOrcErmes();
}
