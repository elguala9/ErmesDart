import 'dart:async';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart' show ISymmetricCipher;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/in_memory_signaling.dart';
import '../service/version/version_pair.dart';

const _v4 = ErmesConnectionContext.ipv4;

void main() {
  setUpAll(registerErmesStorageHandlers);
  testErmesPubKeyRotation();
}

/// RFC 8.6: `newpubkey` service message, periodic ECDH key-pair rotation
/// and re-derivation of the directional session keys on receipt.
void testErmesPubKeyRotation() {
  _testNewPubKeyMessage();
  _testRotator();
  _testApplierRederivation();
  _testEndToEnd();
  _testOrcErmesRotation();
}

SignalErmes _signal(String idSignaling, String publicKey, int start) =>
    SignalErmes(
      idSignaling: idSignaling,
      publicKey: publicKey,
      ipv6: '',
      ipv6Port: '',
      ipv4: '127.0.0.1',
      ipv4Port: '4000',
      epochTimestampStartConversation: start,
      epochTimestampExpireConversation: start + 3600,
    );

void _testNewPubKeyMessage() {
  group('ServiceMessageNewPubKey (RFC 7.2)', () {
    test('JSON round-trip keeps reason and key', () {
      const msg = ServiceMessageNewPubKey(id: 7, key: 'abcd');
      final json = msg.toJson();
      expect(json['reason'], 'newpubkey');
      expect(json['key'], 'abcd');
      final back = ServiceMessage.fromJson(json);
      expect(back, isA<ServiceMessageNewPubKey>());
      expect(back, equals(msg));
    });

    test('round-trips inside a MessageType envelope', () {
      const msg = ServiceMessageNewPubKey(id: 3, key: 'ff00');
      const type = MessageType.service(msg);
      final back = MessageType.fromJson(type.toJson());
      expect(back.asService(), equals(msg));
    });

    test('missing key throws', () {
      expect(
        () => ServiceMessage.fromJson({'id': 1, 'reason': 'newpubkey'}),
        throwsArgumentError,
      );
    });

    test('empty key throws', () {
      expect(
        () => ServiceMessage.fromJson(
            {'id': 1, 'reason': 'newpubkey', 'key': ''}),
        throwsArgumentError,
      );
    });
  });
}

/// Records the effects of a rotator's collaborators.
class _RotatorProbe {
  int renewed = 0;
  int rederived = 0;
  int republished = 0;
  bool failRenew = false;
  final List<IErmesService> services = [];

  ErmesPubKeyRotatorInput input({Duration? interval}) =>
      ErmesPubKeyRotatorInput(
        renewKeyPair: () async {
          if (failRenew) {
            throw StateError('renew failed');
          }
          renewed++;
          return 'pub-$renewed';
        },
        services: () => services,
        rederive: () => rederived++,
        republish: () async => republished++,
        interval: interval,
      );
}

void _testRotator() {
  group('ErmesPubKeyRotator (RFC 8.6)', () {
    test('factory defaults the interval to the protocol T', () {
      final r = ErmesPubKeyRotatorFactory.create(_RotatorProbe().input());
      expect(r.interval,
          ErmesProtocolParameters.current.publicKeyRotationInterval);
      expect(r.interval, const Duration(days: 1));
      expect(r.isRunning, isFalse);
    });

    test('rotate renews, re-derives and republishes once', () async {
      final probe = _RotatorProbe();
      await ErmesPubKeyRotatorFactory.create(probe.input()).rotate();
      expect(
          [probe.renewed, probe.rederived, probe.republished], [1, 1, 1]);
    });

    test('timer rotates periodically through the test seam', () async {
      final probe = _RotatorProbe();
      final r = ErmesPubKeyRotatorFactory.create(
          probe.input(interval: const Duration(milliseconds: 30)))
        ..start()
        ..start();
      expect(r.isRunning, isTrue);
      await waitFor(() => probe.republished >= 2);
      r.dispose();
      expect(r.isRunning, isFalse);
      expect(probe.republished, greaterThanOrEqualTo(2));
    });

    test('overlapping rotations run once', () async {
      final probe = _RotatorProbe();
      final r = ErmesPubKeyRotatorFactory.create(probe.input());
      await Future.wait<void>([r.rotate(), r.rotate()]);
      expect(probe.renewed, 1);
    });

    test('does nothing after dispose', () async {
      final probe = _RotatorProbe();
      final r = ErmesPubKeyRotatorFactory.create(probe.input())..dispose();
      await r.rotate();
      r.start();
      expect(r.isRunning, isFalse);
      expect(probe.renewed, 0);
    });

    test('a failed key generation aborts before re-deriving', () async {
      final probe = _RotatorProbe()..failRenew = true;
      final r = ErmesPubKeyRotatorFactory.create(probe.input());
      await expectLater(r.rotate(), throwsStateError);
      expect([probe.rederived, probe.republished], [0, 0]);
      probe.failRenew = false;
      await r.rotate();
      expect(probe.rederived, 1, reason: 'not stuck after a failure');
    });

    test('a closed Connection does not stop the rotation', () async {
      final pair = await VersionPair.create();
      pair.a.close();
      final probe = _RotatorProbe()..services.add(pair.a);
      await ErmesPubKeyRotatorFactory.create(probe.input()).rotate();
      expect([probe.rederived, probe.republished], [1, 1]);
      pair.dispose();
    });
  });
}

