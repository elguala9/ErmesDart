import 'dart:io';

import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

class DockerErmesConfig {
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

  final String pubkey;
  final String privkey;
  final String accountId;
  final String stunHost;
  final int stunPort;
  final int? shspPort;
  final String alicePubkey;
  final String bobPubkey;
  final String charliePubkey;
  final List<String> relayUrls;
}

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
  );

  return getIOrcErmes();
}
