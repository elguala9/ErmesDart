import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart' show ISymmetricCipher;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/in_memory_signaling.dart';

const _v4 = ErmesConnectionContext.ipv4;
const _tick = Duration(milliseconds: 50);

void main() {
  setUpAll(registerErmesStorageHandlers);
  testOrcRepublishedKeyWatcher();
}

/// RFC 8.6 / 6.1: background detection of a peer signal republished with a
/// new public key when the in-band `newpubkey` was lost.
void testOrcRepublishedKeyWatcher() {
  group('OrcRepublishedKeyWatcher (RFC 8.6)', () {
    _testLifecycle();
    _testOverRelay();
  });
}

OrcRepublishedKeyWatcher _watcher(
  Iterable<IdPeer> Function() peers,
  Future<bool> Function(IdPeer) check,
) =>
    OrcRepublishedKeyWatcherFactory.create(OrcRepublishedKeyWatcherInput(
        peers: peers, check: check, interval: _tick));

void _testLifecycle() {
  test('factory defaults the interval to 60 s', () {
    final w = OrcRepublishedKeyWatcherFactory.create(
        OrcRepublishedKeyWatcherInput(
            peers: () => const [], check: (_) async => false));
    expect(w.interval, defaultRepublishedKeyPollInterval);
    expect(w.interval, const Duration(seconds: 60));
  });

  test('polls every peer each interval and stops on dispose', () async {
    final seen = <IdPeer>[];
    final w = _watcher(() => ['a', 'b'], (p) async {
      seen.add(p);
      return p == 'b';
    });
    expect(await w.poll(), ['b']);
    seen.clear();
    w
      ..start()
      ..start();
    expect(w.isRunning, isTrue);
    await Future<void>.delayed(_tick * 3);
    expect(seen, containsAll(['a', 'b']));
    w.dispose();
    expect(w.isRunning, isFalse);
    seen.clear();
    await Future<void>.delayed(_tick * 3);
    expect(seen, isEmpty);
    expect(await w.poll(), isEmpty);
    w.start();
    expect(w.isRunning, isFalse);
  });

  test('a failing check propagates and does not wedge the watcher', () async {
    var fail = true;
    final w = _watcher(() => ['x'], (_) async {
      if (fail) {
        throw StateError('relay down');
      }
      return true;
    });
    await expectLater(w.poll(), throwsStateError);
    fail = false;
    expect(await w.poll(), ['x']);
  });
}

ErmesPeerCipher _cipherOf(String peer) =>
    ErmesPeerCipherHandler().get(peerCipherKey(peer, _v4))!;

DataEncrypted _frame(ISymmetricCipher c, List<int> data) => DataEncrypted(
    c.keyId, Uint8List.fromList(c.encrypt(Uint8List.fromList(data))));

void _testOverRelay() {
  test('rotation without newpubkey is re-derived within one interval, '
      'unchanged or older signals are not', () async {
    final store = <String, List<int>>{};
    final subs = <String, List<InMemorySubscription>>{};
    final ke = await ECDHKeyExchangeService.generateNewService();
    final remote = await ECDHKeyExchangeService.generateNewService();
    final idR = 2001.toRadixString(16).padLeft(64, '0');
    final r = await createInMemoryPeer(
        accountId: idR, store: store, subscriptions: subs,
        enableEncryption: true, keyExchange: remote);
    final reader = await createInMemoryPeer(
        accountId: 2002.toRadixString(16).padLeft(64, '0'),
        store: store, subscriptions: subs);
    await r.orc.publishSignal();
    final first = await reader.server.getSignal(idR, forceRefresh: true);
    final applier = OrcSignalCipherApplier(ke)
      ..apply(idR, first.publicKey, _v4, idSignaling: first.idSignaling);
    final lastSeen = ErmesSignalLastSeenStore()..record(idR, first);
    final hits = <IdPeer>[];
    final w = _watcher(() => [idR], (p) async {
      final changed = await rederiveOnRepublishedSignal(
          reader.server, applier, lastSeen, p);
      if (changed) {
        hits.add(p);
      }
      return changed;
    });
    final before = _cipherOf(idR).currentEncryptKeyId;
    expect(await w.poll(), isEmpty, reason: 'signal unchanged');
    expect(_cipherOf(idR).currentEncryptKeyId, before);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await r.orc.rotatePublicKey();
    w.start();
    await Future<void>.delayed(_tick * 4);
    expect(hits, [idR]);
    final fresh = deriveDirectionalCiphers(remote, ke.publicKey, _v4);
    expect(_cipherOf(idR).decrypt(_frame(fresh.encrypt, [9])), [9]);
    w.dispose();

    final current = await reader.server.getSignal(idR, forceRefresh: true);
    final newer = SignalErmes(
      idSignaling: current.idSignaling,
      publicKey: current.publicKey,
      ipv6: '', ipv6Port: '', ipv4: '127.0.0.1', ipv4Port: '4000',
      epochTimestampStartConversation:
          current.epochTimestampStartConversation + 3600,
      epochTimestampExpireConversation:
          current.epochTimestampExpireConversation + 7200,
    );
    lastSeen.record(idR, newer);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await r.orc.rotatePublicKey();
    final keyBefore = _cipherOf(idR).currentEncryptKeyId;
    expect(await rederiveOnRepublishedSignal(
        reader.server, applier, lastSeen, idR), isFalse,
        reason: 'older than the last-seen signal');
    expect(_cipherOf(idR).currentEncryptKeyId, keyBefore);
    await r.orc.destroy(force: true);
    await reader.orc.destroy(force: true);
  });
}
