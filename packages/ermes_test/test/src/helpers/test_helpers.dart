import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

const testPeerId = 'test-peer-id';

/// Builds a real STUN/SHSP handler over [socket].
///
/// stun_shsp 0.4.0 deleted `StunShspHandlerSingleton`, so tests that used to
/// grab the process-wide instance build their own handler over the socket they
/// already own. Sharing the socket keeps the STUN half and the SHSP half in
/// sync, which is what the singleton used to guarantee.
StunShspHandler testStunShspHandler(IShspSocket socket) =>
    StunShspHandler(ShspSocketMigratable(socket));

/// Builds a real STUN/SHSP handler over a freshly bound loopback socket.
///
/// The caller owns the returned handler and must `close()` it.
Future<StunShspHandler> createTestStunShspHandler({bool ipv6 = false}) =>
    StunShspHandler.createDefault(ipv6: ipv6);


ErmesPeerInfo testPeerInfo() => ErmesPeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: 9999,
      id: testPeerId,
    );

ErmesPeerInfo testPeerInfoFor(IdAccountType id, {int port = 9999}) =>
    ErmesPeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: port,
      id: id,
    );

/// Builds a real signaling handler over [socket].
///
/// The repositories under test never drive a handshake through it, but the
/// handler is a required collaborator, so it gets a genuine one wired to the
/// same socket rather than a stand-in.
ErmesSignalingHandler _defaultSignalHandler(IShspSocket socket) =>
    ErmesSignalingHandler(
      testStunShspHandler(socket),
      socket,
      ErmesBookServiceBase(ErmesBookRepository()),
    );

Future<({ErmesRepository repository, RawDatagramSocket rawSocket})>
    createTestRepository({
  IdAccountType? peerId,
  IErmesBookService<Object>? bookService,
  IErmesSignalingHandler<ShspPeer>? signalHandler,
  bool open = false,
}) async {
  final rawSocket =
      await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final shspSocket = ShspSocket.fromRaw(rawSocket);
  final bs = bookService ?? _createDefaultBookService(peerId);
  final handler = signalHandler ?? _defaultSignalHandler(shspSocket);
  final repository = ErmesRepository(
    remotePeerId: peerId ?? testPeerId,
    socket: shspSocket,
    signalHandler: handler,
    ermesBookService: bs,
  );
  if (open) {
    repository.openState = true;
  }
  return (repository: repository, rawSocket: rawSocket);
}

class TestRepositoryResult {
  TestRepositoryResult({
    required this.repository,
    required this.rawSocket,
  });

  final ErmesRepository repository;
  final RawDatagramSocket rawSocket;

  void cleanUp() {
    repository.destroy();
    repository.socket.close();
  }
}

IErmesBookService<Object> _createDefaultBookService(
    IdAccountType? peerId) {
  final bs = ErmesBookServiceBase(ErmesBookRepository())
    ..setAccount(AccountInfo<BookData>(
      account: peerId ?? testPeerId,
      peerInfo: testPeerInfo(),
    ));
  return bs;
}

class TestErmesRepository extends ErmesRepository {
  TestErmesRepository._({
    required super.remotePeerId,
    required super.socket,
    required super.signalHandler,
    required super.ermesBookService,
    required this.rawSocket,
    bool open = false,
  }) {
    if (open) {
      openState = true;
    }
  }

  /// Creates a TestErmesRepository with a real UDP socket on loopback.
  /// Returns the repository and the raw socket for cleanup.
  static Future<TestErmesRepository> create({
    IdAccountType? peerId,
    IErmesBookService<Object>? bookService,
    IErmesSignalingHandler<ShspPeer>? signalHandler,
    bool open = false,
  }) async {
    final rawSocket =
        await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final shspSocket = ShspSocket.fromRaw(rawSocket);
    final bs = bookService ?? _createDefaultBookService(peerId);
    final handler = signalHandler ?? _defaultSignalHandler(shspSocket);
    return TestErmesRepository._(
      remotePeerId: peerId ?? testPeerId,
      socket: shspSocket,
      signalHandler: handler,
      ermesBookService: bs,
      rawSocket: rawSocket,
      open: open,
    );
  }

  final RawDatagramSocket rawSocket;
  final List<Uint8List> sentData = [];

  @override
  void send(SerializableDataType data) {
    sentData.add(Uint8List.fromList(data));
  }

  static final PeerInfo _fakePeerInfo = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 1,
  );

  void simulateDataReceived(Uint8List data) {
    onMessage([0x00, ...data], _fakePeerInfo);
  }

  void cleanUp() {
    destroy();
    socket.close();
  }
}

/// Helper to set up missing message IDs on a real IErmesMessageControlService.
///
/// Uses the public [IErmesMessageControlService.idArrived] API to simulate
/// sequence gaps, which causes the service to internally track the given IDs
/// as missing. Does NOT support ID 0 (the real implementation tracks gaps
/// starting from 1).
void setupMissingIds(IErmesMessageControlService service, int count) {
  if (count <= 0) {
    return;
  }
  service.idArrived(count + 1);
}
