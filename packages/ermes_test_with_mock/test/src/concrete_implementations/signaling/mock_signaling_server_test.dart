import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

// ---------------------------------------------------------------------------
// Simulated signaling server (in-memory, no network, no mock framework)
// ---------------------------------------------------------------------------

/// In-memory [IErmesSignalingServer] that stands in for the relay.
///
/// It stores published/inbound signals, fires the registered callbacks and
/// lets a test drive the two events that matter for connection lifecycle:
/// a fresh signal arriving ([pushSignal]) and the link dropping
/// ([simulateDisconnect]).
class _MockSignalingServer implements IErmesSignalingServer {
  _MockSignalingServer({String accountId = 'local-account'})
      : _accountId = accountId;

  final String _accountId;

  // Latest inbound signal per remote peer id (what getSignal returns).
  final Map<IdAccountType, ISignalErmes> _inbound = {};

  // Every outbound publish, for assertions.
  final List<({ISignalErmes signal, IdAccountType? to})> published = [];

  final List<({void Function(ISignalErmes) cb, IdAccountType? from})>
      _onSignal = [];
  final List<void Function(Object)> _onError = [];
  final List<void Function()> _onClose = [];

  bool _connected = true;

  @override
  Future<IdAccountType> getIdAccount() async => _accountId;

  @override
  Future<bool> isConnected() async => _connected;

  @override
  Future<ISignalErmes> getSignal(
    IdAccountType from, {
    bool forceRefresh = false,
  }) async {
    final signal = _inbound[from];
    if (signal == null) {
      throw SignalingException('No signal staged for peer $from');
    }
    return signal;
  }

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {
    published.add((signal: signal, to: to));
  }

  @override
  void onSignal(
    void Function(ISignalErmes data) callback, [
    IdAccountType? from,
  ]) {
    _onSignal.add((cb: callback, from: from));
  }

  @override
  void onError(void Function(Object err) callback) => _onError.add(callback);

  @override
  void onClose(void Function() callback) => _onClose.add(callback);

  @override
  Future<void> removeAllListeners() async {
    _onSignal.clear();
    _onError.clear();
    _onClose.clear();
  }

  @override
  Future<void> destroy() async {
    _connected = false;
    await removeAllListeners();
    _inbound.clear();
  }

  // --- test hooks -----------------------------------------------------------

  /// Simulates a peer [from] publishing [signal]: it becomes retrievable via
  /// [getSignal] and every matching onSignal listener is notified.
  void pushSignal(ISignalErmes signal, {required IdAccountType from}) {
    _inbound[from] = signal;
    for (final entry in _onSignal) {
      if (entry.from == null || entry.from == from) {
        entry.cb(signal);
      }
    }
  }

  /// Simulates the signaling link dropping.
  void simulateDisconnect() {
    _connected = false;
    for (final cb in _onClose) {
      cb();
    }
  }

