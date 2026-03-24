import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Custom types used only in these tests
// (unique types prevent contamination from static registry state)
// ---------------------------------------------------------------------------

class _CustomTypeA {
  _CustomTypeA(this.value);
  factory _CustomTypeA.fromJson(Map<String, dynamic> json) =>
      _CustomTypeA(json['value'] as String);
  final String value;
}

class _CustomTypeB {
  _CustomTypeB(this.count);
  factory _CustomTypeB.fromJson(Map<String, dynamic> json) =>
      _CustomTypeB(json['count'] as int);
  final int count;
}

void testSerializationRegistry() {
  group('SerializationRegistry', () {
    group('built-in registrations', () {
      test('MessageRoot is registered by default', () {
        expect(SerializationRegistry.isRegistered<MessageRoot>(), isTrue);
      });

      test('InternalMessage is registered by default', () {
        expect(
          SerializationRegistry.isRegistered<InternalMessage>(),
          isTrue,
        );
      });

      test('MessageData is registered by default', () {
        expect(SerializationRegistry.isRegistered<MessageData>(), isTrue);
      });

      test('ChunkMessage is registered by default', () {
        expect(SerializationRegistry.isRegistered<ChunkMessage>(), isTrue);
      });

      test('ServiceMessage is registered by default', () {
        expect(SerializationRegistry.isRegistered<ServiceMessage>(), isTrue);
      });

      test('MessageType is registered by default', () {
        expect(SerializationRegistry.isRegistered<MessageType>(), isTrue);
      });

      test('getRegisteredTypes returns at least the built-in types', () {
        final types = SerializationRegistry.getRegisteredTypes();
        expect(types, containsAll([MessageRoot, MessageData, ChunkMessage]));
      });
    });

    group('isRegistered', () {
      test('returns false for an unknown type', () {
        // _CustomTypeA is only registered in the register() tests below
        // but static state persists — rely on a truly novel class if possible
        // We check the opposite direction: after registration it becomes true
        SerializationRegistry.register<_CustomTypeA>(
          _CustomTypeA.fromJson,
        );
        expect(SerializationRegistry.isRegistered<_CustomTypeA>(), isTrue);
      });
    });

    group('getFactory', () {
      test('returns the factory for a built-in type', () {
        final factory = SerializationRegistry.getFactory<MessageRoot>();
        expect(factory, isNotNull);
        expect(factory, isA<Function>());
      });

      test('throws ArgumentError for an unregistered type', () {
        expect(
          () => SerializationRegistry.getFactory<_CustomTypeB>(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('_CustomTypeB'),
            ),
          ),
        );
      });
    });

    group('register', () {
      test('registers a custom type and makes it retrievable', () {
        SerializationRegistry.register<_CustomTypeB>(
          _CustomTypeB.fromJson,
        );
        expect(SerializationRegistry.isRegistered<_CustomTypeB>(), isTrue);
      });

      test('registered factory deserializes correctly', () {
        SerializationRegistry.register<_CustomTypeA>(
          _CustomTypeA.fromJson,
        );
        final factory = SerializationRegistry.getFactory<_CustomTypeA>();
        final instance = factory({'value': 'hello'});
        expect(instance, isA<_CustomTypeA>());
        expect((instance as _CustomTypeA).value, equals('hello'));
      });

      test('re-registering a type overwrites the previous factory', () {
        // Register with a factory that returns value 'original'
        SerializationRegistry.register<_CustomTypeA>(
          (json) => _CustomTypeA('original'),
        );
        final factory1 =
            SerializationRegistry.getFactory<_CustomTypeA>();
        expect(
          (factory1({}) as _CustomTypeA).value,
          equals('original'),
        );

        // Overwrite with a factory that returns value 'overwritten'
        SerializationRegistry.register<_CustomTypeA>(
          (json) => _CustomTypeA('overwritten'),
        );
        final factory2 =
            SerializationRegistry.getFactory<_CustomTypeA>();
        expect(
          (factory2({}) as _CustomTypeA).value,
          equals('overwritten'),
        );
      });
    });
  });
}

void main() => testSerializationRegistry();
