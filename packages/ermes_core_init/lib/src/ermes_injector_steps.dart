import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// Points both family STUN handlers under [key] at [host]:[port]. The IPv6
/// handler is optional: a host without IPv6 simply has none registered.
void configureStunServers({
  required String key,
  required String host,
  required int port,
}) {
  for (final family in const ['ipv4', 'ipv6']) {
    RegistryManager.instance
        .getInstanceNullable<IStunShspHandler>(key: key, subkey: family)
        ?.setStunServer(host, port);
  }
}

/// Registers the cipher graph unless a key pair is already present under
/// [key], preserving the previous "only initialise if absent" behaviour so a
/// caller that supplied its own identity keeps it.
Future<void> registerCipherIfAbsent({
  required String key,
  IKeyExchange? keyExchange,
}) async {
  final existing = RegistryManager.instance.getInstanceNullable<IKeyExchange>(
    key: key,
  );
  if (existing != null) {
    return;
  }
  await ErmesCipherInjector(
    keyExchange: keyExchange,
  ).registerAllSingletonsErmesCipherAsync(key: key);
}

/// Tells `OrcErmes` whether to encrypt, based on whether a key pair actually
/// made it into the registry. Without this the orchestrator defaults to
/// encryption-on and then has no key to derive shared secrets from.
void registerEncryptionFlag({required String key}) {
  final registry = RegistryManager.instance;
  final hasKeyExchange =
      registry.getInstanceNullable<IKeyExchange>(key: key) != null;
  registry.setInstance<bool>(hasKeyExchange, key: key);
}
