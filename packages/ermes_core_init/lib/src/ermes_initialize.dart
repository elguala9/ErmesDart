import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';

import 'ermes_injector.dart';

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
  String? stunHost,
  int stunPort = 19302,
  bool connectSignaling = false,
  bool registerIdHandler = false,
  bool registerMessageControl = false,
  OrcSignalRepublishSettings signalRepublish =
      const OrcSignalRepublishSettings(),
  int symmetricNatMaxFailedAttempts = defaultSymmetricNatMaxFailedAttempts,
}) async {
  await ErmesInjector(
    keyPair: keyPair,
    relayUrls: relayUrls,
    accountId: accountId,
    keyExchange: keyExchange,
    useCompression: useCompression,
    initializeStunShsp: initializeStunShsp,
    stunHost: stunHost,
    stunPort: stunPort,
    connectSignaling: connectSignaling,
    registerIdHandler: registerIdHandler,
    registerMessageControl: registerMessageControl,
    signalRepublish: signalRepublish,
    symmetricNatMaxFailedAttempts: symmetricNatMaxFailedAttempts,
  ).register(key: key);
  return getIOrcErmes(key: key);
}

/// Resolves the orchestrator registered under [key].
IOrcErmes<BookData> getIOrcErmes({String key = 'default'}) =>
    RegistryManager.instance.getInstance<IOrcErmes<BookData>>(key: key);
