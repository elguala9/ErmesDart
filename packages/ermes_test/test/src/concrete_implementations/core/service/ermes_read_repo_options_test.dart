import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:test/test.dart';

void main() {
  testErmesReadRepoOptions();
}

void testErmesReadRepoOptions() {
  group('ErmesReadRepoOptions', () {
    test('all fields default to null when unspecified', () {
      const options = ErmesReadRepoOptions();

      expect(options.maxBufferSize, isNull);
      expect(options.maxMessageSize, isNull);
      expect(options.callbackOnDataArrived, isNull);
      expect(options.callbackOnMessageProcessed, isNull);
    });

    test('stores explicit buffer and message size limits', () {
      const options = ErmesReadRepoOptions(
        maxBufferSize: 50,
        maxMessageSize: 2048,
      );

      expect(options.maxBufferSize, equals(50));
      expect(options.maxMessageSize, equals(2048));
    });

    test('stores explicit callbacks', () {
      void onDataArrived(Uint8List data) {}
      Future<void> onProcessed() async {}

      final options = ErmesReadRepoOptions(
        callbackOnDataArrived: onDataArrived,
        callbackOnMessageProcessed: onProcessed,
      );

      expect(options.callbackOnDataArrived, same(onDataArrived));
      expect(options.callbackOnMessageProcessed, same(onProcessed));
    });

    test('is const-constructible', () {
      const a = ErmesReadRepoOptions(maxBufferSize: 10);
      const b = ErmesReadRepoOptions(maxBufferSize: 10);
      expect(a.maxBufferSize, equals(b.maxBufferSize));
    });
  });
}
