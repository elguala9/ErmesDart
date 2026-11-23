import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

SignalErmes _signal({
  String ipv4 = '',
  String ipv4Port = '',
  String ipv6 = '',
  String ipv6Port = '',
}) => SignalErmes(
  idSignaling: 's',
  ipv4: ipv4,
  ipv4Port: ipv4Port,
  ipv6: ipv6,
  ipv6Port: ipv6Port,
  publicKey: '',
  epochTimestampStartConversation: 1,
  epochTimestampExpireConversation: 2,
);

const _both = [ErmesConnectionContext.ipv4, ErmesConnectionContext.ipv6];

void main() {
  testDualStackUnits();
}

/// Unit coverage of the per-family signal and key building blocks.
void testDualStackUnits() {
  group('peerInfosFromSignal', () {
    test('returns both families when the signal carries both', () {
      final infos = peerInfosFromSignal(
        _signal(
          ipv4: '1.2.3.4',
          ipv4Port: '1000',
          ipv6: '2001:db8::1',
          ipv6Port: '2000',
        ),
        'p',
        _both,
      );
      expect(infos.keys, _both);
      expect(infos[ErmesConnectionContext.ipv4]!.port, 1000);
      expect(infos[ErmesConnectionContext.ipv6]!.port, 2000);
    });

    test('IPv4-only and IPv6-only signals yield one family', () {
      expect(
        peerInfosFromSignal(
          _signal(ipv4: '1.2.3.4', ipv4Port: '1000'),
          'p',
          _both,
        ).keys,
        [ErmesConnectionContext.ipv4],
      );
      expect(
        peerInfosFromSignal(
          _signal(ipv6: '2001:db8::1', ipv6Port: '2000'),
          'p',
          _both,
        ).keys,
        [ErmesConnectionContext.ipv6],
      );
    });

    test('families we have no socket for are skipped', () {
      final infos = peerInfosFromSignal(
        _signal(
          ipv4: '1.2.3.4',
          ipv4Port: '1000',
          ipv6: '2001:db8::1',
          ipv6Port: '2000',
        ),
        'p',
        [ErmesConnectionContext.ipv6],
      );
      expect(infos.keys, [ErmesConnectionContext.ipv6]);
    });

    test('no common family yields an empty map', () {
      expect(
        peerInfosFromSignal(
          _signal(ipv4: '1.2.3.4', ipv4Port: '1000'),
          'p',
          [ErmesConnectionContext.ipv6],
        ),
        isEmpty,
      );
    });
  });

  group('buildLocalDualSignal', () {
    test('advertises an IPv4 pair and an IPv6 pair with their own ports', () {
      final signal = buildLocalDualSignal(
        [
          (publicIp: '1.2.3.4', publicPort: 1111),
          (publicIp: '2001:db8::1', publicPort: 2222),
        ],
        localIdSignaling: 'id',
      );
      expect(signal.ipv4, '1.2.3.4');
      expect(signal.ipv4Port, '1111');
      expect(signal.ipv6, '2001:db8::1');
      expect(signal.ipv6Port, '2222');
    });

    test('a single family leaves the other pair empty', () {
      final signal = buildLocalDualSignal(
        [(publicIp: '1.2.3.4', publicPort: 1111)],
        localIdSignaling: 'id',
      );
      expect(signal.ipv6, isEmpty);
      expect(signal.ipv6Port, isEmpty);
    });
  });

  group('OrcFamilySockets and ErmesConnectionKey', () {
    test('requires at least one socket', () {
      expect(OrcFamilySockets.new, throwsA(isA<CoreException>()));
    });

    test('connection keys differ per family and match cipher keys', () {
      const v4 = ErmesConnectionKey('p', ErmesConnectionContext.ipv4);
      const v6 = ErmesConnectionKey('p', ErmesConnectionContext.ipv6);
      expect(v4, isNot(v6));
      expect(v4.cipherKey, isNot(v6.cipherKey));
      expect(v4, const ErmesConnectionKey('p', ErmesConnectionContext.ipv4));
    });

    test('empty ErmesPeerConnections rejects sends', () {
      final held = ErmesPeerConnectionsFactory.create(
        const ErmesPeerConnectionsInput(peer: 'p'),
      );
      expect(held.isConnected(), isFalse);
      expect(
        () => held.send(Uint8List.fromList([1])),
        throwsA(isA<CoreException>()),
      );
    });
  });

  group('discoverSecondaryIpv6', () {
    test('skips an unreachable IPv6 family within its budget', () async {
      final silent =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(silent.close);
      final v6 = await createTestStunShspHandler();
      v6.setStunServer('127.0.0.1', silent.port);
      final sw = Stopwatch()..start();
      final found = await discoverSecondaryIpv6(v6);
      expect(found, isNull);
      expect(
        sw.elapsed,
        lessThan(secondaryStunBudget + const Duration(seconds: 2)),
      );
    });
  });
}
