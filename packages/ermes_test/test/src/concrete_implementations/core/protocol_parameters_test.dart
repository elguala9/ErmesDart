import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  testErmesProtocolParameters();
}

/// RFC section 7.5: parameters fixed by the negotiated minor version.
void testErmesProtocolParameters() {
  group('ErmesProtocolParameters', () {
    test('version 3.0 values match the RFC 7.5 table', () {
      const p = ErmesProtocolParameters.v3_0;
      expect(p.sessionKeyRotationMessages, 1000);
      expect(p.publicKeyRotationInterval, const Duration(seconds: 86400));
      expect(p.missingMessagesThreshold, 10);
      expect(p.retentionWindow, const Duration(seconds: 3600));
    });

    test('forVersion(3.0) returns the 3.0 set', () {
      expect(
        ErmesProtocolParameters.forVersion(ProtocolVersion.parse('3.0')),
        same(ErmesProtocolParameters.v3_0),
      );
    });

    test('current is the set of the emitted version', () {
      expect(
        ErmesProtocolParameters.forVersion(ProtocolVersion.current),
        same(ErmesProtocolParameters.current),
      );
    });

    test('forVersion throws for a version without a defined set', () {
      expect(
        () => ErmesProtocolParameters.forVersion(const ProtocolVersion(3, 1)),
        throwsA(isA<ErmesValidationException>()),
      );
      expect(
        () => ErmesProtocolParameters.forVersion(ProtocolVersion.legacy),
        throwsA(isA<ErmesValidationException>()),
      );
    });
  });
}
