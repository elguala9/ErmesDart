import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:ermes_test_shared/ermes_test_shared.dart';
import 'package:test/test.dart';

SignalErmes _signalAt(int startEpoch) => SignalErmes(
  publicKey: 'pk',
  ipv6: '',
  ipv6Port: '',
  ipv4: '20.161.44.177',
  ipv4Port: '10113',
  epochTimestampStartConversation: startEpoch,
  epochTimestampExpireConversation: startEpoch + 600,
);

void main() {
  group('isSignalFromThisRun', () {
    const runStart = 1800000000;

    test('accepts a signal published after the run started', () {
      expect(isSignalFromThisRun(_signalAt(runStart + 30), runStart), isTrue);
    });

    test('accepts a signal within the clock-skew tolerance', () {
      final s = _signalAt(runStart - signalClockSkewSeconds);
      expect(isSignalFromThisRun(s, runStart), isTrue);
    });

    test('rejects an unexpired leftover from a previous run', () {
      final s = _signalAt(runStart - 78);
      expect(s.epochTimestampExpireConversation, greaterThan(runStart));
      expect(isSignalFromThisRun(s, runStart), isFalse);
    });

    test('rejects a signal just outside the skew tolerance', () {
      final s = _signalAt(runStart - signalClockSkewSeconds - 1);
      expect(isSignalFromThisRun(s, runStart), isFalse);
    });
  });
}
