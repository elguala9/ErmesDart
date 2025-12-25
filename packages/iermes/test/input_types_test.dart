import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('IdHandlerRepositoryInput', () {
    test('should create with all fields', () {
      const input = IdHandlerRepositoryInput(
        max: 1000,
        start: 0,
      );

      expect(input.max, equals(1000));
      expect(input.start, equals(0));
    });

    test('should create with null fields', () {
      const input = IdHandlerRepositoryInput();

      expect(input.max, isNull);
      expect(input.start, isNull);
    });
  });

  group('ErmesWebrtcRepositoryInput', () {
    test('should create with all fields', () {
      const input = ErmesWebrtcRepositoryInput(
        iceServers: [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      );

      expect(input.iceServers, isNotNull);
      expect(input.iceServers!.length, equals(1));
      expect(input.offer, isNull);
    });

    test('should create with null fields', () {
      const input = ErmesWebrtcRepositoryInput();

      expect(input.offer, isNull);
      expect(input.iceServers, isNull);
    });
  });
}
