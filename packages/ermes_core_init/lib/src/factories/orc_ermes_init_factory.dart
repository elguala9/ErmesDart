import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

import '../initial_point/initial_point_ermes_core.dart';
import '../initial_point/initial_point_ermes_core_registry.dart';

/// Autonomous factories that return a ready-to-use [IOrcErmes] by delegating
/// to the initial points, which own all DI / registry wiring.
///
/// Both methods cover every dependency [IOrcErmes.openConnection] needs at
/// runtime: SHSP socket + STUN ([initializeStunShsp]) and a live relay
/// connection ([connectSignaling]). [keyPair] (Nostr identity) and [accountId]
/// remain mandatory for a working orchestrator.
///
///   * [createSingleton] uses the singleton DI container — one global instance.
///   * [createInstance] uses the keyed registry — multiple instances coexist.
class OrcErmesInitFactory {
  /// Private constructor — this class exposes only static factory methods.
  OrcErmesInitFactory._();

  /// Builds the singleton [IOrcErmes] via [initialPointErmesCore].
  ///
  /// With [initializeStunShsp] and [connectSignaling] both true (the default)
  /// the returned orchestrator is ready to open connections immediately.
  static Future<IOrcErmes<BookData>> createSingleton({
    NostrKeyPair? keyPair,
    List<String>? relayUrls,
    bool useCompression = false,
    IdAccountType? accountId,
    bool initializeStunShsp = true,
    bool connectSignaling = true,
  }) async {
    await initialPointErmesCore(
      keyPair: keyPair,
      relayUrls: relayUrls,
      useCompression: useCompression,
      accountId: accountId,
      initializeStunShsp: initializeStunShsp,
      connectSignaling: connectSignaling,
    );
    return getIOrcErmes();
  }

  /// Builds a keyed [IOrcErmes] via [initialPointErmesCoreRegistry].
  ///
  /// With [initializeStunShsp] and [connectSignaling] both true (the default)
  /// the returned orchestrator is ready to open connections immediately.
  static Future<IOrcErmes<BookData>> createInstance({
    String key = 'default',
    NostrKeyPair? keyPair,
    List<String>? relayUrls,
    bool useCompression = false,
    IdAccountType? accountId,
    bool initializeStunShsp = true,
    bool connectSignaling = true,
  }) async {
    await initialPointErmesCoreRegistry(
      key: key,
      keyPair: keyPair,
      relayUrls: relayUrls,
      useCompression: useCompression,
      accountId: accountId,
      initializeStunShsp: initializeStunShsp,
      connectSignaling: connectSignaling,
    );
    return getIOrcErmesFromRegistry(key: key);
  }
}
