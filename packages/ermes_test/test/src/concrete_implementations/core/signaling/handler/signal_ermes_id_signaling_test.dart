import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

SignalErmes _signal(String id) => SignalErmes(
  idSignaling: id,
  publicKey: 'pk',
  ipv6: '',
  ipv6Port: '',
  ipv4: '1.2.3.4',
  ipv4Port: '4000',
  epochTimestampStartConversation: 100,
  epochTimestampExpireConversation: 700,
);

/// RFC section 6.1: the signal carries the publisher's IdSignaling.
void testSignalErmesIdSignaling() {
  group('SignalErmes IdSignaling', () {
    test('toString/fromString round-trips the id as 10th field', () {
      final parsed = SignalErmes.fromString(_signal('peer-a').toString());
      expect(parsed.idSignaling, 'peer-a');
      expect(parsed.ipv4Port, '4000');
      expect(parsed.secondsIntervalOpening, 60);
    });

    test('parse of a legacy 9-field signal throws', () {
      expect(
        () => SignalErmes.fromString('pk|||1.2.3.4|4000|100|10|700|60'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('parse of a legacy 8-field signal throws', () {
      expect(
        () => SignalErmes.fromString('pk|||1.2.3.4|4000|100|10|700'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('parse of a signal with empty id throws', () {
      expect(
        () => SignalErmes.fromString('pk|||1.2.3.4|4000|100|10|700|60|'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('id containing the field separator is rejected', () {
      expect(() => _signal('a|b'), throwsA(isA<ArgumentError>()));
    });
  });
}

void main() => testSignalErmesIdSignaling();
