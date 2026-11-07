import 'dart:async';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'version_pair.dart';

const _v30 = ProtocolVersion.current;

/// RFC ermes-protocol 7.1: ERMES version negotiation between two real
/// [ErmesService]s.
void testErmesVersionNegotiation() {
  group('ERMES version negotiation (RFC 7.1)', () {
    late VersionPair pair;

    setUpAll(registerErmesStorageHandlers);
    tearDown(() => pair.dispose());

    test('same version: both sides negotiate 3.0 and exchange data', () async {
      pair = await VersionPair.create();
      expect(await pair.negA.ready, _v30);
      expect(await pair.negB.ready, _v30);
      await pair.a.send(Uint8List.fromList([1, 2, 3]));
      await waitFor(() => pair.receivedByB.isNotEmpty);
      expect(pair.receivedByB.single, [1, 2, 3]);
    });

    test('3.2 vs 3.0: both adopt the lower minor 3.0', () async {
      pair = await VersionPair.create(versionA: const ProtocolVersion(3, 2));
      expect(await pair.negA.ready, _v30);
      expect(await pair.negB.ready, _v30);
      expect(pair.negA.envelopeVersion, _v30);
    });

    test('3.x vs 4.x: permanent mismatch, closed, no data, no retry',
        () async {
      pair = await VersionPair.create(versionB: const ProtocolVersion(4, 0));
      await expectLater(
          pair.negA.ready, throwsA(isA<ErmesVersionMismatchException>()));
      await expectLater(
          pair.negB.ready, throwsA(isA<ErmesVersionMismatchException>()));
      await waitFor(
          () => pair.a.isConnectionClosed && pair.b.isConnectionClosed);
      expect(pair.a.isConnectionClosed, isTrue);
      expect(pair.b.isConnectionClosed, isTrue);
      await expectLater(pair.a.send(Uint8List.fromList([9])),
          throwsA(isA<ErmesVersionMismatchException>()));
      final sentAfterFailure = pair.repoA.sentData.length;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(pair.repoA.sentData.length, sentAfterFailure,
          reason: 'no advert is retried after a permanent failure');
      expect(pair.receivedByA, isEmpty);
      expect(pair.receivedByB, isEmpty);
      expect(ErmesVersionMismatchException('x').isRetryable, isFalse);
    });

    test('silent peer: fails after the timeout, distinct from mismatch',
        () async {
      pair = await VersionPair.create(
        linked: false,
        timeout: const Duration(milliseconds: 300),
      );
      final error = await pair.negA.ready.then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );
      expect(error, isA<ErmesVersionNegotiationException>());
      expect(error, isNot(isA<ErmesVersionMismatchException>()));
      expect(pair.a.isConnectionClosed, isTrue);
      await expectLater(pair.a.send(Uint8List.fromList([1])),
          throwsA(isA<ErmesVersionNegotiationException>()));
    });

    test('envelope v different from the negotiated one is dropped', () async {
      pair = await VersionPair.create();
      await pair.negA.ready;
      await pair.negB.ready;
      pair.bToA.drop = true;
      await pair.b.send(Uint8List.fromList([7]));
      final frame = pair.repoB.sentData.last;
      pair.repoA.simulateDataReceived(withEnvelopeVersion(frame, '3.1'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(pair.receivedByA, isEmpty, reason: 'protocol violation');
      pair.bToA.drop = false;
      await pair.b.send(Uint8List.fromList([8]));
      await waitFor(() => pair.receivedByA.isNotEmpty);
      expect(pair.receivedByA.single, [8]);
    });

    test('advert is the first service message, before newkey', () async {
      pair = await VersionPair.create(linked: false);
      unawaited(pair.a.sendNewKey(
        algorithm: SymmetricAlgorithm.aes,
        key: 'ab' * 32,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final before = pair.repoA.sentData.map(innerOf).toList();
      expect(before, isNotEmpty);
      expect(before.every((m) => m.asService() is ServiceMessageVersion),
          isTrue);
      pair.link();
      await pair.negA.ready;
      await waitFor(() => pair.repoA.sentData
          .map(innerOf)
          .any((m) => m.asService() is ServiceMessageNewKey));
      final wire = pair.repoA.sentData.map(innerOf).toList();
      expect(wire.first.asService(), isA<ServiceMessageVersion>());
      expect(wire.any((m) => m.asService() is ServiceMessageNewKey), isTrue);
    });

    test('data sent before negotiation is held, then delivered', () async {
      pair = await VersionPair.create(linked: false);
      final sending = pair.a.send(Uint8List.fromList([4, 2]));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(pair.negA.isNegotiated, isFalse);
      final dataOnWire = pair.repoA.sentData
          .map(innerOf)
          .where((m) => m.asService() == null);
      expect(dataOnWire, isEmpty);
      pair.link();
      await sending;
      await waitFor(() => pair.receivedByB.isNotEmpty);
      expect(pair.receivedByB.single, [4, 2]);
    });
  });
}

void main() => testErmesVersionNegotiation();
