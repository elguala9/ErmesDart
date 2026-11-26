import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../helpers/dual_stack_hosts.dart';

const _v4 = ErmesConnectionContext.ipv4;
const _v6 = ErmesConnectionContext.ipv6;

/// The concrete service behind [host]'s Connection to [peer] over [family].
ErmesService _service(DualHost host, String peer, ErmesConnectionContext f) {
  final service = host.orc.connectionOver(peer, f).service;
  if (service is! ErmesService) {
    throw StateError('unexpected service type ${service.runtimeType}');
  }
  return service;
}

/// Records the id of every message [service] puts on the wire from now on.
List<MessageType> _recordSent(ErmesService service) {
  final sent = <MessageType>[];
  service.ermesSendRepo.addOnMessageSendingListener(sent.add);
  return sent;
}

/// Distinct data-message ids in send order (a message is reported once
/// per notification, so duplicates are collapsed).
List<int> _dataIds(List<MessageType> sent) => {
  for (final m in sent)
    if (m.asData() != null) m.id,
}.toList();

void _expectContiguous(List<int> ids) {
  for (var i = 1; i < ids.length; i++) {
    expect(ids[i], ids[i - 1] + 1, reason: 'ids $ids are not contiguous');
  }
}

Future<void> _send(DualHost a, int n, ErmesConnectionContext f, int tag) async {
  for (var i = 0; i < n; i++) {
    final data = Uint8List.fromList([tag, i, 0]);
    await a.orc.sendOverFamily(data, _idB, family: f);
  }
}

var _pairs = 0;
var _idA = '';
var _idB = '';

/// Connects two fresh dual-stack hosts. Each pair gets its own account ids
/// so the per-Connection message storage never leaks between tests.
Future<(DualHost, DualHost)> _pair() async {
  final tag = (++_pairs).toRadixString(16).padLeft(4, '0');
  _idA = 'a' * 60 + tag;
  _idB = 'b' * 60 + tag;
  final store = <String, List<int>>{};
  final a = await dualHost(_idA, store, v4: true, v6: true);
  final b = await dualHost(_idB, store, v4: true, v6: true);
  addTearDown(a.close);
  addTearDown(b.close);
  await dualConnect(a, b);
  return (a, b);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));

void main() {
  testOrcDualStackIds();
}

/// RFC section 2: each address-family Connection owns its message-id
/// sequence; acks and missing-id requests on one family never touch the
/// other.
void testOrcDualStackIds() {
  group('OrcErmes dual-stack per-family id sequences', () {
    setUpAll(registerErmesStorageHandlers);

    test('each family numbers its messages from its own origin', () async {
      final (a, b) = await _pair();
      final s4 = _service(a, _idB, _v4);
      final s6 = _service(a, _idB, _v6);
      final sent4 = _recordSent(s4);
      final sent6 = _recordSent(s6);
      final origin6 = s6.idHandler.getCurrent();

      await _send(a, 3, _v4, 4);
      await _send(a, 5, _v6, 6);

      final ids4 = _dataIds(sent4);
      final ids6 = _dataIds(sent6);
      expect(ids4, hasLength(3));
      expect(ids6, hasLength(5));
      _expectContiguous(ids4);
      _expectContiguous(ids6);
      expect(ids6.first, origin6, reason: 'IPv4 traffic moved IPv6 ids');
      expect(ids6.first, lessThanOrEqualTo(ids4.last));
      expect(identical(s4.idHandler, s6.idHandler), isFalse);
      await dualExpectDelivered(b, Uint8List.fromList([6, 4, 0]));
    });

    test(
      'an acknowledge on IPv4 leaves the IPv6 Connection untouched',
      () async {
        final (a, b) = await _pair();
        await _send(a, 2, _v6, 6);
        final a6 = _service(a, _idB, _v6);
        final sent6 = _recordSent(a6);
        final current6 = a6.idHandler.getCurrent();

        final b4 = _service(b, _idA, _v4);
        final ack = ServiceMessageAcknowledge(
          id: b4.idHandler.getNewId(),
          ackCurrentId: b4.idHandler.getCurrent(),
          ackLastReceivedId: 0,
        );
        await b4.ermesSendRepo.sendMessageType([MessageType.service(ack)]);
        await _settle();

        expect(sent6, isEmpty);
        expect(a6.idHandler.getCurrent(), current6);
      },
    );

    test('a missing-id request on IPv4 is answered only on IPv4', () async {
      final (a, b) = await _pair();
      final a4 = _service(a, _idB, _v4);
      final a6 = _service(a, _idB, _v6);
      await _send(a, 6, _v6, 6);
      final sent4 = _recordSent(a4);
      final sent6 = _recordSent(a6);
      final current6 = a6.idHandler.getCurrent();
      // Ids minted only on IPv6: IPv4 never sent them.
      final unknown = [
        for (var i = 0; i < 4; i++) a4.idHandler.getCurrent() + i,
      ];

      final b4 = _service(b, _idA, _v4);
      final request = ServiceMessageArrayRequest(
        id: b4.idHandler.getNewId(),
        arrayId: unknown,
      );
      await b4.ermesSendRepo.sendMessageType([MessageType.service(request)]);
      await _settle();

      final gone = sent4
          .map((m) => m.asService())
          .whereType<ServiceMessageGone>()
          .toList();
      expect(gone, hasLength(1));
      expect(gone.single.arrayId, unknown);
      expect(sent6, isEmpty, reason: 'IPv6 must not resend for IPv4');
      expect(a6.idHandler.getCurrent(), current6);
    });

    test('a family that is not held cannot be addressed', () async {
      final (a, _) = await _pair();
      await a.orc.closeFamily(_idB, _v6);

      expect(
        () => a.orc.connectionOver(_idB, _v6),
        throwsA(isA<CoreException>()),
      );
      await expectLater(_send(a, 1, _v6, 6), throwsA(isA<Exception>()));
      await _send(a, 1, _v4, 4);
    });
  });
}
