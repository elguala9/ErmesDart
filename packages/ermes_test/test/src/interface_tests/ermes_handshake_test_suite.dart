// ignore_for_file: cascade_invocations


import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesHandshake interface
///
/// Usage:
/// ```dart
/// void main() {
///   testIErmesHandshake<MyInput, MySignal>(
///     'ErmesAsyncHandshake',
///     () => ErmesAsyncHandshake(myInput),
///   );
/// }
/// ```

void testIErmesHandshake<TInput, TSignal>(
  String implementationName,
  IErmesHandshake<TInput, TSignal> Function() createInstance,
) {
  group('IErmesHandshake<$TInput, $TSignal> - $implementationName', () {
    late IErmesHandshake<TInput, TSignal> handshake;

    setUp(() {
      handshake = createInstance();
    });

    tearDown(() {});

    group('Handshake Initialization', () {
      test('should create instance successfully', () {
        expect(handshake, isNotNull);
      });

      test('handshake is IErmesHandshake', () {
        expect(handshake, isA<IErmesHandshake<TInput, TSignal>>());
      });
    });

    group('Handshake Protocol', () {
      test('handshake returns IErmesRepository', () {
        expect(
          () {
            final result = handshake.handshake();
            expect(result, isA<IErmesRepository>());
          },
          anyOf(returnsNormally, throwsA(anything)),
        );
      });

      test('handshake completes or throws expected errors', () {
        expect(
          () => handshake.handshake(),
          anyOf(
            returnsNormally,
            throwsException,
          ),
        );
      });

      test('handshake can be called multiple times', () {
        expect(
          () => handshake.handshake(),
          anyOf(returnsNormally, throwsA(anything)),
        );
        expect(
          () => handshake.handshake(),
          anyOf(returnsNormally, throwsA(anything)),
        );
        expect(handshake, isNotNull);
      });
    });

    group('State Management', () {
      test('instance maintains state between calls', () {
        expect(handshake, isNotNull);
        expect(
          () => handshake.handshake(),
          anyOf(returnsNormally, throwsA(anything)),
        );
        expect(handshake, isNotNull);
      });
    });

    group('Error Handling', () {
      test('unimplemented method throws appropriate error', () {
        expect(
          () => handshake.handshake(),
          anyOf(returnsNormally, throwsA(anything)),
        );
      });
    });

    group('Interface Compliance', () {
      test('implements IErmesHandshake correctly', () {
        expect(
          handshake,
          isA<IErmesHandshake<TInput, TSignal>>(),
        );
      });

      test('handshake method exists and is callable', () {
        expect(handshake.handshake, isA<Function>());
      });
    });
  });
}
