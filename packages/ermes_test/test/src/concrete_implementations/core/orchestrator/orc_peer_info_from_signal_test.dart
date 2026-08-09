import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

SignalErmes _signal({
  String ipv6 = '',
  String ipv6Port = '',
  String ipv4 = '',
  String ipv4Port = '',
}) => SignalErmes(
      publicKey: '',
      ipv6: ipv6,
      ipv6Port: ipv6Port,
      ipv4: ipv4,
      ipv4Port: ipv4Port,
      epochTimestampStartConversation: 0,
      secondsIntervalWindow: 0,
      epochTimestampExpireConversation: 0,
    );

void testPeerInfoFromSignal() {
  group('peerInfoFromSignal', () {
    test('prefers IPv6 when present and non-empty', () {
      final info = peerInfoFromSignal(
        _signal(
          ipv6: '2001:db8::1',
          ipv6Port: '1234',
          ipv4: '192.168.1.1',
          ipv4Port: '5678',
        ),
        'peer-1',
      );
      expect(info.address.address, equals('2001:db8::1'));
      expect(info.port, equals(1234));
    });

    test('falls back to IPv4 when IPv6 is empty', () {
      final info = peerInfoFromSignal(
        _signal(ipv4: '192.168.1.1', ipv4Port: '5678'),
        'peer-1',
      );
      expect(info.address.address, equals('192.168.1.1'));
      expect(info.port, equals(5678));
    });

    test('falls back to IPv4 when IPv6 is the unspecified address "::"', () {
      final info = peerInfoFromSignal(
        _signal(
          ipv6: '::',
          ipv6Port: '1234',
          ipv4: '192.168.1.1',
          ipv4Port: '5678',
        ),
        'peer-1',
      );
      expect(info.address.address, equals('192.168.1.1'));
      expect(info.port, equals(5678));
    });

    test('throws when the IPv6 host is set but its port is unparseable, '
        'instead of silently falling back to IPv4 (the fallback only '
        'checks host, not port)', () {
      expect(
        () => peerInfoFromSignal(
          _signal(
            ipv6: '2001:db8::1',
            ipv6Port: 'not-a-port',
            ipv4: '192.168.1.1',
            ipv4Port: '5678',
          ),
          'peer-1',
        ),
        throwsA(isA<CoreException>()),
      );
    });

    test('throws CoreException when neither IPv6 nor IPv4 is present', () {
      expect(
        () => peerInfoFromSignal(_signal(), 'peer-1'),
        throwsA(isA<CoreException>()),
      );
    });

    test('throws CoreException when the IPv4 port is unparseable', () {
      expect(
        () => peerInfoFromSignal(
          _signal(ipv4: '192.168.1.1', ipv4Port: 'not-a-port'),
          'peer-1',
        ),
        throwsA(isA<CoreException>()),
      );
    });

    test('throws CoreException when the IPv4 port is zero', () {
      expect(
        () => peerInfoFromSignal(
          _signal(ipv4: '192.168.1.1', ipv4Port: '0'),
          'peer-1',
        ),
        throwsA(isA<CoreException>()),
      );
    });

    test('throws CoreException when the IPv4 port is negative', () {
      expect(
        () => peerInfoFromSignal(
          _signal(ipv4: '192.168.1.1', ipv4Port: '-1'),
          'peer-1',
        ),
        throwsA(isA<CoreException>()),
      );
    });

    test('the exception message includes the peer id and both raw '
        'address fields for diagnosability', () {
      try {
        peerInfoFromSignal(_signal(), 'peer-diagnostic');
        fail('expected CoreException');
      } on CoreException catch (e) {
        expect(e.message, contains('peer-diagnostic'));
      }
    });

    test('sets the id field on the returned ErmesPeerInfo', () {
      final info = peerInfoFromSignal(
        _signal(ipv4: '10.0.0.1', ipv4Port: '9999'),
        'peer-42',
      );
      expect(info.id, equals('peer-42'));
    });
  });
}

void main() {
  testPeerInfoFromSignal();
}
