import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// Initializes the Ermes signaling stack for the Ermes DI system.
///
/// If [keyPair] is provided, calls [initialPointNostrSignaling] from
/// nostr_signaling to register [INostrSignaling] in the DI container.
///
/// If [initializeStunShsp] is true, calls [initializePointStunShsp] from
/// stun_shsp to bind SHSP sockets and initialize STUN (which in turn uses
/// [initializePointDualShsp] from shsp and [initialPointStunWithSockets] from
/// stun).
///
/// If [accountId] is provided, registers it in the DI container.
///
/// When parameters are omitted, the caller must ensure the corresponding
/// dependencies are already registered before calling this function.
Future<void> initialPointErmesSignaling({
  NostrKeyPair? keyPair,
  List<String>? relayUrls,
  bool useCompression = false,
  IdAccountType? accountId,
  bool initializeStunShsp = false,
}) async {
  if (initializeStunShsp) {
    await initializePointStunShsp();
  }
  if (keyPair != null) {
    await initialPointNostrSignaling(
      keyPair: keyPair,
      relayUrls: relayUrls ?? ['wss://relay.damus.io'],
      useCompression: useCompression,
    );
  }
  if (accountId != null) {
    SingletonDIAccess.addInstance<IdAccountType>(accountId);
  }
  _initializeDI();
}

/// Partial variant — assumes [INostrSignaling] and [IdAccountType]
/// are already registered. Useful when Nostr signaling is set up
/// separately (e.g., via [ErmesSignalingServer.fromKeys]).
void initialPointErmesSignalingPartial() {
  _initializeDI();
}

void _initializeDI() {
  // 1. Signaling server (needs: INostrSignaling, IdAccountType)
  final server = ErmesSignalingServerDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IErmesSignalingServer, ErmesSignalingServerDI>(server);

  // 2. Book repository (no deps)
  final bookRepo = ErmesBookRepositoryDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IErmesBookRepository<BookData>, ErmesBookRepositoryDI>(bookRepo);

  // 3. Book service (needs: IErmesBookRepository<BookData>)
  final bookService = ErmesBookServiceBaseDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IErmesBookService<BookData>, ErmesBookServiceBaseDI>(bookService);

  // 4. Signaling handler
  // (needs: IStunShspHandler, IShspSocket, IErmesBookService<BookData>)
  final handler = ErmesSignalingHandlerDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IErmesSignalingHandler<IShspPeer>, ErmesSignalingHandlerDI>(handler);

  // 5. Signaling repository
  // (needs: IErmesSignalingServer, IErmesSignalingHandler<IShspPeer>)
  final repo = ErmesSignalingRepositoryDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IErmesSignalingRepository<ISignalErmes>,
      ErmesSignalingRepositoryDI>(repo);

  // 6. Signaling service (needs: IErmesSignalingRepository<ISignalErmes>)
  final service = ErmesSignalingServiceDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IErmesSignalingService, ErmesSignalingServiceDI>(service);
}
