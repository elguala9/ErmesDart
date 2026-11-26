import 'dart:typed_data';

import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/dual_stack_hosts.dart';

void main() {
  testOrcDualStack();
}

/// RFC sections 2, 5 and 6.2: one independent Connection per address family.
void testOrcDualStack() {
  group('OrcErmes dual-stack Connections', () {
    setUpAll(registerErmesStorageHandlers);

    test('dual-stack hosts open one Connection per family', () async {
      final store = <String, List<int>>{};
      final a = await dualHost(dualIdA, store, v4: true, v6: true);
      final b = await dualHost(dualIdB, store, v4: true, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);

      await dualConnect(a, b);

      expect(dualFamilies(a, dualIdB), {
        ErmesConnectionContext.ipv4,
        ErmesConnectionContext.ipv6,
      });
      expect(await a.orc.getConnections(), [dualIdB]);
    });

    test('IPv4-only peer yields a single IPv4 Connection', () async {
      final store = <String, List<int>>{};
      final a = await dualHost(dualIdA, store, v4: true, v6: true);
      final b = await dualHost(dualIdB, store, v4: true, v6: false);
      addTearDown(a.close);
      addTearDown(b.close);

      await dualConnect(a, b);

      expect(dualFamilies(a, dualIdB), {ErmesConnectionContext.ipv4});
      expect(dualFamilies(b, dualIdA), {ErmesConnectionContext.ipv4});
    });

    test('IPv6-only hosts yield a single IPv6 Connection', () async {
      final store = <String, List<int>>{};
      final a = await dualHost(dualIdA, store, v4: false, v6: true);
      final b = await dualHost(dualIdB, store, v4: false, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);

      await dualConnect(a, b);
      final data = Uint8List.fromList([7, 7, 7]);
      await a.orc.send(data, dualIdB);

      expect(dualFamilies(a, dualIdB), {ErmesConnectionContext.ipv6});
      await dualExpectDelivered(b, data);
    });

    test('families carry data independently and one can be closed', () async {
      final store = <String, List<int>>{};
      final a = await dualHost(dualIdA, store, v4: true, v6: true);
      final b = await dualHost(dualIdB, store, v4: true, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);
      await dualConnect(a, b);

      final over4 = Uint8List.fromList([4, 1, 1]);
      final over6 = Uint8List.fromList([6, 2, 2]);
      await a.orc.sendOverFamily(
        over4,
        dualIdB,
        family: ErmesConnectionContext.ipv4,
      );
      await a.orc.sendOverFamily(
        over6,
        dualIdB,
        family: ErmesConnectionContext.ipv6,
      );
      await dualExpectDelivered(b, over4);
      await dualExpectDelivered(b, over6);

      await a.orc.closeFamily(dualIdB, ErmesConnectionContext.ipv6);
      expect(dualFamilies(a, dualIdB), {ErmesConnectionContext.ipv4});

      final after = Uint8List.fromList([9, 3, 3]);
      await a.orc.sendOverFamily(
        after,
        dualIdB,
        family: ErmesConnectionContext.ipv4,
      );
      await dualExpectDelivered(b, after);
      await expectLater(
        a.orc.sendOverFamily(
          after,
          dualIdB,
          family: ErmesConnectionContext.ipv6,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('hosts with no common family fail to open', () async {
      final store = <String, List<int>>{};
      final a = await dualHost(dualIdA, store, v4: true, v6: false);
      final b = await dualHost(dualIdB, store, v4: false, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);

      await expectLater(
        Future.wait([
          a.orc.openConnection(dualIdB),
          b.orc.openConnection(dualIdA),
        ]),
        throwsA(isA<Exception>()),
      );
    });
  });
}
