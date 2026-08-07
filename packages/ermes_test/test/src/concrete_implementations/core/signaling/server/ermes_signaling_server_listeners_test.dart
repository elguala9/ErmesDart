import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

SignalErmes _signal() => SignalErmes(
      publicKey: 'pk',
      ipv6: '',
      ipv6Port: '',
      ipv4: '1.2.3.4',
      ipv4Port: '1000',
      epochTimestampStartConversation: 0,
      secondsIntervalWindow: 0,
      epochTimestampExpireConversation: 0,
    );

void testErmesSignalingServerListeners() {
  group('ErmesSignalingServerListeners', () {
    late ErmesSignalingServerListeners listeners;

    setUp(() {
      listeners = ErmesSignalingServerListeners();
    });

    test('starts with empty registries', () {
      expect(listeners.signalCallbacks, isEmpty);
      expect(listeners.errorCallbacks, isEmpty);
      expect(listeners.closeCallbacks, isEmpty);
    });

    group('notifySignal', () {
      test('does nothing when no callbacks are registered', () {
        expect(
          () => listeners.notifySignal(_signal(), 'peer-1'),
          returnsNormally,
        );
      });

      test('calls only the sender-specific callback for a matching sender',
          () {
        ISignalErmes? receivedByA;
        ISignalErmes? receivedByB;
        listeners
          ..onSignal((s) => receivedByA = s, 'peer-a')
          ..onSignal((s) => receivedByB = s, 'peer-b');
        final signal = _signal();
        listeners.notifySignal(signal, 'peer-a');
        expect(receivedByA, same(signal));
        expect(receivedByB, isNull);
      });

      test('does not call a sender-specific callback for a non-matching '
          'sender', () {
        var called = false;
        listeners
          ..onSignal((_) => called = true, 'peer-a')
          ..notifySignal(_signal(), 'peer-b');
        expect(called, isFalse);
      });

      test('wildcard callback (from=null) fires for any sender', () {
        final received = <ISignalErmes>[];
        listeners
          ..onSignal(received.add, null)
          ..notifySignal(_signal(), 'peer-a')
          ..notifySignal(_signal(), 'peer-b')
          ..notifySignal(_signal(), null);
        expect(received, hasLength(3));
      });

      test('both sender-specific and wildcard callbacks fire for a '
          'matching sender', () {
        var specificCalls = 0;
        var wildcardCalls = 0;
        listeners
          ..onSignal((_) => specificCalls++, 'peer-a')
          ..onSignal((_) => wildcardCalls++, null)
          ..notifySignal(_signal(), 'peer-a');
        expect(specificCalls, equals(1));
        expect(wildcardCalls, equals(1));
      });

      test('registering a second callback for the same sender replaces '
          'the first', () {
        var firstCalls = 0;
        var secondCalls = 0;
        listeners
          ..onSignal((_) => firstCalls++, 'peer-a')
          ..onSignal((_) => secondCalls++, 'peer-a')
          ..notifySignal(_signal(), 'peer-a');
        expect(firstCalls, equals(0));
        expect(secondCalls, equals(1));
      });

      test('notifySignal with null sender only triggers the wildcard '
          'callback, never a sender-specific one', () {
        var specificCalls = 0;
        var wildcardCalls = 0;
        listeners
          ..onSignal((_) => specificCalls++, 'peer-a')
          ..onSignal((_) => wildcardCalls++, null)
          ..notifySignal(_signal(), null);
        expect(specificCalls, equals(0));
        expect(wildcardCalls, equals(1));
      });
    });

    group('notifyError', () {
      test('does nothing when no callbacks are registered', () {
        expect(() => listeners.notifyError(Exception('boom')), returnsNormally);
      });

      test('invokes every registered error callback with the same error',
          () {
        final received = <Object>[];
        listeners
          ..onError(received.add)
          ..onError(received.add);
        final error = Exception('boom');
        listeners.notifyError(error);
        expect(received, equals([error, error]));
      });

      test('propagates a synchronous exception thrown by an error '
          'callback instead of swallowing it', () {
        listeners.onError((_) => throw StateError('listener failure'));
        expect(
          () => listeners.notifyError(Exception('boom')),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('notifyClose', () {
      test('does nothing when no callbacks are registered', () {
        expect(listeners.notifyClose, returnsNormally);
      });

      test('invokes every registered close callback exactly once', () {
        var firstCalls = 0;
        var secondCalls = 0;
        listeners
          ..onClose(() => firstCalls++)
          ..onClose(() => secondCalls++)
          ..notifyClose();
        expect(firstCalls, equals(1));
        expect(secondCalls, equals(1));
      });
    });

    group('clear', () {
      test('removes all signal, error and close callbacks', () {
        var signalCalls = 0;
        var errorCalls = 0;
        var closeCalls = 0;
        listeners
          ..onSignal((_) => signalCalls++, 'peer-a')
          ..onSignal((_) => signalCalls++, null)
          ..onError((_) => errorCalls++)
          ..onClose(() => closeCalls++)
          ..clear()
          ..notifySignal(_signal(), 'peer-a')
          ..notifyError(Exception('boom'))
          ..notifyClose();

        expect(signalCalls, equals(0));
        expect(errorCalls, equals(0));
        expect(closeCalls, equals(0));
        expect(listeners.signalCallbacks, isEmpty);
        expect(listeners.errorCallbacks, isEmpty);
        expect(listeners.closeCallbacks, isEmpty);
      });

      test('is idempotent when called on an already-empty registry', () {
        expect(() => listeners..clear()..clear(), returnsNormally);
      });

      test('registry is reusable after clear', () {
        var calls = 0;
        listeners
          ..onError((_) => calls++)
          ..clear()
          ..onError((_) => calls++)
          ..notifyError(Exception('boom'));
        expect(calls, equals(1));
      });
    });
  });
}

void main() {
  testErmesSignalingServerListeners();
}
