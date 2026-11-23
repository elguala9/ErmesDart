import 'dart:async';
import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show ShspNetworkException;
import 'package:test/test.dart';

import '../../../helpers/in_memory_signaling.dart';

String _id(int v) => v.toRadixString(16).padLeft(64, '0');

SignalErmes _staticSignal(String idSignaling, int port) {
  final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  return SignalErmes(
    idSignaling: idSignaling,
    ipv4: '127.0.0.1',
    ipv4Port: port.toString(),
    ipv6: '',
    ipv6Port: '',
    publicKey: '',
    epochTimestampStartConversation: ts,
    epochTimestampExpireConversation: ts + 600,
  );
}

void main() {
  setUpAll(registerErmesStorageHandlers);
  testStaticSignalOpen();
  testSymmetricNatFailure();
}

void testStaticSignalOpen() {
  group('OrcErmes.openConnection(staticPeerSignal)', () {
    test('connects without touching the relay', () async {
      final store = <String, List<int>>{};
      final a = await createInMemoryPeer(
        accountId: _id(21),
        store: store,
        subscriptions: {},
      );
      final b = await createInMemoryPeer(
        accountId: _id(22),
        store: store,
        subscriptions: {},
      );
      await Future.wait([
        a.orc.openConnection(
          _id(22),
          staticPeerSignal: _staticSignal('b', b.raw.port),
        ),
        b.orc.openConnection(
          _id(21),
          staticPeerSignal: _staticSignal('a', a.raw.port),
        ),
      ]);
      // Nothing was published, and a relay wait would have timed out (60 s).
      expect(store, isEmpty);
      expect(await a.orc.getConnections(), contains(_id(22)));
      expect(await b.orc.getConnections(), contains(_id(21)));
      await a.orc.destroy();
      await b.orc.destroy();
    });
  });
}

/// Runs [body] in a guarded zone: tearing down a never-answered dial leaves
/// SHSP handshake-retry timers that report [ShspNetworkException] on the
/// closed peer. That is transport noise, not under test; anything else fails.
Future<void> _tolerateShspTeardown(Future<void> Function() body) {
  final done = Completer<void>();
  runZonedGuarded(() async {
    try {
      await body();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      done.complete();
    } catch (e, st) {
      done.completeError(e, st);
    }
  }, (e, st) {
    if (e is! ShspNetworkException && !done.isCompleted) {
      done.completeError(e, st);
    }
  });
  return done.future;
}

void testSymmetricNatFailure() {
  group('OrcErmes symmetric NAT detection', () {
    final dead = _id(31);

    Future<void> withOrc(Future<void> Function(OrcErmes orc) body) =>
        _tolerateShspTeardown(() async {
          // Bound but never answering: a peer a hole punch cannot reach.
          final silent =
              await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
          final p = await createInMemoryPeer(
            accountId: _id(30),
            store: {},
            subscriptions: {},
          );
          final orc = OrcErmes(
            signalingServer: p.server,
            signalingHandler: p.handler,
            socket: p.shsp,
            bookService: p.book,
            enableEncryption: false,
            connectionTimeoutMs: 300,
            natDetector: OrcSymmetricNatDetector(maxFailedAttempts: 2),
          );
          try {
            await body(orc);
          } finally {
            await orc.destroy(force: true);
            silent.close();
          }
        });

    test('yields a permanent failure, then fails fast without retry', () async {
      await withOrc((orc) async {
        final signal = _staticSignal('d', 1);
        await orc.openConnection(dead, staticPeerSignal: signal);
        await expectLater(
          orc.openConnection(dead, staticPeerSignal: signal),
          throwsA(isA<ErmesSymmetricNatException>()),
        );
        final sw = Stopwatch()..start();
        await expectLater(
          orc.openConnection(dead, staticPeerSignal: signal),
          throwsA(isA<ErmesSymmetricNatException>()),
        );
        expect(sw.elapsedMilliseconds, lessThan(200));
      });
    });

    test('reconnect loop does not retry and notifies disconnect', () async {
      await withOrc((orc) async {
        final signal = _staticSignal('d', 1);
        await orc.openConnection(dead, staticPeerSignal: signal);
        await expectLater(
          orc.openConnection(dead, staticPeerSignal: signal),
          throwsA(isA<ErmesSymmetricNatException>()),
        );
        final notified = <IdPeer>[];
        await orc.onDisconnect(notified.add);
        final sw = Stopwatch()..start();
        await orc.handlePeerDisconnect(dead);
        expect(notified, [dead]);
        // One backoff step only (1 s), not 1 + 2 + 4 s of retries.
        expect(sw.elapsedMilliseconds, lessThan(2500));
      });
    });
  });
}
