import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
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

const _fast = OrcSignalRepublishSettings(
  checkInterval: Duration(milliseconds: 150),
  minInterval: Duration.zero,
);

void main() {
  setUpAll(registerErmesStorageHandlers);
  testOrcSignalRepublishWiring();
  testOrchestratorSettingsInjection();
}

/// Opens a static (relay-free) connection between two in-memory peers, the
/// first one using [settings], and returns the shared relay store.
Future<(Map<String, List<int>>, OrcErmes, OrcErmes)> _connectedPair(
  int base,
  OrcSignalRepublishSettings settings,
) async {
  final store = <String, List<int>>{};
  final a = await createInMemoryPeer(
    accountId: _id(base),
    store: store,
    subscriptions: {},
    republishSettings: settings,
  );
  final b = await createInMemoryPeer(
    accountId: _id(base + 1),
    store: store,
    subscriptions: {},
    republishSettings: const OrcSignalRepublishSettings.disabled(),
  );
  await Future.wait([
    a.orc.openConnection(
      _id(base + 1),
      staticPeerSignal: _staticSignal('b', b.raw.port),
    ),
    b.orc.openConnection(
      _id(base),
      staticPeerSignal: _staticSignal('a', a.raw.port),
    ),
  ]);
  return (store, a.orc, b.orc);
}

Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 600));

void testOrcSignalRepublishWiring() {
  group('OrcErmes signal republisher', () {
    test('defaults: enabled, 60 s check, 30 s flapping guard', () {
      const s = OrcSignalRepublishSettings();
      expect(s.enabled, isTrue);
      expect(s.checkInterval, const Duration(seconds: 60));
      expect(s.minInterval, const Duration(seconds: 30));
      expect(const OrcSignalRepublishSettings.disabled().enabled, isFalse);
    });

    test('started by openConnection: publishes once per mapping', () async {
      final (store, a, b) = await _connectedPair(41, _fast);
      expect(store, isEmpty);
      await _wait();
      expect(store, isNotEmpty, reason: 'first check publishes the mapping');
      store.clear();
      await _wait();
      expect(store, isEmpty, reason: 'unchanged mapping is not republished');
      await a.destroy();
      await b.destroy();
    });

    test('rotation-style republish does not cause a second publish', () async {
      final (store, a, b) = await _connectedPair(43, _fast);
      await _wait();
      await a.publishSignal();
      store.clear();
      await _wait();
      expect(store, isEmpty);
      await a.destroy();
      await b.destroy();
    });

    test('stopped by destroy', () async {
      final (store, a, b) = await _connectedPair(45, _fast);
      await a.destroy();
      await b.destroy();
      store.clear();
      await _wait();
      expect(store, isEmpty);
    });

    test('disabled settings never publish', () async {
      final (store, a, b) = await _connectedPair(
        47,
        const OrcSignalRepublishSettings.disabled(),
      );
      await _wait();
      expect(store, isEmpty);
      await a.destroy();
      await b.destroy();
    });
  });
}

void testOrchestratorSettingsInjection() {
  group('registerOrchestratorSettings', () {
    test('registers republish settings and NAT detector', () {
      const key = 'orc-settings-ok';
      registerOrchestratorSettings(
        key: key,
        signalRepublish: _fast,
        symmetricNatMaxFailedAttempts: 10,
      );
      final r = RegistryManager.instance;
      expect(r.getInstance<OrcSignalRepublishSettings>(key: key), same(_fast));
      final d = r.getInstance<OrcSymmetricNatDetector>(key: key);
      expect(d.maxFailedAttempts, 10);
      expect(d.enabled, isTrue);
    });

    test('NAT detection is off by default', () {
      expect(defaultSymmetricNatMaxFailedAttempts, 0);
      expect(OrcSymmetricNatDetector().enabled, isFalse);
    });

    test('rejects a negative NAT threshold', () {
      expect(
        () => registerOrchestratorSettings(
          key: 'orc-settings-bad',
          signalRepublish: _fast,
          symmetricNatMaxFailedAttempts: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
