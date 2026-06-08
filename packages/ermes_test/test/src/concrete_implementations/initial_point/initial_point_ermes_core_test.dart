import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:test/test.dart';

void testInitialPointErmesCore() {
  group('initialPointErmesCore', () {
    group('signaling init functions exist', () {
      test('initialPointErmesSignaling is a function', () {
        expect(initialPointErmesSignaling, isA<Function>());
      });

      test('initialPointErmesSignalingPartial is a function', () {
        expect(initialPointErmesSignalingPartial, isA<Function>());
      });
    });

    group('core init functions exist', () {
      test('initialPointErmesCore is a function', () {
        expect(initialPointErmesCore, isA<Function>());
      });

      test('getIOrcErmes is a function', () {
        expect(getIOrcErmes, isA<Function>());
      });
    });

    group('registry core functions', () {
      test('initialPointErmesCoreRegistry is a function', () {
        expect(initialPointErmesCoreRegistry, isA<Function>());
      });

      test('getIOrcErmesFromRegistry is a function', () {
        expect(getIOrcErmesFromRegistry, isA<Function>());
      });
    });

    group('signaling registry functions exist', () {
      test('initialPointErmesSignalingRegistry is a function', () {
        expect(initialPointErmesSignalingRegistry, isA<Function>());
      });

      test('initialPointErmesSignalingPartialRegistry is a function', () {
        expect(initialPointErmesSignalingPartialRegistry, isA<Function>());
      });
    });
  });
}

void main() {
  testInitialPointErmesCore();
}
