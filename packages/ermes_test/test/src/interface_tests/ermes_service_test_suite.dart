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

    test('isOpen returns bool', () async {
      final r = service.isOpen();
      expect(r, isA<bool>());
    });

    test('addOnMessageDataListener accepts callback', () {
      expect(() => service.addOnMessageDataListener((_) {}), returnsNormally);
    });

    test('addOnDataSendingListener accepts callback', () {
      expect(() => service.addOnDataSendingListener((msg) {}), returnsNormally);
    });

    test('addOnDataSentListener accepts callback', () {
      expect(() => service.addOnDataSentListener((id) {}), returnsNormally);
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

      svcB.addOnMessageDataListener((msg) {
        if (!c.isCompleted) c.complete(msg);
      });

      final payload = Uint8List.fromList([1, 2, 3]);
      svcA.send(payload);

      final r = await c.future.timeout(const Duration(milliseconds: 1000));
      expect(r, equals(payload));
    });
  });
}
