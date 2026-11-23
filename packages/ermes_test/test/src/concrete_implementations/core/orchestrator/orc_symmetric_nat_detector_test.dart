import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testOrcSymmetricNatDetector();
}

void testOrcSymmetricNatDetector() {
  group('OrcSymmetricNatDetector', () {
    test('is disabled by default and never throws', () {
      final d = OrcSymmetricNatDetector();
      for (var i = 0; i < 10; i++) {
        d.record('p', connected: false);
      }
      d.assertAllowed('p');
    });

    test('flags a peer after the threshold of consecutive failures', () {
      final d = OrcSymmetricNatDetector(maxFailedAttempts: 3)
        ..record('p', connected: false)
        ..record('p', connected: false);
      expect(
        () => d.record('p', connected: false),
        throwsA(isA<ErmesSymmetricNatException>()),
      );
    });

    test('a flagged peer fails fast and the failure is not retryable', () {
      final d = OrcSymmetricNatDetector(maxFailedAttempts: 1);
      expect(
        () => d.record('p', connected: false),
        throwsA(isA<ErmesSymmetricNatException>()),
      );
      expect(
        () => d.assertAllowed('p'),
        throwsA(
          isA<ErmesSymmetricNatException>()
              .having((e) => e.isRetryable, 'isRetryable', isFalse),
        ),
      );
    });

    test('a success resets the counter (no false positive)', () {
      OrcSymmetricNatDetector(maxFailedAttempts: 2)
        ..record('p', connected: false)
        ..record('p', connected: true)
        ..record('p', connected: false)
        ..assertAllowed('p');
    });

    test('peers are tracked independently and reset clears the flag', () {
      final d = OrcSymmetricNatDetector(maxFailedAttempts: 1);
      expect(
        () => d.record('a', connected: false),
        throwsA(isA<ErmesSymmetricNatException>()),
      );
      d
        ..assertAllowed('b')
        ..reset('a')
        ..assertAllowed('a');
    });
  });
}
