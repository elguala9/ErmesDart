import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'ermes_storage_injection.dart';

/// Composition root for the whole Ermes stack.
///
/// Registers every package's graph into [RegistryManager] under one [key], in
/// dependency order. Composition is by delegation rather than by mixing in the
/// `MainInjection*` mixins, because the inputs each graph needs live on the
/// per-package injector classes, not on the mixins.
///
/// Each [key] is an independent graph, so two peers can be booted side by side
/// in one process without sharing a single instance.
class ErmesInjector {
  /// Creates a composition root for the Ermes stack.
  const ErmesInjector({
    this.keyPair,
    this.relayUrls,
    this.accountId,
    this.keyExchange,
    this.useCompression = false,
    this.initializeStunShsp = false,
    this.connectSignaling = false,
    this.registerIdHandler = false,
    this.registerMessageControl = false,
  });

  /// Nostr key pair identifying this peer on the signaling network.
  final NostrKeyPair? keyPair;

  /// Relay WebSocket URLs to publish and subscribe signals through.
  final List<String>? relayUrls;

  /// This peer's account identifier.
  final IdAccountType? accountId;

  /// Existing key pair to encrypt with; a fresh ECDH pair is generated when
  /// null.
  final IKeyExchange? keyExchange;

  /// Whether signal payloads are gzip-compressed.
  final bool useCompression;

  /// Whether to bind the SHSP sockets and STUN handlers.
  final bool initializeStunShsp;

  /// Whether to open the relay WebSockets straight away.
  final bool connectSignaling;

  /// Whether to register the ID-handler graph.
  ///
  /// Off by default: nothing in the core path resolves it — the connection
  /// opener builds its own ID handler — and its storage repository would
  /// persist a counter to disk.
  final bool registerIdHandler;

  /// Whether to register the message-control graph.
  ///
  /// Off by default, matching the core path, which does not resolve it.
  final bool registerMessageControl;

  /// Registers the whole stack under [key].
  ///
  /// Everything is connected lazily, so nothing is constructed until it is
  /// first resolved — except the STUN/SHSP sockets and the relay connection,
  /// which are genuinely eager.
  Future<void> register({String key = 'default'}) async {
    registerErmesStorageHandlers(key: key);

    if (registerIdHandler) {
      await const ErmesIdHandlerInjector()
          .registerAllSingletonsIdHandlerAsync(key: key);
    }
    if (registerMessageControl) {
      await const ErmesMessageControlInjector()
          .registerAllSingletonsMessageControlAsync(key: key);
    }

    await _registerCipher(key: key);

    await ErmesSignalingInjector(
      keyPair: keyPair,
      relayUrls: relayUrls,
      accountId: accountId,
      useCompression: useCompression,
      initializeStunShsp: initializeStunShsp,
      connectSignaling: connectSignaling,
    ).registerAllSingletonsErmesSignalingAsync(key: key);

    _registerEncryptionFlag(key: key);
    await const ErmesCoreInjector().registerAllSingletonsErmesCoreAsync(
      key: key,
    );
  }

  /// Registers the cipher graph unless a key pair is already present under
  /// [key], preserving the previous "only initialise if absent" behaviour so a
  /// caller that supplied its own identity keeps it.
  Future<void> _registerCipher({required String key}) async {
    final existing =
        RegistryManager.instance.getInstanceNullable<IKeyExchange>(key: key);
    if (existing != null) {
      return;
    }
    await ErmesCipherInjector(keyExchange: keyExchange)
        .registerAllSingletonsErmesCipherAsync(key: key);
  }

  /// Tells [OrcErmes] whether to encrypt, based on whether a key pair actually
  /// made it into the registry. Without this the orchestrator defaults to
  /// encryption-on and then has no key to derive shared secrets from.
  void _registerEncryptionFlag({required String key}) {
    final registry = RegistryManager.instance;
    final hasKeyExchange =
        registry.getInstanceNullable<IKeyExchange>(key: key) != null;
    registry.setInstance<bool>(hasKeyExchange, key: key);
  }
}

/// Registers the whole Ermes stack under [key] and returns the orchestrator.
///
/// Replaces the former `initialPointErmes*` family. Pass a distinct [key] per
/// peer to run several stacks side by side.
Future<IOrcErmes<BookData>> initializeErmes({
  String key = 'default',
  NostrKeyPair? keyPair,
  List<String>? relayUrls,
  IdAccountType? accountId,
  IKeyExchange? keyExchange,
  bool useCompression = false,
  bool initializeStunShsp = false,
  bool connectSignaling = false,
  bool registerIdHandler = false,
  bool registerMessageControl = false,
}) async {
  await ErmesInjector(
    keyPair: keyPair,
    relayUrls: relayUrls,
    accountId: accountId,
    keyExchange: keyExchange,
    useCompression: useCompression,
    initializeStunShsp: initializeStunShsp,
    connectSignaling: connectSignaling,
    registerIdHandler: registerIdHandler,
    registerMessageControl: registerMessageControl,
  ).register(key: key);
  return getIOrcErmes(key: key);
}

/// Resolves the orchestrator registered under [key].
IOrcErmes<BookData> getIOrcErmes({String key = 'default'}) =>
    RegistryManager.instance.getInstance<IOrcErmes<BookData>>(key: key);
