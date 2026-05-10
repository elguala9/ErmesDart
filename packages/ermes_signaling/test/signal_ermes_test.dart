import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

void main() {
  group('SignalErmes', () {
    test('should create with all fields', () {
      final signal = SignalErmes(
        publicKey: 'pubkey123',
        ipv6: '::1',
        ipv6Port: '8080',
        ipv4: '192.168.1.1',
        ipv4Port: '9000',
        epochTimestampStartConversation: 1000,
        secondsIntervalWindow: 10,
        epochTimestampExpireConversation: 2000,
      );

      expect(signal.publicKey, equals('pubkey123'));
      expect(signal.ipv4, equals('192.168.1.1'));
      expect(signal.toString(), contains('pubkey123'));
    });

    test('should serialize and deserialize', () {
      final original = SignalErmes(
        publicKey: 'pubkey456',
        ipv6: 'fe80::1',
        ipv6Port: '9090',
        ipv4: '10.0.0.1',
        ipv4Port: '7000',
        epochTimestampStartConversation: 5000,
        secondsIntervalWindow: 30,
        epochTimestampExpireConversation: 8000,
      );

      final serialized = original.toString();
      final deserialized = SignalErmes.fromString(serialized);

      expect(deserialized.publicKey, equals(original.publicKey));
      expect(deserialized.ipv4, equals(original.ipv4));
      expect(deserialized.epochTimestampStartConversation,
          equals(original.epochTimestampStartConversation));
    });

    test('should detect expired signal', () {
      final signal = SignalErmes(
        publicKey: 'test',
        ipv6: '',
        ipv6Port: '',
        ipv4: '',
        ipv4Port: '',
        epochTimestampStartConversation: 0,
        secondsIntervalWindow: 0,
        epochTimestampExpireConversation: 0,
      );

      expect(signal.isExpired(), isTrue);
    });

    test('should detect non-expired signal', () {
      final futureExpiration =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      final signal = SignalErmes(
        publicKey: 'test',
        ipv6: '',
        ipv6Port: '',
        ipv4: '',
        ipv4Port: '',
        epochTimestampStartConversation: 0,
        secondsIntervalWindow: 0,
        epochTimestampExpireConversation: futureExpiration,
      );

      expect(signal.isExpired(), isFalse);
    });

    test('should throw on invalid serialized string', () {
      expect(
        () => SignalErmes.fromString('invalid|format'),
        throwsArgumentError,
      );
    });

    test('should set signal via fromString', () {
      final signal = SignalErmes(
        publicKey: '',
        ipv6: '',
        ipv6Port: '',
        ipv4: '',
        ipv4Port: '',
        epochTimestampStartConversation: 0,
        secondsIntervalWindow: 0,
        epochTimestampExpireConversation: 0,
      );

      signal.signal = 'pk|ipv6|port6|ipv4|port4|100|10|200';
      expect(signal.publicKey, equals('pk'));
    });
  });

  group('SignalErmesRaw', () {
    test('should create raw signal', () {
      final raw = SignalErmesRaw(
        signal: 'test_signal',
        isEncrypted: false,
      );

      expect(raw.signal, equals('test_signal'));
      expect(raw.isEncrypted, isFalse);
      expect(raw.encryptionType, isNull);
    });

    test('should create raw signal with encryption type', () {
      final raw = SignalErmesRaw(
        signal: 'encrypted_signal',
        isEncrypted: true,
        encryptionType: SymmetricAlgorithm.aes as CryptoAlgorithm,
      );

      expect(raw.isEncrypted, isTrue);
      expect(raw.encryptionType, isNotNull);
    });

    test('should serialize and parse', () {
      final raw = SignalErmesRaw(
        signal: 'sig_data',
        isEncrypted: true,
        encryptionType: SymmetricAlgorithm.aes as CryptoAlgorithm,
      );

      final serialized = raw.toString();
      expect(serialized, startsWith('sig_data|true|'));

      final parsed = SignalErmesRaw(
        signal: '',
        isEncrypted: false,
      );
      parsed.fromString('other_sig|false|');

      expect(parsed.signal, equals('other_sig'));
      expect(parsed.isEncrypted, isFalse);
    });
  });
}
