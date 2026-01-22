import 'dart:async';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

@includeInBarrelFile
void testIErmesService(
  String name,
  IErmesService service1,
  IErmesService service2,
) {
  group('IErmesService - $name', () {
    // Use the first provided service as the primary under test.
    late final service = service1;

    tearDown(() async {
      try {
        service.close();
      } on Exception {}
    });

    test('isConnected returns bool', () async {
      final r = service.isConnected();
      expect(r, isA<bool>());
    });

    test('onMessageData accepts callback', () {
      expect(() => service.onMessageData((_) {}), returnsNormally);
    });

    test('onDataSending accepts callback', () {
      expect(() => service.onDataSending((msg) {}), returnsNormally);
    });

    test('onDataSent accepts callback', () {
      expect(() => service.onDataSent((id) {}), returnsNormally);
    });

    test('send accepts data', () {
      expect(() => service.send(Uint8List(0)), returnsNormally);
    });

    test('close does not throw', () {
      expect(() => service.close(), returnsNormally);
    });

    test('service send/receive exchange between two instances', () async {
      final svcA = service1;
      final svcB = service2;

      // Expect the caller to have already wired repositories and connected
      // the two services. We just verify that sending on one results in the
      // other receiving the payload.
      final c = Completer<dynamic>();

      svcB.onMessageData((msg) {
        if (!c.isCompleted) c.complete(msg);
      });

      final payload = Uint8List.fromList([1, 2, 3]);
      svcA.send(payload);

      final r = await c.future.timeout(const Duration(milliseconds: 1000));
      expect(r, equals(payload));
    });
  });
}
