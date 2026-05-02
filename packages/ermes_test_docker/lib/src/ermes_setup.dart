import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';

class DockerErmesConfig {
  const DockerErmesConfig({
    required this.pubkey,
    required this.privkey,
    required this.accountId,
    required this.stunHost,
    required this.stunPort,
    required this.shspPort,
    this.relayUrls = const ['wss://relay.damus.io'],
  });

  factory DockerErmesConfig.fromEnv() => DockerErmesConfig(
    pubkey: Platform.environment['NOSTR_PUBKEY'] ?? '',
    privkey: Platform.environment['NOSTR_PRIVKEY'] ?? '',
    accountId: Platform.environment['ACCOUNT_ID'] ?? '',
    stunHost: Platform.environment['STUN_HOST'] ?? 'coturn',
    stunPort: int.parse(Platform.environment['STUN_PORT'] ?? '3478'),
    shspPort: int.parse(Platform.environment['SHSP_PORT'] ?? '0'),
    relayUrls: (Platform.environment['NOSTR_RELAYS'] ?? 'wss://relay.damus.io')
        .split(','),
  );

  final String pubkey;
  final String privkey;
  final String accountId;
  final String stunHost;
  final int stunPort;
  final int shspPort;
  final List<String> relayUrls;
}

Future<OrcErmes> createDockerOrcErmes(DockerErmesConfig config) async {
  final signalingServer = await ErmesSignalingServerFactory.createFromKeys(
    pubkey: config.pubkey,
    privkey: config.privkey,
    relayUrls: config.relayUrls,
    accountId: config.accountId,
  );

  return OrcErmesAdvancedFactory.createWithStun(
    signalingServer: signalingServer,
    accountId: config.accountId,
    stunServer: config.stunHost,
    stunPort: config.stunPort,
    localShspPort: config.shspPort == 0 ? null : config.shspPort,
  );
}
