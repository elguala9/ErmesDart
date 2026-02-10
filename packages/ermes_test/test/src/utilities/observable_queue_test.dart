import 'package:ermes_core/src/ermes_utility/observable_queue.dart';
import 'package:test/test.dart';

void main() {
  group('ObservableQueue', () {
    group('push and shift operations', () {
      test('push adds item and shift removes it', () {
        final queue = ObservableQueue<int>();
        queue.push(42);

        expect(queue.isEmpty(), isFalse);
        expect(queue.shift(), equals(42));
        expect(queue.isEmpty(), isTrue);
      });

      test('FIFO order is maintained', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        queue.push(2);
        queue.push(3);

        expect(queue.shift(), equals(1));
        expect(queue.shift(), equals(2));
        expect(queue.shift(), equals(3));
      });

      test('shift throws when empty', () {
        final queue = ObservableQueue<int>();

        expect(
          () => queue.shift(),
          throwsA(isA<StateError>()),
        );
      });

      test('length property is accurate', () {
        final queue = ObservableQueue<int>();

        expect(queue.length, equals(0));
        queue.push(1);
        expect(queue.length, equals(1));
        queue.push(2);
        expect(queue.length, equals(2));
        queue.shift();
        expect(queue.length, equals(1));
      });
    });

    group('max size limit', () {
      test('throws when exceeding max size', () {
        final queue = ObservableQueue<int>(2);
        queue.push(1);
        queue.push(2);

        expect(
          () => queue.push(3),
          throwsA(isA<StateError>()),
        );
      });

      test('allows max size items', () {
        final queue = ObservableQueue<int>(3);
        queue.push(1);
        queue.push(2);
        queue.push(3);

        expect(queue.length, equals(3));
      });

      test('allows adding after removing items', () {
        final queue = ObservableQueue<int>(2);
        queue.push(1);
        queue.push(2);
        queue.shift();

        expect(
          () => queue.push(3),
          isNot(throwsA(isA<StateError>())),
        );
      });
    });

    group('callbacks', () {
      test('onAddCallback is invoked on push', () {
        final queue = ObservableQueue<int>();
        var callbackCount = 0;

        queue.onAddCallback = () {
          callbackCount++;
        };

        queue.push(1);
        expect(callbackCount, equals(1));

        queue.push(2);
        expect(callbackCount, equals(2));
      });

      test('callback is not invoked before setting', () {
        final queue = ObservableQueue<int>();
        var callbackCount = 0;

        queue.push(1);
        expect(callbackCount, equals(0));

        queue.onAddCallback = () {
          callbackCount++;
        };

        queue.push(2);
        expect(callbackCount, equals(1));
      });

      test('callback can be changed', () {
        final queue = ObservableQueue<int>();
        var callback1Count = 0;
        var callback2Count = 0;

        queue.onAddCallback = () {
          callback1Count++;
        };

        queue.push(1);
        expect(callback1Count, equals(1));
        expect(callback2Count, equals(0));

        queue.onAddCallback = () {
          callback2Count++;
        };

        queue.push(2);
        expect(callback1Count, equals(1));
        expect(callback2Count, equals(1));
      });
    });

    group('clear operation', () {
      test('clears all items', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        queue.push(2);
        queue.push(3);

        queue.clear();

        expect(queue.isEmpty(), isTrue);
        expect(queue.length, equals(0));
      });
    });

    group('generic types', () {
      test('works with strings', () {
        final queue = ObservableQueue<String>();
        queue.push('hello');
        queue.push('world');

        expect(queue.shift(), equals('hello'));
        expect(queue.shift(), equals('world'));
      });
    });
  });
}