String _uid(String tag) => '$tag-${DateTime.now().microsecondsSinceEpoch}';

ErmesPeerCipher _cipherOf(String peer) =>
    ErmesPeerCipherHandler().get(peerCipherKey(peer, _v4))!;

DataEncrypted _frame(ISymmetricCipher c, List<int> data) => DataEncrypted(
    c.keyId, Uint8List.fromList(c.encrypt(Uint8List.fromList(data))));

void _testApplierRederivation() {
  group('OrcSignalCipherApplier re-derivation (RFC 8.6)', () {
    test('local rotation: new keys match the remote view, old decrypt kept',
        () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final remote = await ECDHKeyExchangeService.generateNewService();
      final peer = _uid('rot-local');
      final applier = OrcSignalCipherApplier(local)
        ..apply(peer, remote.publicKey, _v4);
      final oldRemote =
          deriveDirectionalCiphers(remote, local.publicKey, _v4).encrypt;
      await local.generateKeyPair();
      applier.reapplyAll();
      final fresh = deriveDirectionalCiphers(remote, local.publicKey, _v4);
      final cipher = _cipherOf(peer);
      expect(cipher.currentEncryptKeyId, fresh.decrypt.keyId);
      expect(cipher.decrypt(_frame(fresh.encrypt, [1])), [1]);
      expect(cipher.decrypt(_frame(oldRemote, [2])), [2],
          reason: 'grace period for frames in flight under the old key');
    });

    test('signal with same IdSignaling and new key re-derives', () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final remote = await ECDHKeyExchangeService.generateNewService();
      final peer = _uid('rot-signal');
      final applier = OrcSignalCipherApplier(local)
        ..apply(peer, remote.publicKey, _v4, idSignaling: 'id-r');
      await remote.generateKeyPair();
      expect(applier.applyIfRotated(peer, _signal('id-r', remote.publicKey, 1)),
          isTrue);
      final fresh = deriveDirectionalCiphers(remote, local.publicKey, _v4);
      expect(_cipherOf(peer).decrypt(_frame(fresh.encrypt, [5])), [5]);
    });

    test('signal of another IdSignaling or same key is ignored', () async {
      final local = await ECDHKeyExchangeService.generateNewService();
      final remote = await ECDHKeyExchangeService.generateNewService();
      final other = await ECDHKeyExchangeService.generateNewService();
      final peer = _uid('rot-ignore');
      final applier = OrcSignalCipherApplier(local)
        ..apply(peer, remote.publicKey, _v4, idSignaling: 'id-r');
      final before = _cipherOf(peer).currentEncryptKeyId;
      expect(applier.applyIfRotated(peer, _signal('id-x', other.publicKey, 1)),
          isFalse);
      expect(
          applier.applyIfRotated(peer, _signal('id-r', remote.publicKey, 1)),
          isFalse);
      expect(applier.applyIfRotated(_uid('nobody'),
          _signal('id-r', other.publicKey, 1)), isFalse);
      expect(_cipherOf(peer).currentEncryptKeyId, before);
    });
  });
}

