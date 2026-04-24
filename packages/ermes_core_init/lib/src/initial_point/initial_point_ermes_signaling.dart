import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:http/http.dart' as http;
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

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

void initialPointErmesSignaling() {
  _initializeDI();
}

void initialPointErmesSignalingPartial() {
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
