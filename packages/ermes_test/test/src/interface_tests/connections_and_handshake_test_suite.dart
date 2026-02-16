import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Minimal test implementation of IErmesConnection
class _DummyConnection implements IErmesConnection {
  @override
  Future<IErmesRepository> connect() async =>
      throw UnimplementedError('Test stub');

  @override
  IdPeer getIdConnection() => 'dummy-connection-id';

  @override
  IErmesRepository getIErmesRepository() =>
      throw UnimplementedError('Test stub');

  @override
  Future<void> destroyConnection({bool close = true}) async {}
}

@includeInBarrelFile
void testIErmesConnectionsHandler(
  String name,
  IErmesConnectionsHandler Function() create,
) {
  group('IErmesConnectionsHandler - $name', () {
    late IErmesConnectionsHandler h;

    setUp(() {
      h = create();
    });

    test('add/delete/get/save/load', () async {
      // create a minimal fake connection implementing IErmesConnection
      final conn = _DummyConnection();
      expect(() => h.addConnection(conn), returnsNormally);
      expect(() => h.getConnection('dummy'), returnsNormally);
      expect(() => h.deleteConnection(conn), returnsNormally);
      await h.saveState();
      await h.loadState();
    });
  });
}

@includeInBarrelFile
void testIErmesHandshake(
  String name,
  IErmesHandshake<dynamic, dynamic> Function() create,
) {
  group('IErmesHandshake - $name', () {
    late IErmesHandshake<dynamic, dynamic> hs;

    setUp(() {
      hs = create();
    });

    test('basic contract', () {
      expect(() => hs.toString(), returnsNormally);
    });
  });
}

@includeInBarrelFile
void testIOrcErmes(String name, IOrcErmes Function() create) {
  group('IOrcErmes - $name', () {
    late IOrcErmes orc;

    setUp(() {
      orc = create();
    });

    test('send/onMessage/open/close/destroy/save/getConnections', () async {
      final data = Uint8List.fromList([]);
      await orc.send(data, 'peer');
      await orc.onMessage((d, p) async {});
      await orc.openConnection('peer');
      await orc.closeConnection('peer');
      await orc.destroy();
      await orc.save();
      final conns = await orc.getConnections();
      expect(conns, isA<IdPeer>());
    });
  });
}