void _testEndToEnd() {
  group('newpubkey end-to-end over two ErmesServices', () {
    test('traffic continues both ways across a rotation', () async {
      final pair = await VersionPair.create();
      final keA = await ECDHKeyExchangeService.generateNewService();
      final keB = await ECDHKeyExchangeService.generateNewService();
      final idB = pair.repoA.remotePeerId;
      final idA = pair.repoB.remotePeerId;
      expect(pair.repoA.cipherKey, peerCipherKey(idB, _v4));
      final applierA = OrcSignalCipherApplier(keA)
        ..apply(idB, keB.publicKey, _v4)
        ..listen(idB, pair.a, _v4);
      final applierB = OrcSignalCipherApplier(keB)
        ..apply(idA, keA.publicKey, _v4)
        ..listen(idA, pair.b, _v4);
      final announced = <ServiceMessageNewPubKey>[];
      pair.b.addOnNewPubKeyListener(announced.add);
      await pair.negA.ready;
      await pair.negB.ready;
      final oldEncrypt = _cipherOf(idA).currentEncryptKeyId;

      await ErmesPubKeyRotatorFactory.create(ErmesPubKeyRotatorInput(
        renewKeyPair: () async {
          await keA.generateKeyPair();
          return keA.publicKey;
        },
        services: () => [pair.a],
        rederive: applierA.reapplyAll,
        republish: () async {},
      )).rotate();
      await waitFor(() => announced.isNotEmpty);
      expect(announced.single.key, keA.publicKey);
      expect(_cipherOf(idA).currentEncryptKeyId, isNot(oldEncrypt));

      await pair.a.send(Uint8List.fromList([1, 2]));
      await pair.b.send(Uint8List.fromList([3, 4]));
      await waitFor(
          () => pair.receivedByB.isNotEmpty && pair.receivedByA.isNotEmpty);
      expect(pair.receivedByB.single, [1, 2]);
      expect(pair.receivedByA.single, [3, 4]);
      expect(applierB, isNotNull);
      pair.dispose();
      for (final id in [idA, idB]) {
        ErmesPeerCipherHandler().remove(peerCipherKey(id, _v4));
      }
    });
  });
}

void _testOrcErmesRotation() {
  group('OrcErmes public-key rotation (RFC 8.6)', () {
    test('republishes a new public key under the same IdSignaling', () async {
      final ke = await ECDHKeyExchangeService.generateNewService();
      final account = 1001.toRadixString(16).padLeft(64, '0');
      final peer = await createInMemoryPeer(
        accountId: account,
        store: {},
        subscriptions: {},
        enableEncryption: true,
        keyExchange: ke,
      );
      await peer.orc.publishSignal();
      final before = await peer.server.getSignal(account, forceRefresh: true);
      await peer.orc.rotatePublicKey();
      final after = await peer.server.getSignal(account, forceRefresh: true);
      expect(after.idSignaling, before.idSignaling);
      expect(after.publicKey, isNot(before.publicKey));
      expect(after.publicKey, ke.publicKey);
      await peer.orc.destroy(force: true);
    });

    test('rotation is a no-op without encryption', () async {
      final account = 1002.toRadixString(16).padLeft(64, '0');
      final peer = await createInMemoryPeer(
          accountId: account, store: {}, subscriptions: {});
      await peer.orc.rotatePublicKey();
      await expectLater(
          peer.server.getSignal(account, forceRefresh: true),
          throwsA(anything));
      await peer.orc.destroy(force: true);
    });

    test('re-published peer signal re-derives the session keys', () async {
      final store = <String, List<int>>{};
      final subs = <String, List<InMemorySubscription>>{};
      final ke = await ECDHKeyExchangeService.generateNewService();
      final remote = await ECDHKeyExchangeService.generateNewService();
      final idR = 1003.toRadixString(16).padLeft(64, '0');
      final r = await createInMemoryPeer(
          accountId: idR, store: store, subscriptions: subs,
          enableEncryption: true, keyExchange: remote);
      final reader = await createInMemoryPeer(
          accountId: 1004.toRadixString(16).padLeft(64, '0'),
          store: store, subscriptions: subs);
      await r.orc.publishSignal();
      final first = await reader.server.getSignal(idR, forceRefresh: true);
      final applier = OrcSignalCipherApplier(ke)
        ..apply(idR, first.publicKey, _v4, idSignaling: first.idSignaling);
      final lastSeen = ErmesSignalLastSeenStore()..record(idR, first);
      expect(await rederiveOnRepublishedSignal(
          reader.server, applier, lastSeen, idR), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await r.orc.rotatePublicKey();
      expect(await rederiveOnRepublishedSignal(
          reader.server, applier, lastSeen, idR), isTrue);
      final fresh = deriveDirectionalCiphers(remote, ke.publicKey, _v4);
      expect(_cipherOf(idR).decrypt(_frame(fresh.encrypt, [8])), [8]);
      expect(await rederiveOnRepublishedSignal(
          reader.server, null, lastSeen, idR), isFalse);
      await r.orc.destroy(force: true);
      await reader.orc.destroy(force: true);
    });
  });
}
