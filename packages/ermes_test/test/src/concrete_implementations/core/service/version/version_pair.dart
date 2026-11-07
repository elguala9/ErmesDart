import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';

import '../../../../helpers/test_helpers.dart';

/// One direction of a lossless in-process link between two repositories.
/// While [up] is false frames are parked and flushed by [open].
class VersionLink {
  VersionLink(this.target);

  final TestErmesRepository target;
  bool up = false;
  bool drop = false;
  final List<Uint8List> parked = [];

  void carry(Uint8List frame) {
    if (drop) {
      return;
    }
    if (!up) {
      parked.add(frame);
      return;
    }
    scheduleMicrotask(() => target.simulateDataReceived(frame));
  }

  void open() {
    up = true;
    final pending = List<Uint8List>.of(parked);
    parked.clear();
    pending.forEach(carry);
  }
}

/// Two real [ErmesService]s, each with version negotiation enabled, wired
/// back to back over [TestErmesRepository] (real SHSP repositories whose
/// outbound frames are handed to the partner instead of a UDP socket).
class VersionPair {
  VersionPair._(this.repoA, this.repoB, this.aToB, this.bToA);

  static int _counter = 0;

  static Future<VersionPair> create({
    ProtocolVersion? versionA,
    ProtocolVersion? versionB,
    Duration timeout = const Duration(seconds: 2),
    bool linked = true,
  }) async {
    _counter++;
    final repoA = await TestErmesRepository.create(
      open: true, peerId: 'vn-b-$_counter',
    );
    final repoB = await TestErmesRepository.create(
      open: true, peerId: 'vn-a-$_counter',
    );
    final pair = VersionPair._(
      repoA, repoB, VersionLink(repoB), VersionLink(repoA),
    );
    repoA.onSend = pair.aToB.carry;
    repoB.onSend = pair.bToA.carry;
    pair
      ..a = _service(repoA, versionA, timeout, pair.receivedByA)
      ..b = _service(repoB, versionB, timeout, pair.receivedByB);
    if (linked) {
      pair.link();
    }
    return pair;
  }

  static ErmesService _service(
    TestErmesRepository repo,
    ProtocolVersion? version,
    Duration timeout,
    List<Uint8List> sink,
  ) =>
      ErmesServiceFactory.createService(
        100, 1024, repo, IdHandlerServiceFactory.createDefault(),
        sink.add, null, null, null, null,
        versionNegotiation: ErmesVersionNegotiationOptions(
          localVersion: version,
          timeout: timeout,
          resendInterval: const Duration(milliseconds: 40),
        ),
      );

  final TestErmesRepository repoA;
  final TestErmesRepository repoB;
  final VersionLink aToB;
  final VersionLink bToA;
  late final ErmesService a;
  late final ErmesService b;
  final List<Uint8List> receivedByA = [];
  final List<Uint8List> receivedByB = [];

  void link() {
    aToB.open();
    bToA.open();
  }

  IErmesVersionNegotiation get negA => a.versionNegotiation!;
  IErmesVersionNegotiation get negB => b.versionNegotiation!;

  void dispose() {
    a.close();
    b.close();
    repoA.cleanUp();
    repoB.cleanUp();
  }
}

/// Decodes the inner message of a plaintext wire frame.
MessageType innerOf(Uint8List frame) {
  final decoded = decodeMessageEnvelope(frame, 'inspect', <String>{});
  return uint8ArrayToObject<InternalMessage>(decoded!.plainBytes).message;
}

/// Returns [frame] with its envelope `v` replaced by [v].
Uint8List withEnvelopeVersion(Uint8List frame, String v) {
  final json = jsonDecode(utf8.decode(frame));
  if (json is! Map<String, dynamic>) {
    throw StateError('not an envelope');
  }
  json['v'] = v;
  return Uint8List.fromList(utf8.encode(jsonEncode(json)));
}

/// Polls [condition] until true or [timeout] elapses.
Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
