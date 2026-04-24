import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/src/initial_point/initial_point_ermes_cipher_registry.dart';
import 'package:ermes_signaling/src/initial_point/initial_point_ermes_signaling_registry.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../orc_ermes.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  _Wrap(this.value);

  final T value;
}

/// Registry-based variant of initialPointErmesCore.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
///
/// Prerequisites — register in RegistryAccess before calling:
///   - _Wrap<SignalingContract> (via key)
///   - _Wrap<IdAccountType>
///   - _Wrap<IStunShspHandler>
///   - _Wrap<IShspSocket>
///   - (optional) call initialPointErmesCipherRegistry(key:) for encryption
Future<void> initialPointErmesCoreRegistry({String key = 'default'}) async {
  // 1. Signaling
  initialPointErmesSignalingRegistry(key: key);

  // 2. Cipher — only if not already initialised by the caller
  if (!RegistryAccess.contains<_Wrap<IKeyExchange>>(key)) {
    await initialPointErmesCipherRegistry(key: key);
  }

  // 3. Build OrcErmes directly from registry components
  final signalingServer = getIErmesSignalingServerFromRegistry(key: key);
  final signalingHandler = getIErmesSignalingHandlerFromRegistry(key: key);
  final bookService = getIErmesBookServiceFromRegistry(key: key);
  final socket = RegistryAccess.getInstance<_Wrap<IShspSocket>>(key).value;
  final enableEncryption = RegistryAccess.contains<_Wrap<IKeyExchange>>(key);

  final orcErmes = OrcErmes(
    signalingServer: signalingServer,
    signalingHandler: signalingHandler as IErmesSignalingHandler<ShspPeer>,
    socket: socket,
    bookService: bookService,
    enableEncryption: enableEncryption,
  );

  RegistryAccess.register<_Wrap<IOrcErmes>>(key, _Wrap(orcErmes));
}

/// Retrieve IOrcErmes from registry by key.
IOrcErmes getIOrcErmesFromRegistry({String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IOrcErmes>>(key).value;
