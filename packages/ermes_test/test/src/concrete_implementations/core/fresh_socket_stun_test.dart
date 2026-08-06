import 'dart:io';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

void testFreshSocketStun() {
  group('freshSocketStun', () {
    test('returns null when customStunHost is null', () async {
      final result = await freshSocketStun(
        customStunHost: null,
        customStunPort: 19302,
      );
      expect(result, isNull);
    });

    test('returns null when customStunPort is null', () async {
      final result = await freshSocketStun(
        customStunHost: 'stun.example.com',
        customStunPort: null,
      );
      expect(result, isNull);
    });

    test('returns null when both host and port are null', () async {
      final result = await freshSocketStun(
        customStunHost: null,
        customStunPort: null,
      );
      expect(result, isNull);
    });

    test(
      'an unresolvable custom host throws SocketException instead of '
      'returning null (the DNS lookup is not inside the try/catch that '
      'shields the rest of the function — documented discrepancy with '
      'the doc comment, which claims a null return on DNS failure)',
      () async {
        await expectLater(
          freshSocketStun(
            customStunHost: 'this-host-does-not-exist.invalid',
            customStunPort: 19302,
          ),
          throwsA(isA<SocketException>()),
        );
      },
    );

    test(
      'returns null after timing out when the host resolves but nothing '
      'answers the STUN binding request',
      () async {
        final result = await freshSocketStun(
          customStunHost: '127.0.0.1',
          customStunPort: 1,
        );
        expect(result, isNull);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}

void main() {
  testFreshSocketStun();
}