  /// Simulates a relay error surfacing.
  void simulateError(Object err) {
    for (final cb in _onError) {
      cb(err);
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SignalErmes _signalWith({
  String publicKey = '',
  int start = 100,
}) =>
    SignalErmes(
      publicKey: publicKey,
      ipv4: '127.0.0.1',
      ipv4Port: '9000',
      ipv6: '',
      ipv6Port: '',
      epochTimestampStartConversation: start,
      epochTimestampExpireConversation:
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );

/// Injects a service message into [repo] the same way a decoded inbound frame
/// would reach the read repo, so the owning [ErmesService] handles it.
Future<void> _injectService(
  TestErmesRepository repo,
  ServiceMessage message,
) async {
  final internal = InternalMessage(
    message: MessageType.service(message),
    type: MessageValue.service,
  );
  final serialized = objectToUint8Array(internal);
  final root = MessageRoot(
    messageSerialized: serialized,
    integrityCheckValue: calculateHashSync(serialized),
  );
  repo.simulateDataReceived(objectToUint8Array(root));
  await Future<void>.delayed(Duration.zero);
}

/// Ciphertext a remote peer holding [keyHex] would put on the wire.
DataEncrypted _encryptWith(String keyHex, Uint8List payload) {
  final remote = ErmesPeerCipher()
    ..addEncryptCipher(generateSymmetric(keyHex, SymmetricAlgorithm.aes));
  return remote.encrypt(payload);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() => testMockSignalingServer();

void testMockSignalingServer() {
  group('Simulated signaling server', () {
    late _MockSignalingServer server;

    setUp(() => server = _MockSignalingServer());

    group('signal publish / retrieve', () {
      test('setSignal records the outbound publish', () async {
        final signal = _signalWith();
        await server.setSignal(signal, 'peer-b');

        expect(server.published, hasLength(1));
        expect(server.published.first.to, equals('peer-b'));
        expect(server.published.first.signal, same(signal));
      });

      test('getSignal returns a staged inbound signal unchanged', () async {
        server.pushSignal(_signalWith(publicKey: 'PUBKEY-XYZ'), from: 'peer-a');

        final fetched = await server.getSignal('peer-a');
        expect(fetched.publicKey, equals('PUBKEY-XYZ'));
        expect(fetched.epochTimestampStartConversation, equals(100));
      });

      test('getSignal throws for an unknown peer', () {
        expect(
          () => server.getSignal('nobody'),
          throwsA(isA<SignalingException>()),
        );
      });

      test('a newer signal supersedes the previous one', () async {
        server
          ..pushSignal(_signalWith(), from: 'peer-a')
          ..pushSignal(_signalWith(start: 200), from: 'peer-a');

        final fetched = await server.getSignal('peer-a');
        expect(fetched.epochTimestampStartConversation, equals(200));
      });
    });

    group('onSignal (a new signal arrives)', () {
      test('fires the callback with the pushed signal', () {
        ISignalErmes? received;
        server
          ..onSignal((s) => received = s)
          ..pushSignal(_signalWith(publicKey: 'K1'), from: 'peer-a');

        expect(received, isNotNull);
        expect(received!.publicKey, equals('K1'));
      });

      test('honours the per-peer filter', () {
        final fromA = <ISignalErmes>[];
        server
          ..onSignal(fromA.add, 'peer-a')
          ..pushSignal(_signalWith(), from: 'peer-b')
          ..pushSignal(_signalWith(), from: 'peer-a');

        expect(fromA, hasLength(1));
      });

      test('delivers a signal carrying an ECDH public key intact', () async {
        final kx = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        ISignalErmes? received;
        server
          ..onSignal((s) => received = s)
          ..pushSignal(_signalWith(publicKey: kx.publicKey), from: 'peer-a');

        expect(received!.publicKey, equals(kx.publicKey));
      });
    });

    group('disconnection', () {
      test('isConnected flips and onClose fires once on disconnect', () async {
        var closes = 0;
        server.onClose(() => closes++);

        expect(await server.isConnected(), isTrue);
        server.simulateDisconnect();

        expect(await server.isConnected(), isFalse);
        expect(closes, equals(1));
      });

      test('destroy leaves the server disconnected', () async {
        await server.destroy();
        expect(await server.isConnected(), isFalse);
      });

      test('onError forwards the error object', () {
        Object? seen;
        final error = StateError('relay down');
        server
          ..onError((e) => seen = e)
          ..simulateError(error);

        expect(seen, same(error));
      });

      test('removeAllListeners silences later events', () async {
        var signalHits = 0;
        var closeHits = 0;
        server
          ..onSignal((_) => signalHits++)
          ..onClose(() => closeHits++);

        await server.removeAllListeners();
        server
          ..pushSignal(_signalWith(), from: 'peer-a')
          ..simulateDisconnect();

        expect(signalHits, equals(0));
        expect(closeHits, equals(0));
      });
    });
  });

  group('Key exchange over a simulated link', () {
    late ErmesService service;
    late TestErmesRepository repo;
    late String peerId;
    var counter = 0;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      peerId = 'remote-peer-${counter++}';
      repo = await TestErmesRepository.create(peerId: peerId);
      service = ErmesServiceFactory.createService(
        100,
        1024,
        repo,
        IdHandlerServiceFactory.createDefault(),
        null,
        null,
        null,
        null,
        null,
      );
    });

    tearDown(() {
      service.close();
      ErmesPeerCipherHandler().remove(peerId);
      repo.cleanUp();
    });

    ServiceMessageNewKey newKey(int id, String keyHex) => ServiceMessageNewKey(
          id: id,
          algorithm: SymmetricAlgorithm.aes,
          key: keyHex,
        );

    group('new keys', () {
      test('a received newKey registers a working decrypt cipher', () async {
        final keyHex = 'a' * 64;
        await _injectService(repo, newKey(1, keyHex));

        final peerCipher = ErmesPeerCipherHandler().get(peerId);
        expect(peerCipher, isNotNull);

        final payload = Uint8List.fromList([10, 20, 30]);
        final decrypted = peerCipher!.decrypt(_encryptWith(keyHex, payload));
        expect(decrypted, equals(payload));
      });

      test('the newKey listener is notified with the key', () async {
        ServiceMessageNewKey? seen;
        service.addOnNewKeyListener((k) => seen = k);

        await _injectService(repo, newKey(7, 'b' * 64));

        expect(seen, isNotNull);
        expect(seen!.id, equals(7));
        expect(seen!.key, equals('b' * 64));
      });
    });

    group('key change (rotation overlap)', () {
      test('both the old and the rotated key keep decrypting', () async {
        final oldKey = 'a' * 64;
        final newKeyHex = 'c' * 64;
        await _injectService(repo, newKey(1, oldKey));
        await _injectService(repo, newKey(2, newKeyHex));

        final peerCipher = ErmesPeerCipherHandler().get(peerId)!;
        final oldMsg = Uint8List.fromList([1, 1, 1]);
        final newMsg = Uint8List.fromList([2, 2, 2]);

        expect(
          peerCipher.decrypt(_encryptWith(oldKey, oldMsg)),
          equals(oldMsg),
        );
        expect(
          peerCipher.decrypt(_encryptWith(newKeyHex, newMsg)),
          equals(newMsg),
        );
      });

      test('several sequential key changes all register', () async {
        final keys = ['a', 'b', 'c', 'd', 'e'].map((c) => c * 64).toList();
        for (var i = 0; i < keys.length; i++) {
          await _injectService(repo, newKey(i + 1, keys[i]));
        }

        final peerCipher = ErmesPeerCipherHandler().get(peerId)!;
        for (final key in keys) {
          final payload = Uint8List.fromList([9, 9]);
          expect(
            peerCipher.decrypt(_encryptWith(key, payload)),
            equals(payload),
          );
        }
      });
    });

    group('shared secret from a new signal', () {
      test('deriving from the signal public key yields a usable cipher',
          () async {
        // Mirrors OrcConnectionOpener._applySharedSecret: a fresh signal
        // carries the peer's ECDH public key, from which both sides derive the
        // same shared cipher without any key travelling on the wire.
        final local = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;
        final remote = await ECDHKeyExchangeService.generateNew()
            as ECDHKeyExchangeService;

        final signalServer = _MockSignalingServer()
          ..pushSignal(_signalWith(publicKey: remote.publicKey), from: peerId);
        final signal = await signalServer.getSignal(peerId);

        final localShared = deriveSharedSecretCipher(local, signal.publicKey);
        final peerCipher = ErmesPeerCipher()
          ..addEncryptCipher(localShared)
          ..addDecryptCipher(localShared);
        ErmesPeerCipherHandler().set(peerId, peerCipher);

        final remoteShared = ErmesPeerCipher()
          ..addEncryptCipher(
            deriveSharedSecretCipher(remote, local.publicKey),
          );
        final payload = Uint8List.fromList([7, 7, 7]);
        expect(
          peerCipher.decrypt(remoteShared.encrypt(payload)),
          equals(payload),
        );
      });
    });

    group('disconnection', () {
      test('a ConnectionClose message closes the service and notifies',
          () async {
        var closed = false;
        service.addOnRemoteCloseListener(() => closed = true);

        await _injectService(
          repo,
          const ServiceMessageConnectionClose(id: 1),
        );

        expect(closed, isTrue);
        expect(service.isConnectionClosed, isTrue);
      });
    });
  });
}
