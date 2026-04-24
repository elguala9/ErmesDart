import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';

class DockerErmesConfig {
  const DockerErmesConfig({
    required this.rpcUrl,
    required this.contractAddress,
    required this.privateKeyHex,
    required this.accountId,
    required this.stunHost,
    required this.stunPort,
    required this.shspPort,
  });

  factory DockerErmesConfig.fromEnv() => DockerErmesConfig(
    rpcUrl: Platform.environment['RPC_URL'] ?? 'http://ganache:8545',
    contractAddress: Platform.environment['CONTRACT_ADDRESS']
        ?? '0x5FbDB2315678afecb367f032d93F642f64180aa3',
    privateKeyHex: Platform.environment['PRIVATE_KEY_HEX'] ?? '',
    accountId: Platform.environment['ACCOUNT_ID'] ?? '',
    stunHost: Platform.environment['STUN_HOST'] ?? 'coturn',
    stunPort: int.parse(Platform.environment['STUN_PORT'] ?? '3478'),
    shspPort: int.parse(Platform.environment['SHSP_PORT'] ?? '0'),
  );

  final String rpcUrl;
  final String contractAddress;
  final String privateKeyHex;
  final String accountId;
  final String stunHost;
  final int stunPort;
  final int shspPort;
}

Future<OrcErmes> createDockerOrcErmes(DockerErmesConfig config) async {
  final contract = await createSignalingContract(
    rpcUrl: config.rpcUrl,
    contractAddress: config.contractAddress,
    privateKeyHex: config.privateKeyHex,
  );

  return OrcErmesAdvancedFactory.createWithCustomStun(
    contract: contract,
    accountId: config.accountId,
    stunServer: config.stunHost,
    stunPort: config.stunPort,
    localShspPort: config.shspPort == 0 ? null : config.shspPort,
  );
}
