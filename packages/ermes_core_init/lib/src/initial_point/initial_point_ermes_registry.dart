import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

import 'initial_point_ermes_core_registry.dart';

/// Registry composition root that creates and returns an [IOrcErmes].
///
/// Wraps [initialPointErmesCoreRegistry] and returns the registered
/// instance directly, enabling a linear call style:
///
/// ```dart
/// final orc = await initialPointErmesRegistry(keyPair: myKeyPair);
/// final orc2 = await initialPointErmesRegistry(key: 'alt', keyPair: altPair);
/// ```
Future<IOrcErmes<BookData>> initialPointErmesRegistry({
  String key = 'default',
  NostrKeyPair? keyPair,
  List<String>? relayUrls,
  bool useCompression = false,
  IdAccountType? accountId,
  bool initializeStunShsp = false,
  bool connectSignaling = false,
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
