import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

import 'initial_point_ermes_core.dart';

/// Singleton composition root that creates and returns an [IOrcErmes].
///
/// Wraps [initialPointErmesCore] and returns the registered instance
/// directly, enabling a linear call style:
///
/// ```dart
/// final orc = await initialPointErmes(keyPair: myKeyPair);
/// ```
Future<IOrcErmes> initialPointErmes({
  NostrKeyPair? keyPair,
  List<String>? relayUrls,
  bool useCompression = false,
  IdAccountType? accountId,
  bool initializeStunShsp = false,
}) async {
  await initialPointErmesCore(
    keyPair: keyPair,
    relayUrls: relayUrls,
    useCompression: useCompression,
    accountId: accountId,
    initializeStunShsp: initializeStunShsp,
  );
  return getIOrcErmes();
}
