import 'package:ermes_cipher/src/initial_point/initial_point_ermes_cipher_registry.dart';
import 'package:ermes_signaling/src/initial_point/initial_point_ermes_signaling_registry.dart';
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../orc_ermes.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  final T value;

  _Wrap(this.value);
}

/// Registry-based variant of initialPointErmesCore.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
Future<void> initialPointErmesCoreRegistry({
  required SignalingContract contract,
  required IdAccountType accountId,
  required IStunShspHandler stunShspHandler,
  required IShspSocket socket,
  bool enableEncryption = true,
  String key = 'default',
}) async {
  RegistryAccess.register<_Wrap<IdAccountType>>(key, _Wrap(accountId));

  // 1. Signaling
  initialPointErmesSignalingRegistry(
    contract: contract,
    stunShspHandler: stunShspHandler,
    socket: socket,
    key: key,
  );

  // 2. Cipher
  if (enableEncryption) {
    await initialPointErmesCipherRegistry(key: key);
  }

  // 3. Build OrcErmes directly from registry components
  final signalingServer = getIErmesSignalingServerFromRegistry(key: key);
  final signalingHandler = getIErmesSignalingHandlerFromRegistry(key: key);
  final bookService = getIErmesBookServiceFromRegistry(key: key);

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
