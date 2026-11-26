import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_message_control/ermes_message_control.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_injector_steps.dart';
import 'ermes_orchestrator_settings_injection.dart';
import 'ermes_storage_injection.dart';
export 'ermes_initialize.dart';

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
    this.stunHost,
    this.stunPort = 19302,
    this.connectSignaling = false,
    this.registerIdHandler = false,
    this.registerMessageControl = false,
    this.signalRepublish = const OrcSignalRepublishSettings(),
    this.symmetricNatMaxFailedAttempts = defaultSymmetricNatMaxFailedAttempts,
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

  /// STUN server host to point the `ipv4` handler at once bound. Ignored
  /// unless [initializeStunShsp] is true; null keeps the handler's own
  /// default.
  final String? stunHost;

  /// STUN server UDP port to pair with [stunHost].
  final int stunPort;

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

  /// Signal republisher started by the orchestrator (on by default).
  final OrcSignalRepublishSettings signalRepublish;

  /// Consecutive failed dials before a peer is flagged as behind a symmetric
  /// NAT; 0 (the default) disables detection.
  final int symmetricNatMaxFailedAttempts;

  /// Registers the whole stack under [key].
  ///
  /// Everything is connected lazily, so nothing is constructed until it is
  /// first resolved — except the STUN/SHSP sockets and the relay connection,
  /// which are genuinely eager.
  Future<void> register({String key = 'default'}) async {
    registerErmesStorageHandlers(key: key);

    if (registerIdHandler) {
      await const ErmesIdHandlerInjector().registerAllSingletonsIdHandlerAsync(
        key: key,
      );
    }
    if (registerMessageControl) {
      await const ErmesMessageControlInjector()
          .registerAllSingletonsMessageControlAsync(key: key);
    }

    await registerCipherIfAbsent(key: key, keyExchange: keyExchange);

    await ErmesSignalingInjector(
      keyPair: keyPair,
      relayUrls: relayUrls,
      accountId: accountId,
      useCompression: useCompression,
      initializeStunShsp: initializeStunShsp,
      connectSignaling: connectSignaling,
    ).registerAllSingletonsErmesSignalingAsync(key: key);

    final host = stunHost;
    if (initializeStunShsp && host != null) {
      configureStunServers(key: key, host: host, port: stunPort);
    }

    registerEncryptionFlag(key: key);
    registerOrchestratorSettings(
      key: key,
      signalRepublish: signalRepublish,
      symmetricNatMaxFailedAttempts: symmetricNatMaxFailedAttempts,
    );
    await const ErmesCoreInjector().registerAllSingletonsErmesCoreAsync(
      key: key,
    );
  }
}
