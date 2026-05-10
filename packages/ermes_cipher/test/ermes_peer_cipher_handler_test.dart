import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesPeerCipherHandler', () {
    test('should be a singleton', () {
      final handler1 = ErmesPeerCipherHandler();
      final handler2 = ErmesPeerCipherHandler();

      expect(identical(handler1, handler2), isTrue);
    });

    test('should manage peer ciphers by peerId', () {
      final handler = ErmesPeerCipherHandler();
      final cipher = ErmesPeerCipher();

      handler.set('peer1', cipher);

      final retrieved = handler.get('peer1');
      expect(retrieved, equals(cipher));
    });

    test('should return null for unknown peer', () {
      final handler = ErmesPeerCipherHandler();

      final retrieved = handler.get('unknown_peer');
      expect(retrieved, isNull);
    });

    test('should remove peer cipher', () {
      final handler = ErmesPeerCipherHandler();
      final cipher = ErmesPeerCipher();

      handler.set('peer1', cipher);
      handler.remove('peer1');

      final retrieved = handler.get('peer1');
      expect(retrieved, isNull);
    });

    test('should check if key exists', () {
      final handler = ErmesPeerCipherHandler();
      handler.set('peer1', ErmesPeerCipher());

      expect(handler.contains('peer1'), isTrue);
      expect(handler.contains('unknown'), isFalse);
    });

    test('keys returns all peer IDs', () {
      final handler = ErmesPeerCipherHandler();
      handler.set('keys_test_a', ErmesPeerCipher());
      handler.set('keys_test_b', ErmesPeerCipher());

      expect(handler.keys, containsAll(['keys_test_a', 'keys_test_b']));
    });

    test('values returns all cipher instances', () {
      final handler = ErmesPeerCipherHandler();
      final cipher1 = ErmesPeerCipher();
      final cipher2 = ErmesPeerCipher();
      handler.set('values_test_a', cipher1);
      handler.set('values_test_b', cipher2);

      expect(handler.values, containsAll([cipher1, cipher2]));
    });

    test('clear removes all entries', () {
      final handler = ErmesPeerCipherHandler();
      handler.set('clear_test_a', ErmesPeerCipher());
      handler.set('clear_test_b', ErmesPeerCipher());

      handler.clear();

      expect(handler.get('clear_test_a'), isNull);
      expect(handler.get('clear_test_b'), isNull);
      expect(handler.length, equals(0));
    });

    test('length returns correct count', () {
      final handler = ErmesPeerCipherHandler();
      expect(handler.length, equals(0));

      handler.set('length_test_a', ErmesPeerCipher());
      expect(handler.length, equals(1));

      handler.set('length_test_b', ErmesPeerCipher());
      expect(handler.length, equals(2));
    });
  });
}
