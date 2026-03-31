import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_book_repository.dart';
import '../generated/ermes_book_repository_di.dart';
import '../generated/ermes_book_service_di.dart';
import '../generated/ermes_signaling_handler_di.dart';
import '../generated/ermes_signaling_repository_di.dart';
import '../generated/ermes_signaling_server_di.dart';
import '../generated/ermes_signaling_service_di.dart';

/// Wrapper to satisfy IValueForRegistry constraint for RegistryAccess.
class _Wrap<T> with ValueForRegistry {
  final T value;
  _Wrap(this.value);
}

/// Registry-based variant of initialPointErmesSignaling.
/// Allows multiple named instances (e.g., 'prod', 'test') to coexist.
void initialPointErmesSignalingRegistry({
  required SignalingContract contract,
  required IStunShspHandler stunShspHandler,
  required IShspSocket socket,
  String key = 'default',
}) {
  // Register external dependencies
  RegistryAccess.register<_Wrap<SignalingContract>>(
    key,
    _Wrap(contract),
  );
  RegistryAccess.register<_Wrap<IStunShspHandler>>(
    key,
    _Wrap(stunShspHandler),
  );
  RegistryAccess.register<_Wrap<IShspSocket>>(
    key,
    _Wrap(socket),
  );
  _initializeDIRegistry(key);
}

/// Registry-based variant of initialPointErmesSignalingPartial.
/// Allows multiple named instances with optional stun/socket.
void initialPointErmesSignalingPartialRegistry({
  required SignalingContract contract,
  IStunShspHandler? stunShspHandler,
  IShspSocket? socket,
  String key = 'default',
}) {
  // Register external dependencies
  RegistryAccess.register<_Wrap<SignalingContract>>(
    key,
    _Wrap(contract),
  );
  if (stunShspHandler != null) {
    RegistryAccess.register<_Wrap<IStunShspHandler>>(
      key,
      _Wrap(stunShspHandler),
    );
  }
  if (socket != null) {
    RegistryAccess.register<_Wrap<IShspSocket>>(
      key,
      _Wrap(socket),
    );
  }
  _initializeDIRegistry(key);
}

void _initializeDIRegistry(String key) {
  // 1. Signaling server (needs: SignalingContract, IdAccountType)
  final server = ErmesSignalingServerDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingServer>>(
    key,
    _Wrap(server),
  );

  // 2. Book repository (no deps)
  final bookRepo = ErmesBookRepositoryDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesBookRepository<BookData>>>(
    key,
    _Wrap(bookRepo),
  );

  // 3. Book service (needs: IErmesBookRepository<BookData>)
  final bookService = ErmesBookServiceBaseDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesBookService<BookData>>>(
    key,
    _Wrap(bookService),
  );

  // 4. Signaling handler
  // (needs: IStunShspHandler, IShspSocket, IErmesBookService<BookData>)
  final handler = ErmesSignalingHandlerDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingHandler<IShspPeer>>>(
    key,
    _Wrap(handler),
  );

  // 5. Signaling repository
  // (needs: IErmesSignalingServer, IErmesSignalingHandler<IShspPeer>)
  final repo = ErmesSignalingRepositoryDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingRepository<ISignalErmes>>>(
    key,
    _Wrap(repo),
  );

  // 6. Signaling service (needs: IErmesSignalingRepository<ISignalErmes>)
  final service = ErmesSignalingServiceDI.initializeDI();
  RegistryAccess.register<_Wrap<IErmesSignalingService>>(
    key,
    _Wrap(service),
  );
}

/// Retrieve IErmesSignalingServer from registry by key.
IErmesSignalingServer getIErmesSignalingServerFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesSignalingServer>>(key).value;

/// Retrieve IErmesBookRepository<BookData> from registry by key.
IErmesBookRepository<BookData> getIErmesBookRepositoryFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess
        .getInstance<_Wrap<IErmesBookRepository<BookData>>>(key)
        .value;

/// Retrieve IErmesBookService<BookData> from registry by key.
IErmesBookService<BookData> getIErmesBookServiceFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesBookService<BookData>>>(key).value;

/// Retrieve IErmesSignalingHandler<IShspPeer> from registry by key.
IErmesSignalingHandler<IShspPeer> getIErmesSignalingHandlerFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess
        .getInstance<_Wrap<IErmesSignalingHandler<IShspPeer>>>(key)
        .value;

/// Retrieve IErmesSignalingRepository<ISignalErmes> from registry by key.
IErmesSignalingRepository<ISignalErmes>
    getIErmesSignalingRepositoryFromRegistry({String key = 'default'}) =>
        RegistryAccess
            .getInstance<_Wrap<IErmesSignalingRepository<ISignalErmes>>>(
              key,
            )
            .value;

/// Retrieve IErmesSignalingService from registry by key.
IErmesSignalingService getIErmesSignalingServiceFromRegistry(
        {String key = 'default'}) =>
    RegistryAccess.getInstance<_Wrap<IErmesSignalingService>>(key).value;
