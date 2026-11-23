import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

SignalErmes _at(int start) => SignalErmes(
      idSignaling: 'peer',
      publicKey: '',
      ipv6: '',
      ipv6Port: '',
      ipv4: '1.2.3.4',
      ipv4Port: '2000',
      epochTimestampStartConversation: start,
      epochTimestampExpireConversation: start + 600,
    );

/// Tests for [IErmesSignalLastSeenStore] built through its factory.
void testErmesSignalLastSeenStore() {
  group('ErmesSignalLastSeenStore', () {
    late IErmesSignalLastSeenStore store;

    setUp(() {
      store = ErmesSignalLastSeenStoreFactory.create(
        const ErmesSignalLastSeenStoreInput(),
      );
    });

    test('factory returns a fresh, empty store each time', () {
      final other = ErmesSignalLastSeenStoreFactory.create(
        const ErmesSignalLastSeenStoreInput(),
      );
      expect(identical(store, other), isFalse);
      expect(store, isA<ErmesSignalLastSeenStore>());
      expect(store.isFresher('a', _at(1)), isTrue);
      expect(store.isRegression('a', _at(1)), isFalse);
    });

    test('older than last seen is a regression', () {
      store.record('a', _at(100));
      expect(store.isRegression('a', _at(99)), isTrue);
      expect(store.isFresher('a', _at(99)), isFalse);
    });

    test('equal start is the same signal: not a regression, not fresher', () {
      store.record('a', _at(100));
      expect(store.isRegression('a', _at(100)), isFalse);
      expect(store.isFresher('a', _at(100)), isFalse);
    });

    test('newer is fresher and record moves last seen forward', () {
      store.record('a', _at(100));
      expect(store.isFresher('a', _at(101)), isTrue);
      store.record('a', _at(101));
      expect(store.isRegression('a', _at(100)), isTrue);
    });

    test('record never moves last seen backwards', () {
      store
        ..record('a', _at(100))
        ..record('a', _at(50));
      expect(store.isRegression('a', _at(99)), isTrue);
    });

    test('counterparts are independent', () {
      store.record('a', _at(100));
      expect(store.isRegression('b', _at(1)), isFalse);
      expect(store.isFresher('b', _at(1)), isTrue);
    });

    test('clear forgets every counterpart', () {
      store
        ..record('a', _at(100))
        ..clear();
      expect(store.isRegression('a', _at(1)), isFalse);
    });
  });
}

void main() => testErmesSignalLastSeenStore();
