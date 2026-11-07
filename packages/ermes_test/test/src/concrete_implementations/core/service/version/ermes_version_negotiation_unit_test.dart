import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

const _v30 = ProtocolVersion.current;

ErmesVersionNegotiationInput _input({
  required List<(ProtocolVersion, bool)> sent,
  required List<ErmesVersionNegotiationException> failures,
  ProtocolVersion? local,
  bool open = true,
}) =>
    ErmesVersionNegotiationInput(
      sendAdvert: (v, {required ack}) => sent.add((v, ack)),
      isOpen: () => open,
      onFailure: failures.add,
      localVersion: local,
      timeout: const Duration(milliseconds: 150),
      resendInterval: const Duration(milliseconds: 20),
    );

/// Unit tests for the advert message, the negotiation state and its factory.
void testErmesVersionNegotiationUnits() {
  group('ServiceMessageVersion', () {
    test('toJson/fromJson round trip with reason v', () {
      const msg = ServiceMessageVersion(
          id: 4, version: ProtocolVersion(3, 2), ack: true);
      final json = msg.toJson();
      expect(json['reason'], 'v');
      expect(json['version'], '3.2');
      expect(ServiceMessage.fromJson(json), msg);
    });

    test('malformed or missing version throws', () {
      expect(
        () => ServiceMessage.fromJson({'id': 1, 'reason': 'v', 'version': 'x'}),
        throwsA(isA<ErmesSerializationException>()),
      );
      expect(
        () => ServiceMessage.fromJson({'id': 1, 'reason': 'v'}),
        throwsA(isA<ErmesSerializationException>()),
      );
    });
  });

  group('ErmesVersionNegotiationState', () {
    test('equal majors adopt the lower minor', () async {
      final state = ErmesVersionNegotiationState(const ProtocolVersion(3, 4))
        ..resolve(const ProtocolVersion(3, 1));
      expect(state.negotiated, const ProtocolVersion(3, 1));
      expect(await state.ready, const ProtocolVersion(3, 1));
    });

    test('different majors fail permanently', () async {
      final state = ErmesVersionNegotiationState(_v30)
        ..resolve(const ProtocolVersion(4, 0));
      expect(state.hasFailed, isTrue);
      expect(() => state.negotiated,
          throwsA(isA<ErmesVersionMismatchException>()));
      await expectLater(
          state.ready, throwsA(isA<ErmesVersionMismatchException>()));
      state.resolve(_v30);
      expect(state.isNegotiated, isFalse, reason: 'failure is final');
    });

    test('not negotiated yet throws and stamps the local version', () {
      final state = ErmesVersionNegotiationState(_v30);
      expect(() => state.negotiated,
          throwsA(isA<ErmesVersionNegotiationException>()));
      expect(state.envelopeVersion, _v30);
    });
  });

  group('ErmesVersionNegotiationFactory', () {
    test('creates a negotiation that answers un-acked adverts', () async {
      final sent = <(ProtocolVersion, bool)>[];
      final failures = <ErmesVersionNegotiationException>[];
      final neg = ErmesVersionNegotiationFactory.create(
          _input(sent: sent, failures: failures))
        ..start()
        ..onAdvert(const ServiceMessageVersion(id: 1, version: _v30));
      expect(neg, isA<IErmesVersionNegotiation>());
      expect(neg.localVersion, ProtocolVersion.current);
      expect(await neg.ready, _v30);
      expect(sent.first, (_v30, false));
      expect(sent.last, (_v30, true));
      expect(failures, isEmpty);
      neg.dispose();
    });

    test('closed transport sends nothing and never times out', () async {
      final sent = <(ProtocolVersion, bool)>[];
      final failures = <ErmesVersionNegotiationException>[];
      final neg = ErmesVersionNegotiationFactory.create(
          _input(sent: sent, failures: failures, open: false))
        ..start();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(sent, isEmpty);
      expect(failures, isEmpty);
      neg.dispose();
    });

    test('timeout reports one non-retryable failure', () async {
      final sent = <(ProtocolVersion, bool)>[];
      final failures = <ErmesVersionNegotiationException>[];
      ErmesVersionNegotiationFactory.create(
          _input(sent: sent, failures: failures)).start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(failures, hasLength(1));
      expect(failures.single.isRetryable, isFalse);
      expect(sent.length, greaterThan(1), reason: 'advert is re-sent');
    });
  });
}

void main() => testErmesVersionNegotiationUnits();
