import 'package:ermes_core/ermes_core.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  testErmesLog();
}

void testErmesLog() {
  group('ermes_log', () {
    group('ermesCoreLogger', () {
      test('is named ermes_core', () {
        expect(ermesCoreLogger.name, equals('ermes_core'));
      });

      test('is a singleton within the logging hierarchy', () {
        expect(ermesCoreLogger, same(Logger('ermes_core')));
      });
    });

    group('ermesLoggerFor()', () {
      test('returns a child logger named ermes_core.<name>', () {
        final logger = ermesLoggerFor('ErmesService');
        expect(logger.fullName, equals('ermes_core.ErmesService'));
      });

      test('returns the same child logger for repeated calls with the '
          'same name', () {
        final first = ermesLoggerFor('SamePart');
        final second = ermesLoggerFor('SamePart');
        expect(first, same(second));
      });

      test('returns distinct loggers for distinct subsystem names', () {
        final first = ermesLoggerFor('SubsystemA');
        final second = ermesLoggerFor('SubsystemB');
        expect(first, isNot(same(second)));
      });

      test('rejects an empty subsystem name (logging package hierarchy '
          "can't end with '.')", () {
        expect(() => ermesLoggerFor(''), throwsArgumentError);
      });
    });
  });
}
