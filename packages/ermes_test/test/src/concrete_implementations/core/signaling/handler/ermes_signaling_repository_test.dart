
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_signaling_helper.dart';

void testErmesSignalingRepository() {
  group('ErmesSignalingRepository.getLastSignal', () {
    test('returns null before any signal received', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );
        final lastSignal = await repo.getLastSignal();
        expect(lastSignal, isNull);
      } finally {
        await setup.dispose();
      }
    });

    test('returns signal after setSignal notifies locally', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );

        final signal = SignalErmes(
          publicKey: 'sender-pubkey',
          ipv6: '',
          ipv6Port: '',
          ipv4: '127.0.0.1',
          ipv4Port: '9000',
          epochTimestampStartConversation: 1000,
          epochTimestampExpireConversation: 2000,
        );

        await setup.signalingServer.setSignal(signal, setup.accountId);

        final lastSignal = await repo.getLastSignal();
        expect(lastSignal, isA<ISignalErmes>());
        expect(lastSignal!.publicKey, equals('sender-pubkey'));
      } finally {
        await setup.dispose();
      }
    });

    test('returns most recent signal after multiple signals', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );

        final signal1 = SignalErmes(
          publicKey: 'first',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 1000,
        );
        final signal2 = SignalErmes(
          publicKey: 'last',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 2000,
        );

        await setup.signalingServer.setSignal(signal1, 'peer-1');
        await setup.signalingServer.setSignal(signal2, 'peer-2');

        final lastSignal = await repo.getLastSignal();
        expect(lastSignal!.publicKey, equals('last'));
      } finally {
        await setup.dispose();
      }
    });

    test('still returns signal after removeAllListeners', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );

        final signal = SignalErmes(
          publicKey: 'persistent',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 1000,
        );

        await setup.signalingServer.setSignal(signal, setup.accountId);

        repo.removeAllListeners();

        final lastSignal = await repo.getLastSignal();
        expect(lastSignal!.publicKey, equals('persistent'));
      } finally {
        await setup.dispose();
      }
    });
  });

  group('ErmesSignalingRepository.getLastSignalForced', () {
    test('returns null before any signal received', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );
        final result = await repo.getLastSignalForced();
        expect(result, isNull);
      } finally {
        await setup.dispose();
      }
    });

    test('returns signal after setSignal notifies locally', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );

        final signal = SignalErmes(
          publicKey: 'sender-pubkey',
          ipv6: '',
          ipv6Port: '',
          ipv4: '127.0.0.1',
          ipv4Port: '9000',
          epochTimestampStartConversation: 1000,
          epochTimestampExpireConversation: 2000,
        );

        await setup.signalingServer.setSignal(signal, setup.accountId);

        final result = await repo.getLastSignalForced();
        expect(result, isA<ISignalErmes>());
        expect(result!.publicKey, equals('sender-pubkey'));
      } finally {
        await setup.dispose();
      }
    });

    test('returns most recent signal after multiple signals', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );

        final signal1 = SignalErmes(
          publicKey: 'first',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 1000,
        );
        final signal2 = SignalErmes(
          publicKey: 'last',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 2000,
        );

        await setup.signalingServer.setSignal(signal1, 'peer-1');
        await setup.signalingServer.setSignal(signal2, 'peer-2');

        final result = await repo.getLastSignalForced();
        expect(result!.publicKey, equals('last'));
      } finally {
        await setup.dispose();
      }
    });

    test('still returns signal after removeAllListeners', () async {
      final setup = await createTestSignalingSetup();
      try {
        final repo = ErmesSignalingFactory.createRepository(
          setup.signalingServer,
          setup.signalingHandler,
        );

        final signal = SignalErmes(
          publicKey: 'persistent',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 1000,
        );

        await setup.signalingServer.setSignal(signal, setup.accountId);

        repo.removeAllListeners();

        final result = await repo.getLastSignalForced();
        expect(result!.publicKey, equals('persistent'));
      } finally {
        await setup.dispose();
      }
    });
  });
}

void main() {
  testErmesSignalingRepository();
}
