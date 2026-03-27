import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../ermes_signaling.dart';
import 'generated/ermes_book_repository_di.dart';
import 'generated/ermes_book_service_di.dart';
import 'generated/ermes_signaling_handler_di.dart';
import 'generated/ermes_signaling_repository_di.dart';
import 'generated/ermes_signaling_server_di.dart';
import 'generated/ermes_signaling_service_di.dart';

Future<SignalingContract> createSignalingContract({
  required String rpcUrl,
  required String contractAddress,
  required String privateKeyHex,
}) {
  final client = Web3Client(rpcUrl, http.Client());
  final address = EthereumAddress.fromHex(contractAddress);
  final credentials = EthPrivateKey.fromHex(privateKeyHex);
  return SignalingContract.connectWithClient(
    client: client,
    contractAddress: address,
    credentials: credentials,
  );
}

void initialPointErmesSignaling({
  required SignalingContract contract,
  required IStunShspHandler stunShspHandler,
  required IShspSocket socket,
}) {
  // Register external dependencies
  SingletonDIAccess.addInstance<SignalingContract>(contract);
  SingletonDIAccess.addInstance<IStunShspHandler>(stunShspHandler);
  SingletonDIAccess.addInstance<IShspSocket>(socket);
  _initializeDI();
}

void initialPointErmesSignalingPartial({
  required SignalingContract contract,
  IStunShspHandler? stunShspHandler,
  IShspSocket? socket,
}) {
  // Register external dependencies
  SingletonDIAccess.addInstance<SignalingContract>(contract);
  if (stunShspHandler != null) {
    SingletonDIAccess.addInstance<IStunShspHandler>(stunShspHandler);
  }
  if (socket != null) {
    SingletonDIAccess.addInstance<IShspSocket>(socket);
  }
  _initializeDI();
}

void _initializeDI() {
  // 1. Signaling server (needs: SignalingContract, IdAccountType)
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
