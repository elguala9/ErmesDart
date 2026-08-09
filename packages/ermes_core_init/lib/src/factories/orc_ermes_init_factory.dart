import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

import '../ermes_injector.dart';

/// Autonomous factory that returns a ready-to-use [IOrcErmes] by delegating to
/// [initializeErmes], which owns all registry wiring.
///
/// It covers every dependency [IOrcErmes.openConnection] needs at runtime: the
/// SHSP socket + STUN ([initializeStunShsp]) and a live relay connection
/// ([connectSignaling]). [keyPair] (Nostr identity) and [accountId] remain
/// mandatory for a working orchestrator.
class OrcErmesInitFactory {
  /// Private constructor — this class exposes only static factory methods.
  OrcErmesInitFactory._();

  /// Builds an [IOrcErmes] registered under [key].
  ///
  /// With [initializeStunShsp] and [connectSignaling] both true (the default)
  /// the returned orchestrator is ready to open connections immediately.
  ///
  /// Since singleton_manager 2.x there is one keyed registry rather than a
  /// separate global container, so this single method replaces the former
  /// `createSingleton` / `createInstance` pair: the default [key] is what
  /// `createSingleton` used to give you, and any other [key] yields an
  /// independent stack.
  static Future<IOrcErmes<BookData>> create({
    String key = 'default',
    NostrKeyPair? keyPair,
    List<String>? relayUrls,
    IdAccountType? accountId,
    IKeyExchange? keyExchange,
    bool useCompression = false,
    bool initializeStunShsp = true,
    bool connectSignaling = true,
  }) =>
      initializeErmes(
        key: key,
        keyPair: keyPair,
        relayUrls: relayUrls,
        accountId: accountId,
        keyExchange: keyExchange,
        useCompression: useCompression,
        initializeStunShsp: initializeStunShsp,
        connectSignaling: connectSignaling,
      );
}
