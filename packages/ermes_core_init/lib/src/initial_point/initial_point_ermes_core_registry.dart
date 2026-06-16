import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'initial_point_ermes_cipher_registry.dart';
import 'initial_point_ermes_signaling_registry.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  _Wrap(this.value);

  final T value;
}

/// Registry-based variant of initialPointErmesCore.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
///
/// If [keyPair] is provided, calls [initialPointNostrSignalingRegistry]
/// internally to satisfy the [INostrSignaling] dependency.
///
/// If [initializeStunShsp] is true, calls [initializePointRegistryStunShsp]
/// to bind SHSP sockets and initialize STUN in the registry.
///
/// Prerequisites (when not auto-initialized):
///   - _Wrap<SignalingContract> (via key)
///   - _Wrap<IStunShspHandler>
///   - _Wrap<IShspSocket>
///   - (optional) call initialPointErmesCipherRegistry(key:) for encryption
Future<void> initialPointErmesCoreRegistry({
  String key = 'default',
  NostrKeyPair? keyPair,
  List<String>? relayUrls,
  bool useCompression = false,
  IdAccountType? accountId,
  bool initializeStunShsp = false,
  bool connectSignaling = false,
}) async {
  // 1. Signaling
  await initialPointErmesSignalingRegistry(
    key: key,
    keyPair: keyPair,
    relayUrls: relayUrls,
    useCompression: useCompression,
    accountId: accountId,
    initializeStunShsp: initializeStunShsp,
    connectSignaling: connectSignaling,
  );

  // 2. Cipher — only if not already initialised by the caller
  if (!RegistryAccess.contains<_Wrap<IKeyExchange>>(key)) {
    await initialPointErmesCipherRegistry(key: key);
  }

  // 3. Build OrcErmes directly from registry components
  final signalingServer = getIErmesSignalingServerFromRegistry(key: key);
  final signalingHandler = getIErmesSignalingHandlerFromRegistry(key: key);
  final bookService = getIErmesBookServiceFromRegistry(key: key);
  final socket = SingletonDIAccess.get<IShspSocket>();
  final enableEncryption = RegistryAccess.contains<_Wrap<IKeyExchange>>(key);

  final orcErmes = OrcErmes(
    signalingServer: signalingServer,
    signalingHandler: signalingHandler as IErmesSignalingHandler<ShspPeer>,
    socket: socket,
    bookService: bookService,
    enableEncryption: enableEncryption,
  );

  RegistryAccess.register<_Wrap<IOrcErmes<BookData>>>(key, _Wrap(orcErmes));
}

/// Retrieve IOrcErmes from registry by key.
IOrcErmes<BookData> getIOrcErmesFromRegistry({String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IOrcErmes<BookData>>>(key).value;
