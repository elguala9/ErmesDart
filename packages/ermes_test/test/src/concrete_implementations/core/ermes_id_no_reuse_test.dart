import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Ids never repeat within a connection (RFC 7.2), tested via the
/// [IIdHandlerService] interface.
void testErmesIdNoReuse() {
  group('IIdHandlerService id no-reuse (RFC 7.2)', () {
    test('issues strictly increasing distinct ids', () {
      final ids = IdHandlerServiceFactory.createDefault();
      final issued = [for (var i = 0; i < 100; i++) ids.getNewId()];
      expect(issued.toSet(), hasLength(100));
      for (var i = 1; i < issued.length; i++) {
        expect(issued[i], greaterThan(issued[i - 1]));
      }
    });

    test('issues the last id of the range', () {
      final ids = IdHandlerServiceFactory.createWithRange(start: 2, max: 3);
      expect(ids.getNewId(), 2);
      expect(ids.getNewId(), 3);
    });

    test('throws on exhaustion instead of wrapping to 0', () {
      final ids = IdHandlerServiceFactory.createWithRange(start: 2, max: 3)
        ..getNewId()
        ..getNewId();
      expect(ids.getNewId, throwsA(isA<ErmesValidationException>()));
      expect(ids.getNewId, throwsA(isA<ErmesValidationException>()));
    });

    test('setCounter on a fresh connection starts from that id', () {
      final ids = IdHandlerServiceFactory.createDefault()..setCounter(40);
      expect(ids.getNewId(), 40);
    });

    test('setCounter outside the range is rejected', () {
      final ids = IdHandlerServiceFactory.createWithRange(start: 0, max: 3);
      expect(() => ids.setCounter(4), throwsArgumentError);
    });
  });
}

void main() => testErmesIdNoReuse();
