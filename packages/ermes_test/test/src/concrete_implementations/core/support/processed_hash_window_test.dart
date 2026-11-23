import 'package:ermes_core/ermes_core.dart';
import 'package:test/test.dart';

/// Age-bounded dedup set for processed hashes (RFC 7.1, 10.2).
void testProcessedHashWindow() {
  group('ProcessedHashWindow', () {
    late int now;
    late ProcessedHashWindow window;

    setUp(() {
      now = 0;
      window = ProcessedHashWindowFactory.create(
        ProcessedHashWindowInput(nowMs: () => now),
      );
    });

    test('defaults to the 3600 s retention window', () {
      expect(
        ProcessedHashWindowFactory.create(
          const ProcessedHashWindowInput(),
        ).retention,
        const Duration(seconds: 3600),
      );
    });

    test('rejects a duplicate inside the window', () {
      expect(window.add('a'), isTrue);
      now = 3599 * 1000;
      expect(window.add('a'), isFalse);
      expect(window.contains('a'), isTrue);
    });

    test('forgets a hash once it is older than the window', () {
      window.add('a');
      now = 1000;
      window.add('b');
      now = 3600 * 1000;
      expect(window.contains('a'), isFalse);
      expect(window, hasLength(1));
      expect(window.add('a'), isTrue);
    });

    test('memory stays bounded by age, not by message count', () {
      for (var i = 0; i < 1000; i++) {
        now = i * 10 * 1000;
        window.add('h$i');
      }
      expect(window.length, lessThanOrEqualTo(361));
    });

    test('works as the decoder dedup set', () {
      expect(window.remove('missing'), isFalse);
      window.add('x');
      expect(window.remove('x'), isTrue);
      expect(window, isEmpty);
    });
  });
}

void main() => testProcessedHashWindow();
